// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexBaseStrategy.sol";
import "../../../external/compound/ICToken.sol";
import "../../../external/curve/ICurveLiquidityPool.sol";
import "../../../external/curve/ICurveLiquidityCustomPool.sol";
import "../../../external/yearn/IYearnVault.sol";

contract ConvexPaxStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address private constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private constant USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address private constant PAX = address(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    address private constant ycDAI = address(0x99d1Fa417f94dcD62BfE781a1213c092a47041Bc);
    address private constant ycUSDC = address(0x9777d7E2b60bB01759D0E2f8be2095df444cb07E);
    address private constant ycUSDT = address(0x1bE5d71F2dA660BFdee8012dDc58D024448A0A59);

    function initialize(address _vault, address _harvester,string memory _name) public initializer {
        address[] memory _wants = new address[](4);
        _wants[0] = DAI;
        _wants[1] = USDC;
        _wants[2] = USDT;
        _wants[3] = PAX;
        super._initialize(
            _vault,
            _harvester,
            _name,
            _wants,
            0x06364f10B501e868329afBc005b3492902d6C763,
            0xe3DaafC8C14147d5B4A7a56F0BfdED240158e51e
        );
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }


    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        ICurveLiquidityCustomPool curvePoolContract = ICurveLiquidityCustomPool(curvePool);
        _ratios[0] =
            IYearnVault(ycDAI).getPricePerFullShare() *
            curvePoolContract.balances(int128(0));
        _ratios[1] =
            IYearnVault(ycUSDC).getPricePerFullShare() *
            curvePoolContract.balances(int128(1));
        _ratios[2] =
            IYearnVault(ycUSDT).getPricePerFullShare() *
            curvePoolContract.balances(int128(2));
        _ratios[3] = curvePoolContract.balances(int128(3)) * 1e18;
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](1);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = wants;

        // not support remove_liquidity_one_coin
    }

    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        )
    {
        _isUsd = true;
        _usdValue =
            (ICurveLiquidityPool(curvePool).get_virtual_price() * balanceOfLpToken()) /
            decimalUnitOfToken(lpToken);
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        return
            (ICurveLiquidityPool(curvePool).get_virtual_price() *
                IERC20Upgradeable(lpToken).totalSupply()) / decimalUnitOfToken(lpToken);
    }

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        uint256[] memory _depositAmounts = new uint256[](4);
        address[] memory _yTokens = new address[](4);
        _yTokens[0] = ycDAI;
        _yTokens[1] = ycUSDC;
        _yTokens[2] = ycUSDT;
        _yTokens[3] = PAX;
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] > 0) {
                // The last coin, PAX, does not require investment into yearn
                if (_assets.length - 1 != i) {
                    IERC20Upgradeable(_assets[i]).safeApprove(_yTokens[i], 0);
                    IERC20Upgradeable(_assets[i]).safeApprove(_yTokens[i], _amounts[i]);
                    IYearnVault(_yTokens[i]).deposit(_amounts[i]);
                }
                _depositAmounts[i] = balanceOfToken(_yTokens[i]);
                IERC20Upgradeable(_yTokens[i]).safeApprove(curvePool, 0);
                IERC20Upgradeable(_yTokens[i]).safeApprove(curvePool, _depositAmounts[i]);
            }
        }
        ICurveLiquidityPool(curvePool).add_liquidity(
            [_depositAmounts[0], _depositAmounts[1], _depositAmounts[2], _depositAmounts[3]],
            0
        );
        return balanceOfToken(lpToken);
    }

    function curveRemoveLiquidity(uint256 _removeLiquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool(curvePool).remove_liquidity(
            _removeLiquidity,
            [uint256(0), uint256(0), uint256(0), uint256(0)]
        );
        uint256 _yDaiBalance = balanceOfToken(ycDAI);
        console.log("daiBalance:%d", _yDaiBalance);
        if (_yDaiBalance > 0) {
            IYearnVault(ycDAI).withdraw(_yDaiBalance);
        }
        uint256 _yUsdcBalance = balanceOfToken(ycUSDC);
        console.log("_yUsdcBalance:%d", _yUsdcBalance);
        if (_yUsdcBalance > 0) {
            IYearnVault(ycUSDC).withdraw(_yUsdcBalance);
        }
        uint256 _yUsdtBalance = balanceOfToken(ycUSDT);
        console.log("_yUsdtBalance:%d", _yUsdtBalance);
        if (_yUsdtBalance > 0) {
            IYearnVault(ycUSDT).withdraw(_yUsdtBalance);
        }
        uint256 _yTusdBalance = balanceOfToken(PAX);
        console.log("PaxBalance:%d", _yTusdBalance);
    }
}
