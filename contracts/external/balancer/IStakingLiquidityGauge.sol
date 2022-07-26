// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface  IStakingLiquidityGauge {
    function balanceOf(address _addr) external view returns (uint256);
    function deposit(uint256 value) external;
    function withdraw(uint256 value) external;
    function claim_rewards(address _addr) external;
}
