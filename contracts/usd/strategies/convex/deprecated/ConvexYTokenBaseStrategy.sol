// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0 <0.9.0;

// import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
// import "hardhat/console.sol";

// import "../../../external/curve/ICurveLiquidityPool.sol";
// import "../../../external/yearn/IYearnVault.sol";

// import "./ConvexBaseStrategy.sol";

// abstract contract ConvexYTokenBaseStrategy is ConvexBaseStrategy {
//     using SafeERC20Upgradeable for IERC20Upgradeable;

//     // yToken Price Pershare
//     uint256 private constant YPP_DECIMALS = 1e18;

//     function __initialize(
//         address _vault,
//         address _harvester
//     ) internal {
//         address[] memory _wants = new address[](4);
//         // the oder is same with underlying coins
//         // DAI
//         _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
//         // USDC
//         _wants[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
//         // USDT
//         _wants[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
//         _wants[3] = getAnotherUSD();
//         super._initialize(_vault, _harvester, _wants);
//     }

//     function getVersion() external pure override returns (string memory) {
//         return "1.0.0";
//     }

//     function getAnotherUSD() internal pure virtual returns(address);
//     function getCurvePool() internal pure virtual returns(ICurveLiquidityPool);

//     function getYTokens() internal pure virtual returns (IYearnVault[] memory);

//     function getWantsInfo()
//         public
//         view
//         override
//         returns (address[] memory _assets, uint256[] memory _ratios)
//     {
//         _assets = wants;
//         _ratios = new uint256[](_assets.length);
//         IYearnVault[] memory yTokens = getYTokens();
//         int128 balancesIndex = 0;
//         for (uint256 i = 0; i < _assets.length; i++) {
//             _ratios[i] =
//                 (getCurvePool().balances(balancesIndex) * yTokens[i].getPricePerFullShare()) /
//                 YPP_DECIMALS;
//             balancesIndex++;
//         }
//     }

//     function getOutputsInfo()
//         external
//         view
//         virtual
//         override
//         returns (OutputInfo[] memory outputsInfo){}

//     function getPositionDetail()
//         public
//         view
//         override
//         returns (
//             address[] memory _tokens,
//             uint256[] memory _amounts,
//             bool isUsd,
//             uint256 usdValue
//         )
//     {
//         _tokens = wants;
//         // curve LP token amount = convex LP token amount
//         uint256 lpAmount = balanceOfLpToken();
//         // curve LP total supply
//         uint256 totalSupply = IERC20Upgradeable(lpToken).totalSupply();
//         // calc balances
//         _amounts = new uint256[](_tokens.length);
//         IYearnVault[] memory yTokens = getYTokens();
//         int128 balancesIndex = 0;
//         for (uint256 i = 0; i < _tokens.length; i++) {
//             _amounts[i] =
//                 balanceOfToken(_tokens[i]) +
//                 (getCurvePool().balances(balancesIndex) * yTokens[i].getPricePerFullShare() / YPP_DECIMALS) * lpAmount / totalSupply;
//             balancesIndex++;
//         }
//     }

//     function get3rdPoolAssets() external view override returns (uint256 thirdPoolAssets) {
//         address[] memory _assets = wants;
//         IYearnVault[] memory yTokens = getYTokens();
//         int128 balancesIndex = 0;
//         for (uint256 i = 0; i < _assets.length; i++) {
//             thirdPoolAssets += queryTokenValue(
//                 _assets[i],
//                 (getCurvePool().balances(int128(balancesIndex)) * yTokens[i].getPricePerFullShare()) /
//                     YPP_DECIMALS
//             );
//             balancesIndex++;
//         }
//         return thirdPoolAssets;
//     }

//     function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
//         internal
//         override
//         returns (uint256)
//     {
//         console.log("start adding liquidity");
//         IYearnVault[] memory yTokens = getYTokens();
//         uint256[] memory yTokenAmounts = new uint256[](4);
//         for (uint256 i = 0; i < _assets.length; i++) {
//             console.log("amount: %d", _amounts[i]);
//             if (_amounts[i] > 0) {
//                 address yTokenAddress = address(yTokens[i]);
//                 IERC20Upgradeable(_assets[i]).safeApprove(yTokenAddress, 0);
//                 IERC20Upgradeable(_assets[i]).safeApprove(yTokenAddress, _amounts[i]);
//                 yTokens[i].deposit(_amounts[i]);
//                 yTokenAmounts[i] = balanceOfToken(yTokenAddress);
//                 IERC20Upgradeable(yTokenAddress).safeApprove(address(getCurvePool()), 0);
//                 IERC20Upgradeable(yTokenAddress).safeApprove(address(getCurvePool()), yTokenAmounts[i]);
//             }
//         }
//         getCurvePool().add_liquidity(
//             [yTokenAmounts[0], yTokenAmounts[1], yTokenAmounts[2], yTokenAmounts[3]],
//             0
//         );
//         return balanceOfToken(lpToken);
//     }

//     function curveRemoveLiquidity(uint256 liquidity, uint256 _outputCode) internal override {
//         console.log("liquidity:%d", liquidity);
//         getCurvePool().remove_liquidity(liquidity, [uint256(0), uint256(0), uint256(0), uint256(0)]);
//         IYearnVault[] memory yTokens = getYTokens();
//         for (uint256 i = 0; i < yTokens.length; i++) {
//             uint256 yTokenAmount = balanceOfToken(address(yTokens[i]));
//             if (yTokenAmount > 0) {
//                 yTokens[i].withdraw(yTokenAmount);
//             }
//         }
//     }
// }
