// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import 'hardhat/console.sol';
import '../../../external/oneinch/IOneInchV4.sol';
import '../IETHExchangeAdapter.sol';
import '../utils/ExchangeHelpers.sol';

import '@openzeppelin/contracts~v3/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts~v3/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts~v3/math/SafeMath.sol';
import 'boc-contract-core/contracts/library/RevertReasonParser.sol';
import "../../../library/ETHToken.sol";

contract EthOneInchV4Adapter is IETHExchangeAdapter, ExchangeHelpers {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    event Response(bool success, bytes data);

    address private immutable AGGREGATION_ROUTER_V4 = address(0x1111111254fb6c44bAC0beD2854e76F90643097d);

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return 'oneInchV4';
    }

    function swap(uint8, bytes calldata _data, SwapDescription calldata _sd) external payable override returns (uint256){
        bool success;
        bytes memory result;
        uint256 toTokenBefore = getTokenBalance(_sd.dstToken, address(this));

        if(_sd.srcToken != ETHToken.NATIVE_TOKEN){
            IERC20(_sd.srcToken).safeApprove(AGGREGATION_ROUTER_V4, 0);
            IERC20(_sd.srcToken).safeApprove(AGGREGATION_ROUTER_V4, _sd.amount);
            (success, result) = AGGREGATION_ROUTER_V4.call(_data);
        }else{
            (success, result) = payable(AGGREGATION_ROUTER_V4).call{value: _sd.amount}(_data);
        }

        emit Response(success, result);
        if (!success) {
            revert(RevertReasonParser.parse(result, '1inch V4 swap failed: '));
        }

        uint256 exchangeAmount = getTokenBalance(_sd.dstToken, address(this)) - toTokenBefore;
        _sd.dstToken == ETHToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(exchangeAmount):IERC20(_sd.dstToken).safeTransfer(_sd.receiver, exchangeAmount);
        console.log('swap and transfer ok, return _sd.receiver:%s, token:%s, exchangeAmount:%s', _sd.receiver, _sd.dstToken, exchangeAmount);
        return exchangeAmount;
    }

    receive() external payable {
    }
}
