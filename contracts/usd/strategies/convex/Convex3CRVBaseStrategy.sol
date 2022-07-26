// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/curve/ICurveLiquidityPool.sol";
import "../../../external/yearn/IYearnVault.sol";

import "./ConvexBaseStrategy.sol";

abstract contract Convex3CRVBaseStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant POOL3 = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address private constant CRV3 = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    uint256 private constant USD_INDEX = 0;
    uint256 private constant CRV3_INDEX = 1;

    function __initialize(address _vault, address _harvester) internal {
        address[] memory _wants = new address[](4);
        // the oder is same with underlying coins
        // DAI
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        // USDC
        _wants[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        // USDT
        _wants[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        _wants[3] = getAnotherUSD();
        super._initialize(_vault, _harvester, _wants);
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function getAnotherUSD() internal pure virtual returns (address);

    function getCurvePool() internal pure virtual returns (ICurveLiquidityPool);

    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        _ratios[3] = getCurvePool().balances(USD_INDEX);
        uint256 crv3Amount = getCurvePool().balances(CRV3_INDEX);
        uint256 crv3Supply = IERC20Upgradeable(CRV3).totalSupply();
        for (uint256 i = 0; i < 3; i++) {
            _ratios[i] = (ICurveLiquidityPool(POOL3).balances(i) * crv3Amount) / crv3Supply;
        }
    }

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
        // curve LP token amount = convex LP token amount
        uint256 lpAmount = balanceOfLpToken();
        // curve LP total supply
        uint256 totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        // calc balances
        _amounts = new uint256[](_tokens.length);
        uint256 crv3Amount = getCurvePool().balances(CRV3_INDEX);
        uint256 crv3Supply = IERC20Upgradeable(CRV3).totalSupply();
        _amounts[3] = (getCurvePool().balances(USD_INDEX) * lpAmount) / totalSupply;
        for (uint256 i = 0; i < 3; i++) {
            _amounts[i] =
                (((ICurveLiquidityPool(POOL3).balances(i) * crv3Amount) / crv3Supply) * lpAmount) /
                totalSupply;
        }
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _assets = wants;
        uint256 crv3Amount = getCurvePool().balances(CRV3_INDEX);
        uint256 crv3Supply = IERC20Upgradeable(CRV3).totalSupply();
        uint256 thirdPoolAssets = queryTokenValue(_assets[3], getCurvePool().balances(USD_INDEX));
        for (uint256 i = 0; i < 3; i++) {
            thirdPoolAssets += queryTokenValue(
                _assets[i],
                (ICurveLiquidityPool(POOL3).balances(i) * crv3Amount) / crv3Supply
            );
        }
        return thirdPoolAssets;
    }

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        console.log("start adding liquidity");
        bool has3Crv;
        for (uint256 i = 0; i < 3; i++) {
            if (_amounts[i] > 0) {
                has3Crv = true;
                IERC20Upgradeable(_assets[i]).safeApprove(POOL3, 0);
                IERC20Upgradeable(_assets[i]).safeApprove(POOL3, _amounts[i]);
            }
        }
        uint256 balanceOf3Crv = 0;
        if (has3Crv) {
            ICurveLiquidityPool(POOL3).add_liquidity([_amounts[0], _amounts[1], _amounts[2]], 0);
            balanceOf3Crv = balanceOfToken(CRV3);
            IERC20Upgradeable(CRV3).safeApprove(address(getCurvePool()), 0);
            IERC20Upgradeable(CRV3).safeApprove(address(getCurvePool()), balanceOf3Crv);
        }

        if (_amounts[3] > 0) {
            IERC20Upgradeable(_assets[3]).safeApprove(address(getCurvePool()), 0);
            IERC20Upgradeable(_assets[3]).safeApprove(address(getCurvePool()), _amounts[3]);
        }
        getCurvePool().add_liquidity([_amounts[3], balanceOf3Crv], 0);
        return balanceOfToken(lpToken);
    }

    function curveRemoveLiquidity(uint256 liquidity) internal override {
        console.log("liquidity:%d", liquidity);
        getCurvePool().remove_liquidity(liquidity, [uint256(0), uint256(0)]);
        uint256 balanceOf3Crv = balanceOfToken(CRV3);
        ICurveLiquidityPool(POOL3).remove_liquidity(
            balanceOf3Crv,
            [uint256(0), uint256(0), uint256(0)]
        );
    }
}
