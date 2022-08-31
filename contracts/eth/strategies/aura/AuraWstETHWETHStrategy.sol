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

    bytes32 internal constant BALANCER_POOL_ID =
        bytes32(0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274);

    IUniswapV2Router2 public constant UNIROUTER2 =
        IUniswapV2Router2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router2 public constant SUSHIROUTER2 =
        IUniswapV2Router2(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    address public constant AURA_TOKEN = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    mapping(address => address[]) public swapRewardRoutes;

    function initialize(address _vault, string memory _name) external initializer {
        address[] memory _wants = new address[](2);
        _wants[0] = WSTETH; //wstETH
        _wants[1] = WETH; //wETH

        address[] memory _ldoSellPath = new address[](2);
        _ldoSellPath[0] = LDO;
        _ldoSellPath[1] = WETH;
        swapRewardRoutes[LDO] = _ldoSellPath;

        uint256 _uintMax = type(uint256).max;
        for (uint256 i = 0; i < _wants.length; i++) {
            // for enter balancer vault
            IERC20Upgradeable(_wants[i]).safeApprove(address(BALANCER_VAULT), _uintMax);
        }
        //for Booster deposit
        IERC20Upgradeable(getPoolLpToken()).safeApprove(address(AURA_BOOSTER), _uintMax);

        //set up sell reward path
        address[] memory _balSellPath = new address[](2);
        _balSellPath[0] = BAL;
        _balSellPath[1] = WETH;
        swapRewardRoutes[BAL] = _balSellPath;
        address[] memory _auraSellPath = new address[](2);
        _auraSellPath[0] = AURA_TOKEN;
        _auraSellPath[1] = WETH;
        swapRewardRoutes[AURA_TOKEN] = _auraSellPath;

        isWantRatioIgnorable = true;

        super._initialize(_vault, uint16(ProtocolEnum.Aura), _name, _wants);
    }

    function setRewardSwapPath(address _token, address[] memory _uniswapRouteToToken)
        external
        isVaultManager
    {
        swapRewardRoutes[_token] = _uniswapRouteToToken;
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
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](3);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = wants;

        OutputInfo memory _info1 = _outputsInfo[1];
        _info1.outputCode = 1;
        _info1.outputTokens = new address[](1);
        _info1.outputTokens[0] = WSTETH; //wstETH

        OutputInfo memory _info2 = _outputsInfo[2];
        _info2.outputCode = 2;
        _info2.outputTokens = new address[](1);
        _info2.outputTokens[0] = WETH; //wETH
    }

    /// @notice 3rd prototcol's pool total assets in USD.
    function get3rdPoolAssets() external view override returns (uint256) {
        uint256 _totalAssets;
        (address[] memory _tokens, uint256[] memory _balances, ) = BALANCER_VAULT.getPoolTokens(
            getPoolKey()
        );
        for (uint8 i = 0; i < _tokens.length; i++) {
            _totalAssets += queryTokenValueInETH(_tokens[i], _balances[i]);
        }
        return _totalAssets;
    }

    /// @notice Returns the position details of the strategy.
    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        )
    {
        _tokens = wants;
        (, _amounts, ) = BALANCER_VAULT.getPoolTokens(getPoolKey());
        uint256 _stakingAmount = getStakingAmount();
        uint256 _lpTotalSupply = IERC20Upgradeable(getPoolLpToken()).totalSupply();
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] =
                (_amounts[i] * _stakingAmount) /
                _lpTotalSupply +
                balanceOfToken(_tokens[i]);
        }
    }

    function getStakingAmount() public view returns (uint256) {
        return IRewardPool(getRewardPool()).balanceOf(address(this));
    }

    function _getPoolAssets(bytes32 _poolKey) internal view returns (IAsset[] memory _poolAssets) {
        (address[] memory _tokens, , ) = BALANCER_VAULT.getPoolTokens(_poolKey);
        _poolAssets = new IAsset[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _poolAssets[i] = IAsset(_tokens[i]);
        }
    }

    /// @notice Strategy deposit funds to 3rd pool.
    /// @param _assets deposit token address
    /// @param _amounts deposit token amount
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        uint256 _receiveLpAmount = _depositToBalancer(_assets, _amounts);
        AURA_BOOSTER.deposit(getPId(), _receiveLpAmount, true);
    }

    function _depositToBalancer(address[] memory _assets, uint256[] memory _amounts)
        internal
        virtual
        returns (uint256 _receiveLpAmount)
    {
        bytes32 _poolKey = getPoolKey();
        IBalancerVault.JoinPoolRequest memory _joinRequest = IBalancerVault.JoinPoolRequest({
            assets: _getPoolAssets(_poolKey),
            maxAmountsIn: _amounts,
            userData: abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, _amounts, 0),
            fromInternalBalance: false
        });

        BALANCER_VAULT.joinPool(_poolKey, address(this), address(this), _joinRequest);
        _receiveLpAmount = balanceOfToken(getPoolLpToken());
    }

    /// @notice Strategy withdraw the funds from 3rd pool.
    /// @param _withdrawShares Numerator
    /// @param _totalShares Denominator
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        uint256 _withdrawAmount = (getStakingAmount() * _withdrawShares) / _totalShares;
        //unstaking
        IRewardPool(getRewardPool()).redeem(_withdrawAmount, address(this), address(this));
        _withdrawFromBalancer(_withdrawAmount, _outputCode);
    }

    function _withdrawFromBalancer(uint256 _exitAmount, uint256 _outputCode) internal virtual {
        address payable _recipient = payable(address(this));
        bytes32 _poolKey = getPoolKey();
        IAsset[] memory _poolAssets = _getPoolAssets(_poolKey);
        uint256[] memory _minAmountsOut = new uint256[](_poolAssets.length);
        IBalancerVault.ExitPoolRequest memory _exitRequest;
        if (_outputCode == 1) {
            //WSTETH
            _exitRequest = IBalancerVault.ExitPoolRequest({
                assets: _poolAssets,
                minAmountsOut: _minAmountsOut,
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, _exitAmount, 0),
                toInternalBalance: false
            });
        } else if (_outputCode == 2) {
            //wETH
            _exitRequest = IBalancerVault.ExitPoolRequest({
                assets: _poolAssets,
                minAmountsOut: _minAmountsOut,
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, _exitAmount, 1),
                toInternalBalance: false
            });
        } else {
            //WSTETH + wETH
            _exitRequest = IBalancerVault.ExitPoolRequest({
                assets: _poolAssets,
                minAmountsOut: _minAmountsOut,
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, _exitAmount),
                toInternalBalance: false
            });
        }
        BALANCER_VAULT.exitPool(_poolKey, address(this), _recipient, _exitRequest);
    }

    function claimRewards()
        internal
        override
        returns (
            bool _claimIsWorth,
            address[] memory _rewardsTokens,
            uint256[] memory _claimAmounts
        )
    {
        address _rewardPool = getRewardPool();
        _claimIsWorth = true;
        IRewardPool(_rewardPool).getReward();
        uint256 _extraRewardsLen = IRewardPool(_rewardPool).extraRewardsLength();
        // _extraRewardsLen = 0;
        _rewardsTokens = new address[](2 + _extraRewardsLen);
        _rewardsTokens[0] = BAL;
        _rewardsTokens[1] = AURA_TOKEN;
        _claimAmounts = new uint256[](2 + _extraRewardsLen);
        _claimAmounts[0] = balanceOfToken(BAL);
        _claimAmounts[1] = balanceOfToken(AURA_TOKEN);
        if (_extraRewardsLen > 0) {
            for (uint256 i = 0; i < _extraRewardsLen; i++) {
                address _extraReward = IRewardPool(_rewardPool).extraRewards(i);
                address _rewardToken = IRewardPool(_extraReward).rewardToken();
                // IRewardPool(_extraReward).getReward();
                _rewardsTokens[2 + i] = _rewardToken;
                _claimAmounts[2 + i] = balanceOfToken(_rewardToken);
            }
        }
    }

    function swapRewardsToWants()
        internal
        override
        returns (address[] memory _wantTokens, uint256[] memory _wantAmounts)
    {
        uint256 _wethBalanceInit = balanceOfToken(WETH);

        uint256 _balanceOfBal = balanceOfToken(BAL);
        if (_balanceOfBal > 0) {
            IERC20Upgradeable(BAL).safeApprove(address(UNIROUTER2), 0);
            IERC20Upgradeable(BAL).safeApprove(address(UNIROUTER2), _balanceOfBal);
            UNIROUTER2.swapExactTokensForTokens(
                _balanceOfBal,
                0,
                swapRewardRoutes[BAL],
                address(this),
                block.timestamp
            );
        }
        uint256 _wethBalanceAfterSellBAL = balanceOfToken(WETH);

        uint256 _balanceOfAura = balanceOfToken(AURA_TOKEN);
        if (_balanceOfAura > 0) {
            IERC20Upgradeable(AURA_TOKEN).safeApprove(address(BALANCER_VAULT), 0);
            IERC20Upgradeable(AURA_TOKEN).safeApprove(address(BALANCER_VAULT), _balanceOfAura);

            IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(BALANCER_POOL_ID, IBalancerVault.SwapKind.GIVEN_IN,  IAsset(AURA_TOKEN), IAsset(WETH), _balanceOfAura, "");
            IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement(address(this), false, payable(address(this)), false);

            BALANCER_VAULT.swap(singleSwap, funds, 0, block.timestamp);
        }
        uint256 _wethBalanceAfterSellBalAndAura = balanceOfToken(WETH);

        uint256 _balanceOfLdo = balanceOfToken(LDO);
        if (_balanceOfLdo > 0) {
            IERC20Upgradeable(LDO).safeApprove(address(SUSHIROUTER2), 0);
            IERC20Upgradeable(LDO).safeApprove(address(SUSHIROUTER2), _balanceOfLdo);
            SUSHIROUTER2.swapExactTokensForTokens(
                _balanceOfLdo,
                0,
                swapRewardRoutes[LDO],
                address(this),
                block.timestamp
            );
        }
        uint256 _wethBalanceAfterSellTotal = balanceOfToken(WETH);

        _wantTokens = new address[](3);
        _wantAmounts = new uint256[](3);
        _wantTokens[0] = WETH;
        _wantTokens[1] = WETH;
        _wantTokens[2] = WETH;

        _wantAmounts[0] = _wethBalanceAfterSellBAL - _wethBalanceInit;
        _wantAmounts[1] = _wethBalanceAfterSellBalAndAura - _wethBalanceAfterSellBAL;
        _wantAmounts[2] = _wethBalanceAfterSellTotal - _wethBalanceAfterSellBalAndAura;

        console.log("_balanceOfAura,_wantAmounts[1]=",_balanceOfAura,_wantAmounts[1]);
    }
}
