// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/price-feeds/IValueInterpreter.sol";
import "boc-contract-core/contracts/price-feeds/derivatives/IAggregatedDerivativePriceFeed.sol";
import "boc-contract-core/contracts/price-feeds/derivatives/IDerivativePriceFeed.sol";
import "boc-contract-core/contracts/price-feeds/primitives/IPrimitivePriceFeed.sol";
import "boc-contract-core/contracts/util/Helpers.sol";

import "hardhat/console.sol";

/// @title MockValueInterpreter Contract
/// @author Enzyme Council <security@enzyme.finance>
/// @notice Interprets price feeds to provide covert value between asset pairs
/// @dev This contract contains several 'live' value calculations, which for this release are simply
/// aliases to their 'canonical' value counterparts since the only primitive price feed (Chainlink)
/// is immutable in this contract and only has one type of value. Including the 'live' versions of
/// functions only serves as a placeholder for infrastructural components and plugins (e.g., policies)
/// to explicitly define the types of values that they should (and will) be using in a future release.
contract MockValueInterpreter is IValueInterpreter, AccessControlMixin {
    address private AGGREGATED_DERIVATIVE_PRICE_FEED;
    address private PRIMITIVE_PRICE_FEED;

    constructor(
        address _primitivePriceFeed,
        address _aggregatedDerivativePriceFeed,
        address _accessControlProxy
    ) {
        AGGREGATED_DERIVATIVE_PRICE_FEED = _aggregatedDerivativePriceFeed;
        PRIMITIVE_PRICE_FEED = _primitivePriceFeed;
        _initAccessControl(_accessControlProxy);
    }

    uint256 public calcCanonicalAssetsTotal;
    mapping(address => uint256) public calcCanonicalAsset;
    mapping(address => uint256) public calcCanonicalAssetInUsd;
    mapping(address => uint256) public priceValue;

    // EXTERNAL FUNCTIONS

    /// @notice Calculates the total value of given amounts of assets in a single quote asset
    /// @param _baseAssets The assets to convert
    /// @param _amounts The amounts of the _baseAssets to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return _value The sum value of _baseAssets, denominated in the _quoteAsset
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state.
    /// Does not handle a derivative quote asset.
    function calcCanonicalAssetsTotalValue(
        address[] memory _baseAssets,
        uint256[] memory _amounts,
        address _quoteAsset
    ) external view override returns (uint256 _value) {
        for (uint256 i = 0; i < _baseAssets.length; i++) {
            (uint256 _assetValue, bool _assetValueIsValid) = __calcAssetValue(
                _baseAssets[i],
                _amounts[i],
                _quoteAsset
            );
            _value = _value + _assetValue;
        }
        return _value;
    }

    /// @notice Calculates the value of a given amount of one asset in terms of another asset
    /// @param _baseAsset The asset from which to convert
    /// @param _amount The amount of the _baseAsset to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return _value The equivalent quantity in the _quoteAsset
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state
    function calcCanonicalAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) external view override returns (uint256 _value) {
        if (_baseAsset == _quoteAsset || _amount == 0) {
            return _amount;
        }
        bool _isValid;
        (_value, _isValid) = __calcAssetValue(_baseAsset, _amount, _quoteAsset);
        require(_isValid, "Invalid rate");
        return _value;
    }

    /// @dev Helper to differentially calculate an asset value
    /// based on if it is a primitive or derivative asset.
    function __calcAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) private view returns (uint256 _value, bool _isValid) {
        if (_baseAsset == _quoteAsset || _amount == 0) {
            return (_amount, true);
        }
        _isValid = true;
        console.log("_quoteAsset##:%s,price:%d ",_quoteAsset,priceValue[_quoteAsset]);
        console.log("_baseAsset##:%s,decimals:%d ",_baseAsset,Helpers.getDecimals(_baseAsset));
        _value =
            (priceValue[_baseAsset] * _amount * (10**Helpers.getDecimals(_quoteAsset))) /
            priceValue[_quoteAsset] /
            (10**Helpers.getDecimals(_baseAsset));
    }

    /*
     * asset value in usd
     * _baseAsset: source token address
     * _amount: source token amount
     * @return usd(1e18)
     */
    function calcCanonicalAssetValueInUsd(address _baseAsset, uint256 _amount)
        external
        view
        override
        returns (uint256 _value)
    {
        return (priceValue[_baseAsset] * _amount) / (10**Helpers.getDecimals(_baseAsset));
    }

    /*
      * usd value of baseUnit quantity assets
      * _baseAsset: source token address
      * @return usd(1e18)
     */
    function price(address _baseAsset) external view override returns (uint256 _value) {
        return priceValue[_baseAsset];
    }

    ///////////////////
    // STATE SETTERS //
    ///////////////////
    function setPrice(address _baseAsset, uint256 _value) external {
        priceValue[_baseAsset] = _value;
    }

    ///////////////////
    function setPrimitivePriceFeed(address _primitivePriceFeed) external onlyGovOrDelegate {
        PRIMITIVE_PRICE_FEED = _primitivePriceFeed;
    }

    function setAggregatedDerivativePriceFeed(address _aggregatedDerivativePriceFeed)
        external
        onlyGovOrDelegate
    {
        AGGREGATED_DERIVATIVE_PRICE_FEED = _aggregatedDerivativePriceFeed;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////
    /// @notice Gets the `AGGREGATED_DERIVATIVE_PRICE_FEED` variable
    /// @return _aggregatedDerivativePriceFeed The `AGGREGATED_DERIVATIVE_PRICE_FEED` variable value
    function getAggregatedDerivativePriceFeed()
        external
        view
        returns (address _aggregatedDerivativePriceFeed)
    {
        return AGGREGATED_DERIVATIVE_PRICE_FEED;
    }

    /// @notice Gets the `PRIMITIVE_PRICE_FEED` variable
    /// @return _primitivePriceFeed The `PRIMITIVE_PRICE_FEED` variable value
    function getPrimitivePriceFeed() external view returns (address _primitivePriceFeed) {
        return PRIMITIVE_PRICE_FEED;
    }
}
