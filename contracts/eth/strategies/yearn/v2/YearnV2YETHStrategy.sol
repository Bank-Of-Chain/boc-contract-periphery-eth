// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
//
// import "./YearnV2BaseStrategy.sol";
// import "../../../../external/yearn/IYearnVaultV2.sol";

// contract YearnV2YETHStrategy is YearnV2BaseStrategy {
//     using SafeERC20Upgradeable for IERC20Upgradeable;

//     address internal constant wETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

//     function initialize(address _vault) public {
//         super._initialize(_vault, wETH);
//     }

//     function getVersion() external pure virtual override returns (string memory) {
//         return "1.0.0";
//     }

//     function name() public pure override returns (string memory) {
//         return "YearnV2YETHStrategy";
//     }

//     function getYVault() internal pure override returns (IYearnVaultV2) {
//         return IYearnVaultV2(address(0xa258C4606Ca8206D8aA700cE2143D7db854D168c));
//     }
// }