// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDForcePriceOracle {
    /**
     * @notice Get the underlying price of a iToken asset
     * @param _iToken The iToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address _iToken) external view returns (uint256);

    /**
     * @notice Get the price of a underlying asset
     * @param _iToken The iToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable and whether the price is valid.
     */
    function getUnderlyingPriceAndStatus(address _iToken) external view returns (uint256, bool);

    /**
     * @dev Set price for an asset.
     * @param _asset Asset address.
     * @param _requestedPrice Requested new price, scaled by 10**18.
     * @return Boolean ture:success, false:fail.
     */
    function setPrice(address _asset, uint256 _requestedPrice) external returns (bool);

    /**
     * @notice Entry point for updating multiple prices.
     * @dev Set prices for a variable number of assets.
     * @param _assets A list of up to assets for which to set a price.
     *        Notice: 0 < _assets.length == _requestedPrices.length
     * @param _requestedPrices Requested new prices for the assets, scaled by 10**18.
     *        Notice: 0 < _assets.length == _requestedPrices.length
     * @return Boolean values in same order as inputs.
     *         For each: ture:success, false:fail.
     */
    function setPrices(address[] memory _assets, uint256[] memory _requestedPrices)
        external
        returns (bool[] memory);

    /**
     * @notice Asset's priceModel address.
     * @dev Stored the value of asset's `priceModel_` .
     * @param _asset The asset address.
     * @return Address priceModel address.
     */
    function priceModel(address _asset) external view returns (address);

    function _setAssetPriceModel(address _asset, address _priceModel) external;
}
