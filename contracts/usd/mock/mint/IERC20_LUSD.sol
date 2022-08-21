// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IERC20_LUSD is IERC20MetadataUpgradeable {
    function borrowerOperationsAddress() external view returns (address);

    function mint(address _to, uint256 _amount) external;
}
