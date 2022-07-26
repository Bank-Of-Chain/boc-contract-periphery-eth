// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IStargatePool {

    function totalLiquidity() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function poolId() external view returns (uint256);
    function router() external view returns (address);
    function token() external view returns (address);
    function localDecimals() external view returns (uint256);
    function decimals() external view returns (uint256);

}
