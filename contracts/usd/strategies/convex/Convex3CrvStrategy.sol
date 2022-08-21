// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/curve/ICurveLiquidityPool.sol";

import "./ConvexBaseStrategy.sol";

contract Convex3CrvStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        address _vault,
        address _harvester,
        string memory _name
    ) public {
        address[] memory _wants = new address[](3);
        // the oder is same with coins
        // DAI
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        // USDC
        _wants[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        // USDT
        _wants[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        super._initialize(
            _vault,
            _harvester,
            _name,
            _wants,
            0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7,
            0x689440f2Ff927E1f24c72F1087E1FAF471eCe1c8
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
        ICurveLiquidityPool pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _assets.length; i++) {
            _ratios[i] = pool.balances(i);
        }
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        address[] memory _wants = wants;
        _outputsInfo = new OutputInfo[](4);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = _wants;

        OutputInfo memory _info1 = _outputsInfo[1];
        _info1.outputCode = 1;
        _info1.outputTokens = new address[](1);
        _info1.outputTokens[0] = _wants[0];

        OutputInfo memory _info2 = _outputsInfo[2];
        _info2.outputCode = 2;
        _info2.outputTokens = new address[](1);
        _info2.outputTokens[0] = _wants[1];

        OutputInfo memory _info3 = _outputsInfo[3];
        _info3.outputCode = 3;
        _info3.outputTokens = new address[](1);
        _info3.outputTokens[0] = _wants[2];
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
        _tokens = wants;
        _amounts = new uint256[](_tokens.length);
        // curve LP token amount = convex LP token amount
        uint256 _lpAmount = balanceOfLpToken();
        // curve LP total supply
        uint256 _totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        // calc balances
        ICurveLiquidityPool pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 _depositedTokenAmount = (pool.balances(i) * _lpAmount) / _totalSupply;
            _amounts[i] = balanceOfToken(_tokens[i]) + _depositedTokenAmount;
        }
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _assets = wants;
        uint256 _thirdPoolAssets;
        ICurveLiquidityPool pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _thirdPoolAssetBalance = pool.balances(i);
            _thirdPoolAssets += queryTokenValue(_assets[i], _thirdPoolAssetBalance);
        }
        return _thirdPoolAssets;
    }

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        address _curvePool = curvePool;
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] > 0) {
                IERC20Upgradeable(_assets[i]).safeApprove(_curvePool, 0);
                IERC20Upgradeable(_assets[i]).safeApprove(_curvePool, _amounts[i]);
            }
        }
        ICurveLiquidityPool(_curvePool).add_liquidity([_amounts[0], _amounts[1], _amounts[2]], 0);
        return balanceOfToken(lpToken);
    }

    function curveRemoveLiquidity(uint256 _liquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        if (_outputCode > 0 && _outputCode < 4) {
            int128 index;
            if (_outputCode == 1) {
                index = 0;
            } else if (_outputCode == 2) {
                index = 1;
            } else if (_outputCode == 3) {
                index = 2;
            }
            _pool.remove_liquidity_one_coin(_liquidity, index, 0);
        } else {
            _pool.remove_liquidity(_liquidity, [uint256(0), uint256(0), uint256(0)]);
        }
    }
}
