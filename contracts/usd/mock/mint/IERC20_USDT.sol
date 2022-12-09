// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title IERC20_USDT
/// @notice The simple interface of USDT token
interface IERC20_USDT is IERC20MetadataUpgradeable {
    function issue(uint256 _amount) external;

    function owner() external view returns (address);
}
