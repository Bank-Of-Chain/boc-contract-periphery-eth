// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./ConvexBaseStrategy.sol";
import "../../../external/compound/ICToken.sol";
import "../../../external/curve/ICurveLiquidityPool.sol";

contract ConvexCompoundStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address private constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private constant C_DAI = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    address private constant C_USDC = address(0x39AA39c021dfbaE8faC545936693aC917d5E7563);

    function initialize(address _vault, address _harvester,string memory _name) public {
        address[] memory _wants = new address[](2);
        _wants[0] = DAI;
        _wants[1] = USDC;
        super._initialize(
            _vault,
            _harvester,
            _name,
            _wants,
            0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56,
            0xf34DFF761145FF0B05e917811d488B441F33a968
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
        _ratios[0] = ((ICToken(C_DAI).balanceOf(curvePool) * (ICToken(C_DAI).totalBorrows())) /
            ICToken(C_DAI).totalSupply());
        _ratios[1] = ((ICToken(C_USDC).balanceOf(curvePool) * (ICToken(C_USDC).totalBorrows())) /
            ICToken(C_USDC).totalSupply());
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
        uint256[] memory _depositAmounts = new uint256[](2);
        address[] memory _cTokens = new address[](2);
        _cTokens[0] = C_DAI;
        _cTokens[1] = C_USDC;
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] > 0) {
                IERC20Upgradeable(_assets[i]).safeApprove(_cTokens[i], 0);
                IERC20Upgradeable(_assets[i]).safeApprove(_cTokens[i], _amounts[i]);
                ICToken(_cTokens[i]).mint(_amounts[i]);
                _depositAmounts[i] = balanceOfToken(_cTokens[i]);
                IERC20Upgradeable(_cTokens[i]).safeApprove(curvePool, 0);
                IERC20Upgradeable(_cTokens[i]).safeApprove(curvePool, _depositAmounts[i]);
            }
        }
        ICurveLiquidityPool(curvePool).add_liquidity([_depositAmounts[0], _depositAmounts[1]], 0);
        return balanceOfToken(lpToken);
    }

    function curveRemoveLiquidity(uint256 _removeLiquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool(curvePool).remove_liquidity(_removeLiquidity, [uint256(0), uint256(0)]);
        uint256 _daiBalance = balanceOfToken(C_DAI);
        if (_daiBalance > 0) {
            ICToken(C_DAI).redeem(_daiBalance);
        }
        uint256 _usdcBalance = balanceOfToken(C_USDC);
        if (_usdcBalance > 0) {
            ICToken(C_USDC).redeem(_usdcBalance);
        }
    }
}
