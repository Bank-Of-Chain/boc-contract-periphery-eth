// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "boc-contract-core/contracts/exchanges/IExchangeAdapter.sol";
import "boc-contract-core/contracts/library/RevertReasonParser.sol";
import "../utils/ExchangeHelpers.sol";

import "@openzeppelin/contracts~v3/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts~v3/math/SafeMath.sol";

contract OneInchV4Adapter is IExchangeAdapter, ExchangeHelpers {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event Response(bool _success, bytes _data);

    address private constant AGGREGATION_ROUTER_V4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    receive() external payable {}

    fallback() external payable {}

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier An identifier string
    function identifier() external pure override returns (string memory) {
        return "oneInchV4";
    }

    function swap(
        uint8,
        bytes calldata _data,
        SwapDescription calldata _sd
    ) external payable override returns (uint256) {
        bool _success;
        bytes memory _result;
        uint256 _toTokenBefore = getTokenBalance(_sd.dstToken, address(this));

        if (_sd.srcToken != NativeToken.NATIVE_TOKEN) {
            IERC20(_sd.srcToken).safeApprove(AGGREGATION_ROUTER_V4, 0);
            IERC20(_sd.srcToken).safeApprove(AGGREGATION_ROUTER_V4, _sd.amount);
            (_success, _result) = AGGREGATION_ROUTER_V4.call(_data);
        } else {
            (_success, _result) = payable(AGGREGATION_ROUTER_V4).call{value: msg.value}(_data);
        }

        emit Response(_success, _result);

        if (!_success) {
            revert(RevertReasonParser.parse(_result, "1inch V4 swap failed: "));
        }

        uint256 _exchangeAmount = getTokenBalance(_sd.dstToken, address(this)) - _toTokenBefore;
        if (_sd.dstToken != NativeToken.NATIVE_TOKEN) {
            IERC20(_sd.dstToken).safeTransfer(_sd.receiver, _exchangeAmount);
        } else {
            payable(_sd.receiver).transfer(_exchangeAmount);
        }
        return _exchangeAmount;
    }
}
