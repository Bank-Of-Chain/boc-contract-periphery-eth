// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "boc-contract-core/contracts/library/NativeToken.sol";
import "@openzeppelin/contracts~v3/token/ERC20/IERC20.sol";

abstract contract ExchangeHelpers {

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
