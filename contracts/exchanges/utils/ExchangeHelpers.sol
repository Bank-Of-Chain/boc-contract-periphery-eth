// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "boc-contract-core/contracts/library/NativeToken.sol";
import "@openzeppelin/contracts~v3/token/ERC20/IERC20.sol";

/// @title OneInchV4ExchangeHelpersdapter
/// @notice Helpers for exchange
/// @author Bank of Chain Protocol Inc
abstract contract ExchangeHelpers {

    /// @notice Gets the ``_dstToken``'s balance of `_owner`
    /// @param _dstToken The token get balance from
    /// @param _owner The address to get balance
    /// @return The ``_dstToken``'s balance of `_owner`
    function getTokenBalance(address _dstToken, address _owner) internal view returns (uint256){
        uint256 _tokenBalance;
        if(_dstToken == NativeToken.NATIVE_TOKEN){
            _tokenBalance = _owner.balance;
        }else{
            _tokenBalance = IERC20(_dstToken).balanceOf(_owner);
        }
        return _tokenBalance;
    }

}
