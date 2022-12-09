// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../../external/curve/ICurveLiquidityPoolPayable.sol";
import "./ETHConvexBaseStrategy.sol";
import "../../../external/weth/IWeth.sol";

/// @title ConvexStETHStrategy
/// @notice Investment strategy for investing ETH via Lido:Curve Liquidity Farming Pool Contract
/// @author Bank of Chain Protocol Inc
contract ConvexStETHStrategy is ETHConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address private constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    function initialize(address _vault, string memory _name) external initializer {
        super._initialize(_vault, _name);
        //set up sell reward path
        address[] memory _rewardCRVPath = new address[](2);
        _rewardCRVPath[0] = CRV;
        _rewardCRVPath[1] = W_ETH;
        uniswapRewardRoutes[CRV] = _rewardCRVPath;
        address[] memory _rewardCVXPath = new address[](2);
        _rewardCVXPath[0] = CVX;
        _rewardCVXPath[1] = W_ETH;
        uniswapRewardRoutes[CVX] = _rewardCVXPath;
        address[] memory _rewardLDOPath = new address[](2);
        _rewardLDOPath[0] = LDO;
        _rewardLDOPath[1] = W_ETH;
        uniswapRewardRoutes[LDO] = _rewardLDOPath;
    }

    /// Curve Liquidity Farming Pool Contract 
    /// @inheritdoc ETHConvexBaseStrategy
    function getCurvePool() internal pure override returns (ICurveLiquidityPoolPayable) {
        return ICurveLiquidityPoolPayable(address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022));
    }

    /// @inheritdoc ETHConvexBaseStrategy
    function getConvexWants() internal pure override returns (address[] memory) {
        address[] memory _wants = new address[](2);
        _wants[0] = NativeToken.NATIVE_TOKEN;
        _wants[1] = ST_ETH;
        return _wants;
    }

    /// @inheritdoc ETHConvexBaseStrategy
    function getConvexRewards() internal pure override returns (address[] memory) {
        address[] memory _rewards = new address[](3);
        _rewards[0] = CRV;
        _rewards[1] = CVX;
        _rewards[2] = LDO;
        return _rewards;
    }

    /// @inheritdoc ETHConvexBaseStrategy
    function getRewardPool() internal pure override returns (IConvexReward) {
        return IConvexReward(address(0x0A760466E1B4621579a82a39CB56Dda2F4E70f03));
    }

    /// @inheritdoc ETHConvexBaseStrategy
    function getLpToken() internal pure override returns (address) {
        return 0x06325440D014e39736583c165C2963BA99fAf14E;
    }

    /// @inheritdoc ETHConvexBaseStrategy
    function getPid() internal pure override returns (uint256) {
        return 25;
    }

    /// @inheritdoc ETHBaseStrategy
    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc ETHBaseStrategy
    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            _ratios[i] = getCurvePool().balances(i);
        }
    }

    /// @inheritdoc ETHBaseStrategy
    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](3);
        OutputInfo memory _info = _outputsInfo[0];
        _info.outputCode = 0;
        _info.outputTokens = wants;

        OutputInfo memory _info1 = _outputsInfo[1];
        _info1.outputCode = 1;
        _info1.outputTokens = new address[](1);
        _info1.outputTokens[0] = NativeToken.NATIVE_TOKEN;

        OutputInfo memory _info2 = _outputsInfo[2];
        _info2.outputCode = 2;
        _info2.outputTokens = new address[](1);
        _info2.outputTokens[0] = ST_ETH;
    }

    /// @inheritdoc ETHBaseStrategy
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
        _amounts = new uint256[](_tokens.length);
        // curve LP token amount = convex LP token amount
        uint256 _lpAmount = balanceOfLpToken();
        // curve LP total supply
        uint256 _totalSupply = IERC20Upgradeable(getLpToken()).totalSupply();
        for (uint256 i = 0; i < wants.length; i++) {
            _amounts[i] =
                balanceOfToken(_tokens[i]) +
                (getCurvePool().balances(i) * _lpAmount) /
                _totalSupply;
        }
    }

    /// @inheritdoc ETHConvexBaseStrategy
    function sellWETH2Want() internal override {
        // Unwrap wEth to Eth
        IWeth(W_ETH).withdraw(balanceOfToken(W_ETH));
    }

    /// @inheritdoc ETHBaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        bool _isDeposit = false;
        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] > 0) {
                _isDeposit = true;
                break;
            }
        }
        if (_isDeposit) {
            // https://etherscan.io/tx/0x05ccc4242d3d5192a5ff30195cd1aa0ddb434b50fa88ffc55281ccc0bdb94c13
            uint256 _liquidity = curveAddLiquidity(_assets, _amounts);
            address _lpToken = getLpToken();
            IERC20Upgradeable(_lpToken).safeApprove(address(BOOSTER), 0);
            IERC20Upgradeable(_lpToken).safeApprove(address(BOOSTER), _liquidity);
            // deposit into convex booster and stake at reward pool automatically
            // https://etherscan.io/tx/0xfdc8f347440dc9adeaa0b59201c653fd09c2cfffb97b35df08de7af5691b02ec
            BOOSTER.deposit(getPid(), _liquidity, true);
        }
    }

    /// @inheritdoc ETHConvexBaseStrategy
    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        uint256[2] memory _depositArray;
        _depositArray[0] = _amounts[0];
        _depositArray[1] = _amounts[1];
        // only need to safeApprove stETH
        IERC20Upgradeable(_assets[1]).safeApprove(address(getCurvePool()), 0);
        IERC20Upgradeable(_assets[1]).safeApprove(address(getCurvePool()), _amounts[1]);
        if (_amounts[0] > 0) {
            return getCurvePool().add_liquidity{value: _amounts[0]}(_depositArray, 0);
        }
        return getCurvePool().add_liquidity(_depositArray, 0);
    }

    /// @inheritdoc ETHConvexBaseStrategy
    function curveRemoveLiquidity(uint256 _liquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPoolPayable pool = getCurvePool();
        if (_outputCode == 1) {
            pool.remove_liquidity_one_coin(_liquidity, 0, 0);
        } else if (_outputCode == 2) {
            pool.remove_liquidity_one_coin(_liquidity, 1, 0);
        } else {
            pool.remove_liquidity(_liquidity, [uint256(0), uint256(0)]);
        }
    }
}
