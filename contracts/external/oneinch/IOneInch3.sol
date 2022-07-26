// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface IOneInch3 {

    struct OneInchSwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swap(
        address caller,
        OneInchSwapDescription calldata desc,
        bytes calldata data
    )external;

    function unoswap(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata /* pools */
    ) external;
}
