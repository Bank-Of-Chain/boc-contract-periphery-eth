// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <council@enzyme.finance>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../external/dodo/DodoStakePool.sol';
import '../../external/dodo/DodoVault.sol';
import 'hardhat/console.sol';

contract DodoPoolActionsMixin {
    address internal lpTokenPool;

    address internal STAKE_POOL_ADDRESS;

    function __claimAllRewards() internal {
        DodoStakePool(STAKE_POOL_ADDRESS).claimAllRewards();
    }

    function __deposit(uint256 _amount) internal {
        DodoVault(lpTokenPool).approve(STAKE_POOL_ADDRESS, _amount);
        DodoStakePool(STAKE_POOL_ADDRESS).deposit(_amount);
    }

    function __withdrawLpToken(uint256 _amount) internal {
        DodoStakePool(STAKE_POOL_ADDRESS).withdraw(_amount);
    }

    function balanceOfLpToken(address addr) internal view returns (uint256 lpAmount) {
        lpAmount = DodoStakePool(STAKE_POOL_ADDRESS).balanceOf(addr);
    }

    function getPendingRewardByToken(address rewardToken) internal view returns(uint256 rewardAmount) {
        rewardAmount = DodoStakePool(STAKE_POOL_ADDRESS).getPendingRewardByToken(address(this),rewardToken);
    }
}
