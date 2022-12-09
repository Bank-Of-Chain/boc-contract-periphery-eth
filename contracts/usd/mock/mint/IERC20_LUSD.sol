// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title IERC20_LUSD
/// @notice The simple interface of LUSD token
interface IERC20_LUSD is IERC20MetadataUpgradeable {
    function borrowerOperationsAddress() external view returns (address);

    function mint(address _to, uint256 _amount) external;
}
