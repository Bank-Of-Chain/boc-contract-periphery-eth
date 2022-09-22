// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title IERC20_WETH
/// @notice The simple interface of WETH token
interface IERC20_WETH is IERC20MetadataUpgradeable {
    function deposit() external;
}
