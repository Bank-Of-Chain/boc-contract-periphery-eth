// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IAavePriceOracle interface
 * @notice Interface for the Aave Price Oracle IAavePriceOracle.
 * @author Aave
 **/
interface IAavePriceOracle {
    /// @notice Gets an asset price by address
    /// @param asset The asset address
    function getAssetPrice(address asset) external view returns (uint256);
}
