// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "../../../external/oneinch/IOneInchV4.sol";
import "boc-contract-core/contracts/exchanges/IExchangeAdapter.sol";
import "../utils/ExchangeHelpers.sol";

import "@openzeppelin/contracts~v3/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts~v3/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts~v3/math/SafeMath.sol";
import "boc-contract-core/contracts/library/RevertReasonParser.sol";

contract OneInchV4Adapter is IExchangeAdapter, ExchangeHelpers {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    event Response(bool success, bytes data);

    address private immutable AGGREGATION_ROUTER_V4 =
        address(0x1111111254fb6c44bAC0beD2854e76F90643097d);

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "oneInchV4";
    }

    function swap(
        uint8,
        bytes calldata _data,
        SwapDescription calldata _sd
    ) external override returns (uint256) {
        console.log("[OneInchV4Adapter] start safeApprove");
        IERC20(_sd.srcToken).safeApprove(AGGREGATION_ROUTER_V4, 0);
        IERC20(_sd.srcToken).safeApprove(AGGREGATION_ROUTER_V4, _sd.amount);
        console.log("[OneInchV4Adapter] start swap");
        uint256 toTokenBefore = IERC20(_sd.dstToken).balanceOf(address(this));
        (bool success, bytes memory result) = AGGREGATION_ROUTER_V4.call(_data);
        emit Response(success, result);
        if (!success) {
            revert(RevertReasonParser.parse(result, "1inch V4 swap failed: "));
        }
        console.log("[OneInchV4Adapter] swap ok");
        uint256 exchangeAmount = IERC20(_sd.dstToken).balanceOf(address(this)) - toTokenBefore;
        console.log("[OneInchV4Adapter] swap receive target amount:", exchangeAmount);
        IERC20(_sd.dstToken).safeTransfer(_sd.receiver, exchangeAmount);
        console.log("[OneInchV4Adapter] transfer ok");
        return exchangeAmount;
    }
}
