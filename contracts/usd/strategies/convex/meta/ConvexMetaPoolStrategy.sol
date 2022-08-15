// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../../external/curve/ICurveLiquidityPool.sol";
import "../../../../external/yearn/IYearnVault.sol";

import "../ConvexBaseStrategy.sol";

contract ConvexMetaPoolStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant POOL3 = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address private constant CRV3 = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    uint256 private constant USD_INDEX = 0;
    uint256 private constant CRV3_INDEX = 1;

    address public pairToken;

    function initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address _pairToken,
        address _curvePool,
        address _rewardPool
    ) external initializer {
        pairToken = _pairToken;
        address[] memory _wants = new address[](4);
        // the oder is same with underlying coins
        // DAI
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        // USDC
        _wants[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        // USDT
        _wants[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        _wants[3] = _pairToken;
        super._initialize(_vault, _harvester, _name, _wants, _curvePool, _rewardPool);
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
        ICurveLiquidityPool curveLiquidityPool = ICurveLiquidityPool(curvePool);
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        _ratios[3] = curveLiquidityPool.balances(USD_INDEX);
        uint256 crv3Amount = curveLiquidityPool.balances(CRV3_INDEX);
        uint256 crv3Supply = IERC20Upgradeable(CRV3).totalSupply();
        for (uint256 i = 0; i < 3; i++) {
            _ratios[i] = (ICurveLiquidityPool(POOL3).balances(i) * crv3Amount) / crv3Supply;
        }
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory outputsInfo)
    {
        address[] memory _wants = wants;
        outputsInfo = new OutputInfo[](5);
        OutputInfo memory info0 = outputsInfo[0];
        info0.outputCode = 0;
        info0.outputTokens = _wants; //other

        OutputInfo memory info1 = outputsInfo[1];
        info1.outputCode = 1;
        info1.outputTokens = new address[](1);
        info1.outputTokens[0] = _wants[0];

        OutputInfo memory info2 = outputsInfo[2];
        info2.outputCode = 2;
        info2.outputTokens = new address[](1);
        info2.outputTokens[0] = _wants[1];

        OutputInfo memory info3 = outputsInfo[3];
        info3.outputCode = 3;
        info3.outputTokens = new address[](1);
        info3.outputTokens[0] = _wants[2];

        OutputInfo memory info4 = outputsInfo[4];
        info4.outputCode = 4;
        info4.outputTokens = new address[](1);
        info4.outputTokens[0] = _wants[3];
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
        ICurveLiquidityPool pool = ICurveLiquidityPool(curvePool);
        uint256 crv3Amount = pool.balances(CRV3_INDEX);
        uint256 crv3Supply = IERC20Upgradeable(CRV3).totalSupply();
        _amounts[3] = (pool.balances(USD_INDEX) * lpAmount) / totalSupply;
        for (uint256 i = 0; i < 3; i++) {
            _amounts[i] =
                (((ICurveLiquidityPool(POOL3).balances(i) * crv3Amount) / crv3Supply) * lpAmount) /
                totalSupply;
        }
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _assets = wants;
        uint256 crv3Amount = ICurveLiquidityPool(curvePool).balances(CRV3_INDEX);
        uint256 crv3Supply = IERC20Upgradeable(CRV3).totalSupply();
        uint256 thirdPoolAssets = queryTokenValue(
            _assets[3],
            ICurveLiquidityPool(curvePool).balances(USD_INDEX)
        );
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
        address _curvePool = curvePool;
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
            IERC20Upgradeable(CRV3).safeApprove(_curvePool, 0);
            IERC20Upgradeable(CRV3).safeApprove(_curvePool, balanceOf3Crv);
        }

        if (_amounts[3] > 0) {
            IERC20Upgradeable(_assets[3]).safeApprove(_curvePool, 0);
            IERC20Upgradeable(_assets[3]).safeApprove(_curvePool, _amounts[3]);
        }

        ICurveLiquidityPool(curvePool).add_liquidity([_amounts[3], balanceOf3Crv], 0);
        return balanceOfToken(lpToken);
    }

    function curveRemoveLiquidity(uint256 liquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool pool = ICurveLiquidityPool(curvePool);
        if (_outputCode == 4) {
            pool.remove_liquidity_one_coin(liquidity, 0, 0);
        } else if (_outputCode > 0 && _outputCode < 4) {
            int128 index;
            if (_outputCode == 1) {
                index = 0;
            } else if (_outputCode == 2) {
                index = 1;
            } else if (_outputCode == 3) {
                index = 2;
            }
            pool.remove_liquidity_one_coin(liquidity, 1, 0);
            uint256 balanceOf3Crv = balanceOfToken(CRV3);
            ICurveLiquidityPool(POOL3).remove_liquidity_one_coin(balanceOf3Crv, index, 0);
        } else {
            pool.remove_liquidity(liquidity, [uint256(0), uint256(0)]);
            uint256 balanceOf3Crv = balanceOfToken(CRV3);
            ICurveLiquidityPool(POOL3).remove_liquidity(
                balanceOf3Crv,
                [uint256(0), uint256(0), uint256(0)]
            );
        }
        console.log('want0 balance:',balanceOfToken(wants[0]));
        console.log('want1 balance:',balanceOfToken(wants[1]));
        console.log('want2 balance:',balanceOfToken(wants[2]));
        console.log('want3 balance:',balanceOfToken(wants[3]));
    }
}
