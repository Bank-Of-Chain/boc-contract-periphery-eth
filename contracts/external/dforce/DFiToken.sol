// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DFiToken {
    function mint(address, uint256) external;

    function redeem(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}
