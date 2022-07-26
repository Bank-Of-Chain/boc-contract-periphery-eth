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
import '../../external/dodo/DodoStakePoolV1.sol';

contract DodoPoolV1ActionsMixin {
    address internal STAKE_POOL_V1_ADDRESS;

    address internal BASE_LP_TOKEN;

    address internal QUOTE_LP_TOKEN;

    function __claimRewards(address _lpToken) internal {
        DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).claim(_lpToken);
    }

    function __deposit(address _lpToken, uint256 _amount) internal {
        DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).deposit(_lpToken, _amount);
    }

    function __withdrawLpToken(address _lpToken, uint256 _amount) internal {
        DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).withdraw(_lpToken, _amount);
    }

    function balanceOfBaseLpToken() internal view returns (uint256 lpAmount) {
        lpAmount = DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).getUserLpBalance(BASE_LP_TOKEN, address(this));
    }

    function balanceOfQuoteLpToken() internal view returns (uint256 lpAmount) {
        lpAmount = DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).getUserLpBalance(QUOTE_LP_TOKEN, address(this));
    }

    function getPendingReward() internal view returns(uint256 rewardAmount) {
        rewardAmount = DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).getPendingReward(BASE_LP_TOKEN, address(this));
        rewardAmount += DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).getPendingReward(QUOTE_LP_TOKEN, address(this));
    }
}
