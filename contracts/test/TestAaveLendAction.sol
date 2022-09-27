// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <council@enzyme.finance>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";

import "../utils/actions/AaveLendActionMixin.sol";

contract TestAaveLendAction is AaveLendActionMixin {
    constructor(
        uint256 _interestRateMode,
        address _collaternalToken,
        address _borrowToken
    ) {
        __initLendConfigation(_interestRateMode, _collaternalToken, _borrowToken);
    }

    receive() external payable {}

    fallback() external payable {}

    function addCollaternal(uint256 _collaternalAmount) external payable {
        if (collaternalToken != NativeToken.NATIVE_TOKEN) {
            IERC20(collaternalToken).transferFrom(msg.sender, address(this), _collaternalAmount);
        }
        __addCollaternal(_collaternalAmount);
    }

    function removeCollaternal(uint256 _collaternalAmount) external {
        __removeCollaternal(_collaternalAmount);
    }

    function borrow(uint256 _borrowAmount) external {
        __borrow(_borrowAmount);
    }

    function repay(uint256 _repayAmount) external {
        __repay(_repayAmount);
    }
}
