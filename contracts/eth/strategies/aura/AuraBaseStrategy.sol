// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/balancer/IAsset.sol";
import "../../../external/balancer/IBalancerVault.sol";
// aura fork from convex
import "../../../external/aura/IRewardPool.sol";
import "../../../external/aura/IAuraBooster.sol";

import "../../../external/uniswap/IUniswapV2Router2.sol";

import "../ETHBaseClaimableStrategy.sol";
import "../../enums/ProtocolEnum.sol";

import "hardhat/console.sol";

abstract contract AuraBaseStrategy is ETHBaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }

    IAuraBooster internal constant AURA_BOOSTER =
        IAuraBooster(0x7818A1DA7BD1E64c199029E86Ba244a9798eEE10);

    IBalancerVault internal constant BALANCER_VAULT =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    
    IUniswapV2Router2 public constant uniRouter2 = IUniswapV2Router2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router2 public constant sushiRouter2 = IUniswapV2Router2(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    address public constant AURA_TOKEN = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping(address => address[]) public swapRewardRoutes;
    mapping(address => uint256) public sellFloor;

    function _initialize(
        address _vault,
        address[] memory _wants
    ) public initializer {
        super._initialize(_vault, uint16(ProtocolEnum.Aura), _wants);

        uint256 uintMax = type(uint256).max;
        // (address[] memory _tokens, , ) = BALANCER_VAULT.getPoolTokens(poolKey);
        for (uint256 i = 0; i < _wants.length; i++) {
            address token = _wants[i];
            // for enter balancer vault
            IERC20Upgradeable(token).safeApprove(address(BALANCER_VAULT), uintMax);
        }
        //for Booster deposit
        IERC20Upgradeable(getPoolLpToken()).safeApprove(address(AURA_BOOSTER), uintMax);

        //set up sell reward path
        address[] memory balSellPath = new address[](2);
        balSellPath[0] = BAL;
        balSellPath[1] = WETH;
        swapRewardRoutes[BAL] = balSellPath;
        address[] memory auraSellPath = new address[](2);
        auraSellPath[0] = AURA_TOKEN;
        auraSellPath[1] = WETH;
        swapRewardRoutes[AURA_TOKEN] = auraSellPath;
        sellFloor[BAL] = 1e17;
    }

    /**
     * Sets the minimum amount of token needed to trigger a sale.
     */
    function setSellFloor(address token, uint256 floor) external isVaultManager {
        sellFloor[token] = floor;
    }

    function setRewardSwapPath(address token, address[] memory _uniswapRouteToToken) external isVaultManager {
        require(token == _uniswapRouteToToken[_uniswapRouteToToken.length - 1]);
        swapRewardRoutes[token] = _uniswapRouteToToken;
    }

    function getPoolKey() internal pure virtual returns(bytes32);
    function getPId() internal pure virtual returns(uint256);
    function getPoolLpToken() internal pure virtual returns(address);
    function getRewardPool() internal pure virtual returns(address);

    /// @notice Returns the position details of the strategy.
    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool isUsd,
            uint256 usdValue
        )
    {
        _tokens = wants;
        (, _amounts, ) = BALANCER_VAULT.getPoolTokens(getPoolKey());
        uint256 stakingAmount = getStakingAmount();
        uint256 lpTotalSupply = IERC20Upgradeable(getPoolLpToken()).totalSupply();
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = (_amounts[i] * stakingAmount) / lpTotalSupply + balanceOfToken(_tokens[i]);
        }
    }

    function getStakingAmount() public view returns (uint256) {
        return IRewardPool(getRewardPool()).balanceOf(address(this));
    }

    function _getPoolAssets(bytes32 _poolKey) internal view returns (IAsset[] memory poolAssets) {
        (address[] memory tokens, , ) = BALANCER_VAULT.getPoolTokens(_poolKey);
        poolAssets = new IAsset[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            poolAssets[i] = IAsset(tokens[i]);
        }
    }

    /// @notice Strategy deposit funds to 3rd pool.
    /// @param _assets deposit token address
    /// @param _amounts deposit token amount
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal override {
        uint256 receiveLpAmount = _depositToBalancer(_assets, _amounts);
        console.log("receiveLpAmount:", receiveLpAmount);
        AURA_BOOSTER.deposit(getPId(), receiveLpAmount, true);
    }

    function _depositToBalancer(address[] memory _assets, uint256[] memory _amounts)
        internal
        virtual
        returns (uint256 receiveLpAmount)
    {
        bytes32 poolKey = getPoolKey();
        IBalancerVault.JoinPoolRequest memory joinRequest = IBalancerVault.JoinPoolRequest({
            assets: _getPoolAssets(poolKey),
            maxAmountsIn: _amounts,
            userData: abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, _amounts, 0),
            fromInternalBalance: false
        });

        BALANCER_VAULT.joinPool(poolKey, address(this), address(this), joinRequest);
        receiveLpAmount = balanceOfToken(getPoolLpToken());
    }

    /// @notice Strategy withdraw the funds from 3rd pool.
    /// @param _withdrawShares Numerator
    /// @param _totalShares Denominator
    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares) internal override {
        uint256 withdrawAmount = (getStakingAmount() * _withdrawShares) / _totalShares;
        //unstaking
        IRewardPool(getRewardPool()).redeem(withdrawAmount, address(this), address(this));
        console.log("lpAmount:", balanceOfToken(getPoolLpToken()));
        _withdrawFromBalancer(withdrawAmount);
    }

    function _withdrawFromBalancer(uint256 _exitAmount) internal virtual {
        address payable recipient = payable(address(this));
        bytes32 poolKey = getPoolKey();
        IAsset[] memory poolAssets = _getPoolAssets(poolKey);
        uint256[] memory minAmountsOut = new uint256[](poolAssets.length);
        IBalancerVault.ExitPoolRequest memory exitRequest = IBalancerVault.ExitPoolRequest({
            assets: poolAssets,
            minAmountsOut: minAmountsOut,
            userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, _exitAmount),
            toInternalBalance: false
        });
        BALANCER_VAULT.exitPool(poolKey, address(this), recipient, exitRequest);
    }

    function claimRewards()
        internal
        override
        returns (
            bool claimIsWorth,
            address[] memory _rewardsTokens,
            uint256[] memory _claimAmounts
        )
    {
        address rewardPool = getRewardPool();
        uint256 earn = IRewardPool(rewardPool).earned(address(this));
        if (earn > sellFloor[BAL]) {
            claimIsWorth = true;
            console.log("earn:", earn);
            IRewardPool(rewardPool).getReward();
            uint256 extraRewardsLen = IRewardPool(rewardPool).extraRewardsLength();
            // extraRewardsLen = 0;
            _rewardsTokens = new address[](2 + extraRewardsLen);
            _rewardsTokens[0] = BAL;
            _rewardsTokens[1] = AURA_TOKEN;
            _claimAmounts = new uint256[](2 + extraRewardsLen);
            _claimAmounts[0] = balanceOfToken(BAL);
            _claimAmounts[1] = balanceOfToken(AURA_TOKEN);
            console.log("extraRewardsLen:%s,BAL:%s", extraRewardsLen,balanceOfToken(BAL));
            if (extraRewardsLen > 0) {
                for (uint256 i = 0; i < extraRewardsLen; i++) {
                    address extraReward = IRewardPool(rewardPool).extraRewards(i);
                    address rewardToken = IRewardPool(extraReward).rewardToken();
                    // IRewardPool(extraReward).getReward();
                    _rewardsTokens[2 + i] = rewardToken;
                    _claimAmounts[2 + i] = balanceOfToken(rewardToken);
                    console.log('extraReward:%s,rewardToken:%s,balance:%d',extraReward,rewardToken,balanceOfToken(rewardToken));
                }
            }
        }
    }

    
}
