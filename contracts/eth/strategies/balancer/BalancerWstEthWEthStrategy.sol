// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../../external/balancer/IAsset.sol";
import "../../../external/balancer/IBalancerVault.sol";
import "../../../external/balancer/IStakingLiquidityGauge.sol";
import "../../../external/balancer/IBalancerMinter.sol";

import "../../enums/ProtocolEnum.sol";
import "../ETHBaseClaimableStrategy.sol";
import "../../../external/uniswap/IUniswapV2Router2.sol";

import "hardhat/console.sol";

contract BalancerWstEthWEthStrategy is ETHBaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    //strategy want
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //it's a ERC20
    address public constant pool = 0x32296969Ef14EB0c6d29669C550D4a0449130230;
    bytes32 public constant poolId = 0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080;
    address public constant gauge = 0xcD4722B7c24C29e0413BDCd9e51404B4539D14aE;
    address public constant minter = 0x239e55F427D44C3cc793f49bFB507ebe76638a2b;

    IUniswapV2Router2 public constant router2 = IUniswapV2Router2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IBalancerVault private constant balancerVault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    mapping(address => address[]) public uniswapRewardRoutes;
    mapping(address => uint256) public sellFloor;

    IAsset[] public poolAssets;

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

    function initialize(address _vault) public initializer {
        address[] memory _wants = new address[](2);
        _wants[0] = WSTETH;
        _wants[1] = WETH;

        //set up sell reward path
        address[] memory rewardSellPath = new address[](2);
        rewardSellPath[0] = BAL;
        rewardSellPath[1] = WETH;
        uniswapRewardRoutes[BAL] = rewardSellPath;
        sellFloor[BAL] = 1e17;

        IAsset[] memory _poolAssets = new IAsset[](_wants.length);
        _poolAssets[0] = IAsset(WSTETH);
        _poolAssets[1] = IAsset(WETH);
        poolAssets = _poolAssets;

        isWantRatioIgnorable = true;
        super._initialize(_vault, uint16(ProtocolEnum.Balancer), _wants);
    }

    /**
     * Sets the minimum amount of token needed to trigger a sale.
     */
    function setSellFloor(address token, uint256 floor) public isVaultManager {
        sellFloor[token] = floor;
    }

    function setRewardSwapPath(address token, address[] memory _uniswapRouteToToken) public isVaultManager {
        require(BAL == _uniswapRouteToToken[0]);
        require(token == _uniswapRouteToToken[_uniswapRouteToToken.length - 1]);
        uniswapRewardRoutes[token] = _uniswapRouteToToken;
    }

    function getVersion() external pure virtual override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "BalancerWstEthWEthStrategy";
    }

    /// @notice Provide the strategy need underlying token and ratio
    function getWantsInfo() external view virtual override returns (address[] memory _assets, uint256[] memory _ratios) {
        // 0:wstEth,1:wEth
        _assets = wants;
        (, _ratios, ) = balancerVault.getPoolTokens(poolId);
        // Convert the amount of wstETH to stETH
        // _ratios[0] = (IWstETH(WSTETH).stEthPerToken() * _ratios[0]) / 1e18;
    }

    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory outputsInfo){
        outputsInfo = new OutputInfo[](1);
        OutputInfo memory info = outputsInfo[0];
        info.outputCode = 0;
        info.outputTokens = new address[](2);
        info.outputTokens[0] = WSTETH;
        info.outputTokens[1] = WETH;
    }

    /// @notice Returns the position details or ETH value of the strategy.
    function getPositionDetail()
        public
        view
        virtual
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool isETH,
            uint256 ethValue
        )
    {
        // (_tokens, _amounts, ) = balancerVault.getPoolTokens(poolId);
        (, _amounts, ) = balancerVault.getPoolTokens(poolId);
        _tokens = wants;
        uint256 lpBalance = IStakingLiquidityGauge(gauge).balanceOf(address(this));
        uint256 lpTotalSupply = IERC20Upgradeable(pool).totalSupply();
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = (_amounts[i] * lpBalance) / lpTotalSupply + balanceOfToken(_tokens[i]);
        }
    }

    function get3rdPoolAssets() external view override returns (uint256 totalAssets) {
        (address[] memory tokens, uint256[] memory balances, ) = balancerVault.getPoolTokens(poolId);
        for (uint8 i = 0; i < tokens.length; i++) {
            totalAssets += queryTokenValueInETH(tokens[i], balances[i]);
        }
    }

    function claimRewards()
        internal
        virtual
        override
        returns (
            bool isWorth,
            address[] memory assets,
            uint256[] memory amounts
        )
    {
        IBalancerMinter(minter).mint(gauge);
        uint256 balanceOfBal = balanceOfToken(BAL);
        console.log("claimRewards###:", balanceOfBal);
        if (balanceOfBal > sellFloor[BAL]) {
            console.log("claim reward:%d", balanceOfBal);
            isWorth = true;
            assets = new address[](1);
            assets[0] = BAL;
            amounts = new uint256[](1);
            amounts[0] = balanceOfBal;
        }
    }

    function swapRewardsToWants() internal virtual override {
        uint256 balanceOfBal = balanceOfToken(BAL);
        IERC20Upgradeable(BAL).safeApprove(address(router2), 0);
        IERC20Upgradeable(BAL).safeApprove(address(router2), balanceOfBal);
        router2.swapExactTokensForTokens(balanceOfBal, 0, uniswapRewardRoutes[BAL], address(this), block.timestamp);
    }

    // UserData struct:https://github.com/balancer-labs/balancer-v2-monorepo/blob/a1e58e0d5910bc41482c31f7921953ec68010a36/pkg/pool-stable/contracts/StablePoolUserDataHelpers.sol
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal override {
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] > 0) {
                IERC20Upgradeable(_assets[i]).approve(address(balancerVault), 0);
                IERC20Upgradeable(_assets[i]).approve(address(balancerVault), _amounts[i]);
            }
        }

        IBalancerVault.JoinPoolRequest memory joinRequest = IBalancerVault.JoinPoolRequest({
            assets: poolAssets,
            maxAmountsIn: _amounts,
            userData: abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, _amounts, 0),
            fromInternalBalance: false
        });

        balancerVault.joinPool(poolId, address(this), address(this), joinRequest);

        uint256 lpAmount = balanceOfToken(pool);
        IERC20Upgradeable(pool).safeApprove(gauge, 0);
        IERC20Upgradeable(pool).safeApprove(gauge, lpAmount);
        IStakingLiquidityGauge(gauge).deposit(lpAmount);
    }

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares,uint256 _outputCode) internal override {
        IStakingLiquidityGauge stakingLiquidityGauge = IStakingLiquidityGauge(gauge);
        uint256 _lpAmount = (stakingLiquidityGauge.balanceOf(address(this)) * _withdrawShares) / _totalShares;
        if (_lpAmount > 0) {
            stakingLiquidityGauge.withdraw(_lpAmount);
            address payable recipient = payable(address(this));
            IAsset[] memory _poolAssets = poolAssets;
            uint256[] memory minAmountsOut = new uint256[](_poolAssets.length);
            IBalancerVault.ExitPoolRequest memory exitRequest = IBalancerVault.ExitPoolRequest({
                assets: _poolAssets,
                minAmountsOut: minAmountsOut,
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, _lpAmount),
                toInternalBalance: false
            });
            balancerVault.exitPool(poolId, address(this), recipient, exitRequest);
        }
    }
}
