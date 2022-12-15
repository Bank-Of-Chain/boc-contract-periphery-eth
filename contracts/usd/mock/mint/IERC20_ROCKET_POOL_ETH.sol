// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title IERC20_ROCKET_POOL_ETH
/// @notice The simple interface of ROCKET_POOL_ETH
interface IERC20_ROCKET_POOL_ETH is IERC20MetadataUpgradeable {
    function getExchangeRate() external view returns (uint256);

    function mint(uint256 _ethAmount, address _to) external;
}
