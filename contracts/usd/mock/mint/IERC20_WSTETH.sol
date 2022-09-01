// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IERC20_WSTETH is IERC20MetadataUpgradeable {
    function wrap(uint256 _amount) external;

    function stEthPerToken() external view returns (uint256);

    function tokensPerStEth() external view returns (uint256);
}
