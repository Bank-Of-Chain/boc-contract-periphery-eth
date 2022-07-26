// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DodoStakePoolV1 {

    function claim(address _lpToken) external;

    function deposit(address _lpToken,uint256 _amount) external;

    function getUserLpBalance(address _lpToken, address _user) external view returns (uint256);

    function withdraw(address _lpToken, uint256 _amount) external;

    function getPendingReward(address _lpToken, address _user) external view returns(uint256);
}
