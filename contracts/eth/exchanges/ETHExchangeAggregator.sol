// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './IETHExchangeAggregator.sol';
import 'hardhat/console.sol';
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";

contract ETHExchangeAggregator is AccessControlMixin {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event ExchangeAdapterAdded(
        address[] exchangeAdapters
    );

    event ExchangeAdapterRemoved(
        address[] exchangeAdapters
    );

    EnumerableSet.AddressSet private exchangeAdapters;

    constructor(address[] memory _exchangeAdapters, address _accessControlProxy) {
        _initAccessControl(_accessControlProxy);
        __addExchangeAdapters(_exchangeAdapters);
    }

    function addExchangeAdapters(address[] calldata _exchangeAdapters) external onlyGovOrDelegate {
        __addExchangeAdapters(_exchangeAdapters);
    }

    function removeExchangeAdapters(address[] calldata _exchangeAdapters) external onlyGovOrDelegate {
        require(_exchangeAdapters.length > 0, '_exchangeAdapters cannot be empty');

        for (uint256 i = 0; i < _exchangeAdapters.length; i++) {
            exchangeAdapters.remove(_exchangeAdapters[i]);
        }
        emit ExchangeAdapterRemoved(_exchangeAdapters);
    }

    function __addExchangeAdapters(address[] memory _exchangeAdapters) private {
        for (uint256 i = 0; i < _exchangeAdapters.length; i++) {
            exchangeAdapters.add(_exchangeAdapters[i]);
        }
        emit ExchangeAdapterAdded(_exchangeAdapters);
    }

    // address platform：Called exchange platforms
    // uint8 _method：method of the exchange platform
    // bytes calldata _data ：binary parameters
    // IExchangeAdapter.SwapDescription calldata _sd
    function swap(address _platform, uint8 _method, bytes calldata _data, IETHExchangeAdapter.SwapDescription calldata _sd)
    external payable
    returns (uint256){
        require(exchangeAdapters.contains(_platform), 'error swap platform');
        if (_sd.srcToken == NATIVE_TOKEN) {
            payable(_platform).transfer(_sd.amount);
        }else{
            IERC20(_sd.srcToken).transferFrom(msg.sender, _platform, _sd.amount);
        }
        return IETHExchangeAdapter(_platform).swap(_method, _data, _sd);
    }

    function getExchangeAdapters()
    external
    view
    returns (address[] memory exchangeAdapters_, string[] memory identifiers_)
    {
        exchangeAdapters_ = new address[](exchangeAdapters.length());
        identifiers_ = new string[](exchangeAdapters_.length);
        for (uint256 i = 0; i < exchangeAdapters_.length; i++) {
            exchangeAdapters_[i] = exchangeAdapters.at(i);
            identifiers_[i] = IETHExchangeAdapter(exchangeAdapters_[i]).identifier();
        }
        return (exchangeAdapters_, identifiers_);
    }

    receive() external payable {
    }
}
