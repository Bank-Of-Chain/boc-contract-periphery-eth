// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0 <0.9.0;

// import "./ConvexYTokenBaseStrategy.sol";

// contract ConvexBusdStrategy is ConvexYTokenBaseStrategy {

//     function initialize(address _vault, address _harvester) public {
//         super.__initialize(
//             _vault,
//             _harvester
//         );
//     }

//     function getAnotherUSD() internal pure override returns(address) {
//         return address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
//     }

//     function getCurvePool() internal pure override returns(ICurveLiquidityPool) {
//         return ICurveLiquidityPool(address(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27));
//     }

//     function getRewardPool() internal pure override returns(IConvexReward) {
//         return IConvexReward(address(0x602c4cD53a715D8a7cf648540FAb0d3a2d546560));
//     }

//     function name() external pure override returns (string memory) {
//         return "ConvexBusdStrategy";
//     }

//     function getYTokens() internal pure override returns (IYearnVault[] memory) {
//         IYearnVault[] memory yTokens = new IYearnVault[](4);
//         yTokens[0] = IYearnVault(address(0xC2cB1040220768554cf699b0d863A3cd4324ce32));
//         yTokens[1] = IYearnVault(address(0x26EA744E5B887E5205727f55dFBE8685e3b21951));
//         yTokens[2] = IYearnVault(address(0xE6354ed5bC4b393a5Aad09f21c46E101e692d447));
//         yTokens[3] = IYearnVault(address(0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE));
//         return yTokens;
//     }
// }
