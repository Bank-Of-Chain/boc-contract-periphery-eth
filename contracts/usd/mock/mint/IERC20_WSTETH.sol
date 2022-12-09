// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title IERC20_WSTETH
/// @notice The simple interface of WSTETH token
interface IERC20_WSTETH is IERC20MetadataUpgradeable {
    function wrap(uint256 _amount) external;

    function stEthPerToken() external view returns (uint256);

    function tokensPerStEth() external view returns (uint256);
}
