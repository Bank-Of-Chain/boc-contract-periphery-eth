// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DodoStakePool {
    function claimReward(address _lpToken) external;

    function claimAllRewards() external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function balanceOf(address addr) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getPendingReward(address user, uint256 i) external view returns (uint256);

    function getPendingRewardByToken(address user, address rewardToken) external view returns (uint256);
}
