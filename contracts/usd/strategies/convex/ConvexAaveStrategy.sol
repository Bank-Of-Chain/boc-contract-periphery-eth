// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/curve/ICurveLiquidityPool.sol";

import "./ConvexBaseStrategy.sol";

contract ConvexAaveStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ICurveLiquidityPool private constant CURVE_POOL =
        ICurveLiquidityPool(address(0xDeBF20617708857ebe4F679508E7b7863a8A8EeE));

    function initialize(address _vault, address _harvester) public {
        address[] memory _wants = new address[](3);
        // the oder is same with underlying coins
        // DAI
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        // USDC
        _wants[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        // USDT
        _wants[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        super._initialize(_vault, _harvester, _wants);
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "ConvexAaveStrategy";
    }

    function getRewardPool() internal pure override returns (IConvexReward) {
        return IConvexReward(address(0xE82c1eB4BC6F92f85BF7EB6421ab3b882C3F5a7B));
    }

    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            _ratios[i] = CURVE_POOL.balances(i);
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
        outputsInfo = new OutputInfo[](4);
        OutputInfo memory info0 = outputsInfo[0];
        info0.outputCode = 0;
        info0.outputTokens = _wants;

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
        _amounts = new uint256[](_tokens.length);
        // curve LP token amount = convex LP token amount
        uint256 lpAmount = balanceOfLpToken();
        // curve LP total supply
        uint256 totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        // calc balances
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 depositedTokenAmount = (CURVE_POOL.balances(i) * lpAmount) / totalSupply;
            _amounts[i] = balanceOfToken(_tokens[i]) + depositedTokenAmount;
        }
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _assets = wants;
        uint256 thirdPoolAssets;
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 thirdPoolAssetBalance = CURVE_POOL.balances(i);
            thirdPoolAssets += queryTokenValue(_assets[i], thirdPoolAssetBalance);
        }
        return thirdPoolAssets;
    }

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] > 0) {
                IERC20Upgradeable(_assets[i]).safeApprove(address(CURVE_POOL), 0);
                IERC20Upgradeable(_assets[i]).safeApprove(address(CURVE_POOL), _amounts[i]);
            }
        }
        return CURVE_POOL.add_liquidity([_amounts[0], _amounts[1], _amounts[2]], 0, true);
    }

    function curveRemoveLiquidity(uint256 liquidity, uint256 _outputCode) internal override {
        if (_outputCode == 0) {
            CURVE_POOL.remove_liquidity(liquidity, [uint256(0), uint256(0), uint256(0)], true);
        } else {
            int128 index;
            if (_outputCode == 1) {
                index = 0;
            } else if (_outputCode == 2) {
                index = 1;
            } else if (_outputCode == 3) {
                index = 2;
            }
            CURVE_POOL.remove_liquidity_one_coin(liquidity, index, 0, true);
        }
        console.log("DAI balance:", balanceOfToken(wants[0]));
        console.log("USDC balance:", balanceOfToken(wants[1]));
        console.log("USDT balance:", balanceOfToken(wants[2]));
    }
}
