// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title IERC20_SUSD
/// @notice The simple interface of SUSD token
interface IERC20_SUSD is IERC20MetadataUpgradeable {
    function issue(address to, uint256 _amount) external;

    function owner() external view returns (address);
}
