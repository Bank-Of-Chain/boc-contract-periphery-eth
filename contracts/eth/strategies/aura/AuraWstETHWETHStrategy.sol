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

contract AuraWstETHWETHStrategy is ETHBaseClaimableStrategy {
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

    IUniswapV2Router2 public constant uniRouter2 =
        IUniswapV2Router2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router2 public constant sushiRouter2 =
        IUniswapV2Router2(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    address public constant AURA_TOKEN = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    mapping(address => address[]) public swapRewardRoutes;
    mapping(address => uint256) public sellFloor;

    function initialize(address _vault,string memory _name) external initializer {
        address[] memory _wants = new address[](2);
        _wants[0] = WSTETH; //wstETH
        _wants[1] = WETH; //wETH

        address[] memory ldoSellPath = new address[](2);
        ldoSellPath[0] = LDO;
        ldoSellPath[1] = WETH;
        swapRewardRoutes[LDO] = ldoSellPath;

        uint256 uintMax = type(uint256).max;
        for (uint256 i = 0; i < _wants.length; i++) {
            // for enter balancer vault
            IERC20Upgradeable(_wants[i]).safeApprove(address(BALANCER_VAULT), uintMax);
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

        isWantRatioIgnorable = true;

        super._initialize(_vault, uint16(ProtocolEnum.Aura), _name,_wants);
    }

    /**
     * Sets the minimum amount of token needed to trigger a sale.
     */
    function setSellFloor(address token, uint256 floor) external isVaultManager {
        sellFloor[token] = floor;
    }

    function setRewardSwapPath(address token, address[] memory _uniswapRouteToToken)
        external
        isVaultManager
    {
        require(token == _uniswapRouteToToken[_uniswapRouteToToken.length - 1]);
        swapRewardRoutes[token] = _uniswapRouteToToken;
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function getPoolKey() internal pure returns (bytes32) {
        return 0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080;
    }

    function getPId() internal pure returns (uint256) {
        return 3;
    }

    function getPoolLpToken() internal pure returns (address) {
        return 0x32296969Ef14EB0c6d29669C550D4a0449130230;
    }

    function getRewardPool() internal pure returns (address) {
        return 0xDCee1C640cC270121faF145f231fd8fF1d8d5CD4;
    }

    /// @notice Provide the strategy need underlying token and ratio
    function getWantsInfo()
        external
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        (, _ratios, ) = BALANCER_VAULT.getPoolTokens(getPoolKey());
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory outputsInfo)
    {
        outputsInfo = new OutputInfo[](3);
        OutputInfo memory info0 = outputsInfo[0];
        info0.outputCode = 0;
        info0.outputTokens = wants;

        OutputInfo memory info1 = outputsInfo[1];
        info1.outputCode = 1;
        info1.outputTokens = new address[](1);
        info1.outputTokens[0] = WSTETH; //wstETH

        OutputInfo memory info2 = outputsInfo[2];
        info2.outputCode = 2;
        info2.outputTokens = new address[](1);
        info2.outputTokens[0] = WETH; //wETH
    }

    /// @notice 3rd prototcol's pool total assets in USD.
    function get3rdPoolAssets() external view override returns (uint256) {
        uint256 totalAssets;
        (address[] memory tokens, uint256[] memory balances, ) = BALANCER_VAULT.getPoolTokens(
            getPoolKey()
        );
        for (uint8 i = 0; i < tokens.length; i++) {
            totalAssets += queryTokenValueInETH(tokens[i], balances[i]);
        }
        return totalAssets;
    }

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
            _amounts[i] =
                (_amounts[i] * stakingAmount) /
                lpTotalSupply +
                balanceOfToken(_tokens[i]);
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
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
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
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        uint256 withdrawAmount = (getStakingAmount() * _withdrawShares) / _totalShares;
        //unstaking
        IRewardPool(getRewardPool()).redeem(withdrawAmount, address(this), address(this));
        console.log("lpAmount:", balanceOfToken(getPoolLpToken()));
        _withdrawFromBalancer(withdrawAmount, _outputCode);
    }

    function _withdrawFromBalancer(uint256 _exitAmount, uint256 _outputCode) internal virtual {
        address payable recipient = payable(address(this));
        bytes32 poolKey = getPoolKey();
        IAsset[] memory poolAssets = _getPoolAssets(poolKey);
        uint256[] memory minAmountsOut = new uint256[](poolAssets.length);
        IBalancerVault.ExitPoolRequest memory exitRequest;
        if (_outputCode == 1) {
            //WSTETH
            exitRequest = IBalancerVault.ExitPoolRequest({
                assets: poolAssets,
                minAmountsOut: minAmountsOut,
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, _exitAmount, 0),
                toInternalBalance: false
            });
        } else if (_outputCode == 2) {
            //wETH
            exitRequest = IBalancerVault.ExitPoolRequest({
                assets: poolAssets,
                minAmountsOut: minAmountsOut,
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, _exitAmount, 1),
                toInternalBalance: false
            });
        } else {
            //WSTETH + wETH
            exitRequest = IBalancerVault.ExitPoolRequest({
                assets: poolAssets,
                minAmountsOut: minAmountsOut,
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, _exitAmount),
                toInternalBalance: false
            });
        }
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
            console.log("extraRewardsLen:%s,BAL:%s", extraRewardsLen, balanceOfToken(BAL));
            if (extraRewardsLen > 0) {
                for (uint256 i = 0; i < extraRewardsLen; i++) {
                    address extraReward = IRewardPool(rewardPool).extraRewards(i);
                    address rewardToken = IRewardPool(extraReward).rewardToken();
                    // IRewardPool(extraReward).getReward();
                    _rewardsTokens[2 + i] = rewardToken;
                    _claimAmounts[2 + i] = balanceOfToken(rewardToken);
                    console.log(
                        "extraReward:%s,rewardToken:%s,balance:%d",
                        extraReward,
                        rewardToken,
                        balanceOfToken(rewardToken)
                    );
                }
            }
        }
    }

    function swapRewardsToWants() internal override {
        uint256 balanceOfBal = balanceOfToken(BAL);
        if (balanceOfBal > 0) {
            IERC20Upgradeable(BAL).safeApprove(address(uniRouter2), 0);
            IERC20Upgradeable(BAL).safeApprove(address(uniRouter2), balanceOfBal);
            uniRouter2.swapExactTokensForTokens(
                balanceOfBal,
                0,
                swapRewardRoutes[BAL],
                address(this),
                block.timestamp
            );
        }

        uint256 balanceOfAura = balanceOfToken(AURA_TOKEN);
        if (balanceOfAura > 0) {
            IERC20Upgradeable(AURA_TOKEN).safeApprove(address(uniRouter2), 0);
            IERC20Upgradeable(AURA_TOKEN).safeApprove(address(uniRouter2), balanceOfAura);
            uniRouter2.swapExactTokensForTokens(
                balanceOfAura,
                0,
                swapRewardRoutes[AURA_TOKEN],
                address(this),
                block.timestamp
            );
        }

        uint256 balanceOfLdo = balanceOfToken(LDO);
        if (balanceOfLdo > 0) {
            IERC20Upgradeable(LDO).safeApprove(address(sushiRouter2), 0);
            IERC20Upgradeable(LDO).safeApprove(address(sushiRouter2), balanceOfAura);
            sushiRouter2.swapExactTokensForTokens(
                balanceOfLdo,
                0,
                swapRewardRoutes[LDO],
                address(this),
                block.timestamp
            );
        }
    }
}
