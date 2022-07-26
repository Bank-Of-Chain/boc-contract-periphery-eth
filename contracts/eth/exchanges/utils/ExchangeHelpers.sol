// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts~v3/math/SafeMath.sol';
import '../IETHExchangeAdapter.sol';
import '@openzeppelin/contracts~v3/token/ERC20/SafeERC20.sol';
import 'hardhat/console.sol';

abstract contract ExchangeHelpers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function __approveAssetMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        if(_asset == NATIVE_TOKEN){
            return;
        }
        if (IERC20(_asset).allowance(address(this), _target) < _neededAmount) {
            IERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }
    function __validateFromTokenAmount(address _fromToken, address srcToken) internal pure {
        require(_fromToken == srcToken, 'srcToken diff');
    }

    function __validateToTokenAddress(address _toToken, address dstToken) internal pure {
        require(_toToken == dstToken, 'dstToken diff');
    }

    function getTokenBalance(address dstToken, address owner) internal view returns (uint256){
        uint256 tokenBalance;
        if(dstToken == NATIVE_TOKEN){
            tokenBalance = owner.balance;
        }else{
            tokenBalance = IERC20(dstToken).balanceOf(owner);
        }
        console.log('getTokenBalance dstToken:%s, balance:%s, owner:%s', dstToken, tokenBalance, owner);
        return tokenBalance;
    }

}
