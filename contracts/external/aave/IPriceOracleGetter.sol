// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceOracleGetter {
  function getAssetPrice(address asset) external view returns (uint256);
}