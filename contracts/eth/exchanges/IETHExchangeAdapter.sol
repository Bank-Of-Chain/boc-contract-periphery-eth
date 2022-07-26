// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IETHExchangeAdapter {

    struct SwapDescription {
        uint256 amount;
//        uint256 expectedReturn;
//        uint256 minReturn;
//        uint256 biasPercent;
        address srcToken;
        address dstToken;
        address receiver;
    }

    function identifier() external pure returns (string memory identifier_);

    function swap(uint8 _method, bytes calldata _encodedCallArgs, SwapDescription calldata _sd) external payable returns(uint256);
}