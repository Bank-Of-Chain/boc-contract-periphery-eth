// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IERC20_USDT is IERC20MetadataUpgradeable {
    function issue(uint256 amount) external;

    function owner() external view returns (address);
}
