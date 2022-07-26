// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IERC20_USDC is IERC20MetadataUpgradeable {
    function owner() external view returns (address);

    function mint(address _to, uint256 amount) external;

    function isMinter(address account) external view returns (bool);

    function masterMinter() external view returns (address);

    function configureMinter(address minter, uint256 minterAllowedAmount) external returns (bool);
}
