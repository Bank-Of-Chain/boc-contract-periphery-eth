// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0 <0.9.0;


/**
 * @title Lido
 *
 */
interface ILido {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
}
