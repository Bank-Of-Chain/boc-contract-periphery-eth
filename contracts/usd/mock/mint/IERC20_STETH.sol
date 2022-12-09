// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title IERC20_STETH
/// @notice The simple interface of STETH token
interface IERC20_STETH is IERC20MetadataUpgradeable {
    function submit(address _to) external;
    function removeStakingLimit() external;
}
