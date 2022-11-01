// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title IERC20_DAI
/// @notice The simple interface of DAI token
interface IERC20_DAI is IERC20MetadataUpgradeable {
    function mint(address _to, uint256 _amount) external;
}
