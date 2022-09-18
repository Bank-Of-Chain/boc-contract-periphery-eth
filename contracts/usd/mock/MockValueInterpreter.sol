// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/price-feeds/IValueInterpreter.sol";
import "boc-contract-core/contracts/price-feeds/derivatives/IAggregatedDerivativePriceFeed.sol";
import "boc-contract-core/contracts/price-feeds/derivatives/IDerivativePriceFeed.sol";
import "boc-contract-core/contracts/price-feeds/primitives/IPrimitivePriceFeed.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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
        if(priceValue[_baseAsset] == 0 || priceValue[_quoteAsset] == 0){
            _isValid = false;
        }else{
            _value =
            (priceValue[_baseAsset] * _amount * getPowDecimals(_quoteAsset)) /
            priceValue[_quoteAsset] /
            getPowDecimals(_baseAsset);
        }
    }

    /// @notice Calculate the asset value in USD
    /// @param _baseAsset The source token address
    /// @param _amount The source token amount
    /// @return _value The asset value in USD
    function calcCanonicalAssetValueInUsd(address _baseAsset, uint256 _amount)
        external
        view
        override
        returns (uint256 _value)
    {
        return (priceValue[_baseAsset] * _amount) / getPowDecimals(_baseAsset);
    }

    /*
      * usd value of baseUnit quantity assets
      * _baseAsset: source token address
      * @return usd(1e18)
     */
    /// @notice Gets the price in USD of one `_baseAsset` 
    /// @param _baseAsset The source token address
    /// @return _value The asset value in USD of one `_baseAsset` 
    function price(address _baseAsset) external view override returns (uint256 _value) {
        return priceValue[_baseAsset];
    }

    ///////////////////
    // STATE SETTERS //
    ///////////////////

    /// @notice Sets the `_baseAsset` price in USD
    /// @param _baseAsset The source token address
    /// @param _value The new value of price
    function setPrice(address _baseAsset, uint256 _value) external {
        priceValue[_baseAsset] = _value;
    }

    /// @notice Sets `PRIMITIVE_PRICE_FEED` state varizble
    /// @param _primitivePriceFeed The new value of `PRIMITIVE_PRICE_FEED`
    /// Requirements: only governance or delegate role can call
    function setPrimitivePriceFeed(address _primitivePriceFeed) external onlyGovOrDelegate {
        PRIMITIVE_PRICE_FEED = _primitivePriceFeed;
    }

    /// @notice Sets `AGGREGATED_DERIVATIVE_PRICE_FEED` state varizble
    /// @param _aggregatedDerivativePriceFeed The new value of `AGGREGATED_DERIVATIVE_PRICE_FEED`
    /// Requirements: only governance or delegate role can call
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

    /// @notice Gets the power decimals of `_asset`
    /// @return the power decimals of `_asset`
    function getPowDecimals(address _asset) private view returns (uint256) {
        if (_asset == NativeToken.NATIVE_TOKEN) {
            return 1e18;
        } else {
            return 10**IERC20Metadata(_asset).decimals();
        }
    }
}
