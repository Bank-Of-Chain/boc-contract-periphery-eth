// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts~v3/math/SafeMath.sol';
import 'boc-contract-core/contracts/exchanges/IExchangeAdapter.sol';

abstract contract ExchangeHelpers {
    using SafeMath for uint256;

    function __validateFromTokenAmount(address _fromToken, IExchangeAdapter.SwapDescription calldata _sd) internal pure {
        require(_fromToken == _sd.srcToken, 'srcToken diff');
//        require(_sd.amount == _fromAmount, 'fromAmount diff');
//        require(_sd.amount >= _fromAmount.mul(uint256(10000).sub(_sd.biasPercent)).div(10000) && _sd.amount <= _fromAmount.mul(uint256(10000).add(_sd.biasPercent)).div(10000), 'amount biasPercent error');
    }

    function __validateToTokenAddress(address _toToken,IExchangeAdapter.SwapDescription calldata _sd) internal pure {
        require(_toToken == _sd.dstToken, 'dstToken diff');
    }

}
