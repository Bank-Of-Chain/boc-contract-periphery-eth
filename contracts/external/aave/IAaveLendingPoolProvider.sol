// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title AaveLendingPoolProvider interface
 * @notice Interface for the Aave Price Oracle IAavePriceOracle.
 * @author Aave
 **/
 
interface IAaveLendingPoolProvider {
    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}
