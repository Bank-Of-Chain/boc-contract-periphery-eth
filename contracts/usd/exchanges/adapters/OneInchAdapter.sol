// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "../../../external/oneinch/IOneInch3.sol";
import "boc-contract-core/contracts/exchanges/IExchangeAdapter.sol";
import "../utils/ExchangeHelpers.sol";

import "@openzeppelin/contracts~v3/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts~v3/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts~v3/math/SafeMath.sol";

contract OneInchAdapter is IExchangeAdapter, ExchangeHelpers {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum SwapMethod {
        swap,
        unoswap
    }

    address private immutable AGGREGATION_ROUTER_V3 =
        address(0x11111112542D85B3EF69AE05771c2dCCff4fAa26);

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return "oneInch";
    }

    function swap(
        uint8,
        bytes calldata _data,
        SwapDescription calldata _sd
    ) external override returns (uint256) {
        // 0x7c是1inch swap方法名的编码
        if (_data[0] == 0x7c) {
            return swap(_data, _sd);
            // 0x2e是1inch unoswap方法名的编码
        } else if (_data[0] == 0x2e) {
            return unoswap(_data, _sd);
        } else {
            revert("[OneInchAdapter] error oneinch method");
        }
    }

    function swap(bytes calldata _data, SwapDescription calldata _sd) internal returns (uint256) {
        console.log("[OneInchAdapter] it is oneinch swap method");
        (address _c, IOneInch3.OneInchSwapDescription memory desc, bytes memory _d) = abi.decode(
            _data[4:],
            (address, IOneInch3.OneInchSwapDescription, bytes)
        );
        __validateFromTokenAmount(desc.srcToken, _sd);
        __validateToTokenAddress(desc.dstToken, _sd);

        desc.minReturnAmount = _sd.amount.mul(desc.minReturnAmount).div(desc.amount);
        desc.amount = _sd.amount;
        //        desc.amount = _sd.amount;
        //        desc.minReturnAmount = _sd.minReturn;

        console.log("[OneInchAdapter] desc.srcToken:", desc.srcToken);
        console.log("[OneInchAdapter] desc.dstToken:", desc.dstToken);
        console.log("[OneInchAdapter] desc.srcReceiver:", desc.srcReceiver);
        console.log("[OneInchAdapter] desc.dstReceiver:", desc.dstReceiver);
        console.log("[OneInchAdapter] desc.amount:", desc.amount);
        console.log("[OneInchAdapter] desc.minReturnAmount:", desc.minReturnAmount);
        console.log("[OneInchAdapter] desc.flags:", desc.flags);
        uint256 toTokenBefore = IERC20(_sd.dstToken).balanceOf(address(this));
        console.log("[OneInchAdapter] swap toToken Before:", toTokenBefore);
        console.log("[OneInchAdapter] swap fromToken Before:", IERC20(desc.srcToken).balanceOf(address(this)));

        IERC20(desc.srcToken).safeApprove(AGGREGATION_ROUTER_V3, 0);
        IERC20(desc.srcToken).safeApprove(AGGREGATION_ROUTER_V3, desc.amount);
        IOneInch3(AGGREGATION_ROUTER_V3).swap(_c, desc, _d);
        console.log("[OneInchAdapter] swap ok");
        uint256 exchangeAmount = IERC20(_sd.dstToken).balanceOf(address(this)) - toTokenBefore;
        console.log("[OneInchAdapter] swap receive target amount:", exchangeAmount);
        IERC20(_sd.dstToken).safeTransfer(_sd.receiver, exchangeAmount);
        console.log("[OneInchAdapter] transfer ok");
        return exchangeAmount;
    }

    function unoswap(bytes calldata _data, SwapDescription calldata _sd)
        internal
        returns (uint256)
    {
        console.log("[OneInchAdapter] it is oneinch unoswap method");
        (address srcToken, uint256 amount, uint256 minReturn, bytes32[] memory pathData) = abi
            .decode(_data[4:], (address, uint256, uint256, bytes32[]));

        console.log("[OneInchAdapter] srcToken:", srcToken);
        console.log("[OneInchAdapter] amount:", amount);
        console.log("[OneInchAdapter] minReturn:", minReturn);
        console.log("[OneInchAdapter] unoswap approve ok");

        __validateFromTokenAmount(srcToken, _sd);

        minReturn = _sd.amount.mul(minReturn).div(amount);
        amount = _sd.amount;
        //        amount = _sd.amount;
        //        minReturn = _sd.minReturn;

        IERC20(srcToken).safeApprove(AGGREGATION_ROUTER_V3, 0);
        IERC20(srcToken).safeApprove(AGGREGATION_ROUTER_V3, amount);

        uint256 toTokenBefore = IERC20(_sd.dstToken).balanceOf(address(this));
        IOneInch3(AGGREGATION_ROUTER_V3).unoswap(srcToken, amount, minReturn, pathData);
        uint256 exchangeAmount = IERC20(_sd.dstToken).balanceOf(address(this)).sub(toTokenBefore);
        require(exchangeAmount > 0, "toToken exchange 0");
        IERC20(_sd.dstToken).safeTransfer(_sd.receiver, exchangeAmount);
        console.log("[OneInchAdapter] transfer ok");
        return exchangeAmount;
    }
}
