// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IOneInchV4 {

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
    )external payable returns (
        uint256 returnAmount,
        uint256 spentAmount,
        uint256 gasLeft
    );

    function unoswap(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external payable returns(uint256 returnAmount);

    function unoswapWithPermit(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] calldata pools,
        bytes calldata permit
    ) external returns(uint256 returnAmount);

    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns(uint256 returnAmount);

    function uniswapV3SwapTo(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns(uint256 returnAmount);

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;

    function uniswapV3SwapToWithPermit(
        address payable recipient,
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools,
        bytes calldata permit
    ) external returns(uint256 returnAmount);

    function clipperSwap(
        address srcToken,
        address dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns(uint256 returnAmount);

    function clipperSwapTo(
        address payable recipient,
        address srcToken,
        address dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns(uint256 returnAmount);

    function clipperSwapToWithPermit(
        address payable recipient,
        address srcToken,
        address dstToken,
        uint256 amount,
        uint256 minReturn,
        bytes calldata permit
    ) external returns(uint256 returnAmount);
}
