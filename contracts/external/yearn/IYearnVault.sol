// SPDX-License-Identifier: GPL-3.0
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

pragma solidity >=0.8.0 <0.9.0;

interface IYearnVault is IERC20Upgradeable {

    function deposit(uint256 amount) external ;

    function withdraw(uint256 maxShares) external ;

    function getPricePerFullShare() external view returns(uint);

    function calcPoolValueInToken() external view returns (uint);
}
