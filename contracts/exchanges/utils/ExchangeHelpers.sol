// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts~v3/math/SafeMath.sol";
import "@openzeppelin/contracts~v3/token/ERC20/SafeERC20.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "hardhat/console.sol";

abstract contract ExchangeHelpers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function __validateFromTokenAmount(address _fromToken, address _srcToken) internal pure {
        require(_fromToken == _srcToken, "srcToken diff");
    }

    function __validateToTokenAddress(address _toToken, address _dstToken) internal pure {
        require(_toToken == _dstToken, "dstToken diff");
    }

    function __approveAssetMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        if(_asset == NativeToken.NATIVE_TOKEN){
            return;
        }
        if (IERC20(_asset).allowance(address(this), _target) < _neededAmount) {
            IERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }

    function getTokenBalance(address _dstToken, address _owner) internal view returns (uint256){
        uint256 _tokenBalance;
        if(_dstToken == NativeToken.NATIVE_TOKEN){
            _tokenBalance = _owner.balance;
        }else{
            _tokenBalance = IERC20(_dstToken).balanceOf(_owner);
        }
        console.log("getTokenBalance dstToken:%s, balance:%s, owner:%s", _dstToken, _tokenBalance, _owner);
        return _tokenBalance;
    }

}
