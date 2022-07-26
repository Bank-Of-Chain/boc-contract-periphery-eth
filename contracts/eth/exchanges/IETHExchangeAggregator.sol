// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IETHExchangeAdapter.sol";

interface IETHExchangeAggregator {
    struct ExchangeParam {
        address platform;
        uint8 method;
        bytes encodeExchangeArgs;
        uint256 slippage;
        uint256 oracleAdditionalSlippage;
    }

    struct ExchangeToken {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        ExchangeParam exchangeParam;
    }

    function swap(
        address platform,
        uint8 _method,
        bytes calldata _data,
        IETHExchangeAdapter.SwapDescription calldata _sd
    ) external payable returns (uint256);

    function getExchangeAdapters()
        external
        view
        returns (address[] memory exchangeAdapters_);
}
