// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "../IETHExchangeAdapter.sol";
import "boc-contract-core/contracts/price-feeds/IValueInterpreter.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../oracle/IPriceOracle.sol";
import "../../../library/ETHToken.sol";

contract TestAdapter is IETHExchangeAdapter {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address valueInterpreter;

    constructor(address _valueInterpreter) {
        valueInterpreter = _valueInterpreter;
    }

    function identifier() external pure override returns (string memory identifier_) {
        return "testAdapter";
    }

    function balanceOfToken(address asset) private view returns (uint256) {
        if (asset == ETHToken.NATIVE_TOKEN) {
            return address(this).balance;
        } else {
            return IERC20Upgradeable(asset).balanceOf(address(this));
        }
    }

    function swap(
        uint8 _method,
        bytes calldata _encodedCallArgs,
        IETHExchangeAdapter.SwapDescription calldata _sd
    ) external payable override returns (uint256) {
//        console.log(
//            "[TestAdapter] swap:_sd.srcToken:%s, balanceOf:%s",
//            _sd.srcToken,
//            balanceOfToken(_sd.srcToken)
//        );
//        console.log(
//            "[TestAdapter] swap:_sd.dstToken:%s, balanceOf:%s",
//            _sd.dstToken,
//            balanceOfToken(_sd.dstToken)
//        );
        uint256 amount = IPriceOracle(valueInterpreter).valueInTargetToken(
            _sd.srcToken,
            _sd.amount,
            _sd.dstToken
        );
        console.log("[TestAdapter] swap:_sd.amount=%s, amount=%s", _sd.amount, amount);
        // Mock exchange
        uint256 expectAmount = (amount * 1) / 1;
        if (_sd.dstToken == ETHToken.NATIVE_TOKEN) {
            payable(_sd.receiver).transfer(expectAmount);
        } else {
            IERC20Upgradeable(_sd.dstToken).safeTransfer(_sd.receiver, expectAmount);
        }
        return expectAmount;
    }

    receive() external payable {
    }
}
