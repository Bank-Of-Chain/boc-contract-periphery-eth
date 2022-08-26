// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "boc-contract-core/contracts/exchanges/IExchangeAdapter.sol";
import "../../eth/oracle/IPriceOracleConsumer.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract ETHTestAdapter is IExchangeAdapter {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address valueInterpreter;

    constructor(address _valueInterpreter) {
        valueInterpreter = _valueInterpreter;
    }

    receive() external payable {}
    fallback() external payable {}

    function identifier() external pure override returns (string memory) {
        return "testAdapter";
    }

    function swap(
        uint8 _method,
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) external payable override returns (uint256) {
        uint256 _amount = IPriceOracleConsumer(valueInterpreter).valueInTargetToken(
            _sd.srcToken,
            _sd.amount,
            _sd.dstToken
        );
        // Mock exchange
        uint256 _expectAmount = (_amount * 1000) / 1000;
        if (_sd.dstToken == NativeToken.NATIVE_TOKEN) {
            payable(_sd.receiver).transfer(_expectAmount);
        } else {
            IERC20Upgradeable(_sd.dstToken).safeTransfer(_sd.receiver, _expectAmount);
        }
        return _expectAmount;
    }
}