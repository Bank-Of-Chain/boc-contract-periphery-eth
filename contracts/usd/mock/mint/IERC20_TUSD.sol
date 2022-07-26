// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title IERC20_TUSD
/// @notice The simple interface of TUSD token
interface IERC20_TUSD is IERC20MetadataUpgradeable {
    function owner() external view returns (address);

    function mint(address _to, uint256 _amount) external;
}
