// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;


interface IBalancerMinter  {
    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gauge `LiquidityGauge` address to get mintable amount from
     */
    function mint(address gauge) external returns (uint256);
}
