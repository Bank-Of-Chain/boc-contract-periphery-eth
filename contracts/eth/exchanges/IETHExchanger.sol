// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import 'boc-contract-core/contracts/exchanges/IExchangeAdapter.sol';

interface IETHExchanger {
    function eth2stEth(address receiver) external payable returns (uint256 stEthAmount);

    function stEth2Eth(address receiver, uint256 stEthAmount) external returns (uint256 ethAmount);

    function eth2wstEth(address receiver) external payable returns (uint256 wstEthAmount);

    function wstEth2Eth(address receiver, uint256 wstEthAmount) external returns (uint256 ethAmount);

    function eth2rEth(address receiver) external payable returns (uint256 rstEthAmount);

    function rEth2Eth(address receiver, uint256 rEthAmount) external returns (uint256 ethAmount);

    function eth2wEth(address receiver) external payable returns (uint256 rstEthAmount);

    function wEth2Eth(address receiver, uint256 wEthAmount) external returns (uint256 ethAmount);

    function swap(
        address platform,
        uint8 _method,
        bytes calldata _data,
        IExchangeAdapter.SwapDescription calldata _sd
    ) external payable returns (uint256);
}
