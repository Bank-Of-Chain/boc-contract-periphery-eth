// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDForcePriceModel {
    function isPriceModel() external view returns (bool);

    function getAssetPrice(address _asset) external returns (uint256);

    function getAssetStatus(address _asset) external returns (bool);

    function getAssetPriceStatus(address _asset) external returns (uint256, bool);
}
