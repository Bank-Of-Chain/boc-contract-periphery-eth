// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardDistributorV3 {
    function reward(address _holder) external view returns (uint256);

    function claimReward(address[] memory _holders, address[] memory _iTokens) external;

    function claimAllReward(address[] memory _holders) external;

    function claimRewards(
        address[] memory _holders,
        address[] memory _suppliediTokens,
        address[] memory _borrowediTokens
    ) external;
}
