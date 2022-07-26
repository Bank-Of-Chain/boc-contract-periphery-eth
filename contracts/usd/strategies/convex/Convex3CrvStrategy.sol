// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/curve/ICurveLiquidityPool.sol";

import "./ConvexBaseStrategy.sol";

contract Convex3CrvStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ICurveLiquidityPool private constant CURVE_POOL =
        ICurveLiquidityPool(address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7));

    function initialize(address _vault, address _harvester) public {
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
            _wants
        );
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "Convex3CrvStrategy";
    }

    function getRewardPool() internal pure override returns(IConvexReward) {
        return IConvexReward(address(0x689440f2Ff927E1f24c72F1087E1FAF471eCe1c8));
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
            console.log('token %s balance %d', _tokens[i], _amounts[i]);
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
        console.log('start adding liquidity');
        for (uint256 i = 0; i < _assets.length; i++) {
            console.log('amount: %d', _amounts[i]);
            if (_amounts[i] > 0) {
                IERC20Upgradeable(_assets[i]).safeApprove(address(CURVE_POOL), 0);
                IERC20Upgradeable(_assets[i]).safeApprove(address(CURVE_POOL), _amounts[i]);
            }
        }
        CURVE_POOL.add_liquidity([_amounts[0], _amounts[1], _amounts[2]], 0);
        return balanceOfToken(lpToken);
    }

    function curveRemoveLiquidity(uint256 liquidity) internal override {
        CURVE_POOL.remove_liquidity(liquidity, [uint256(0), uint256(0), uint256(0)]);
    }
}
