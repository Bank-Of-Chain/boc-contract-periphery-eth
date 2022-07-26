// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/// @title ICurveAddressProvider interface
/// @author Enzyme Council <security@enzyme.finance>

interface IRewardPool{
    function pid() external view returns(uint256);
    //get balance of an address
    function balanceOf(address _account) external view returns(uint256);
    function totalAssets() external view returns (uint256);
    /**
     * @notice Redeems `shares` from `owner` and sends `assets`
     * of underlying tokens to `receiver`.
     */
    function redeem(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256);
    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    function extraRewards(uint256 i) external view returns(address extraReward);
    function extraRewardsLength() external view returns (uint256);
    function earned(address _account) external view returns(uint256);
    //claim rewards
    function getReward() external returns(bool);
    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns(bool);
    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account,uint256 _amount) external returns(bool);

    function rewardToken() external view returns(address);
}