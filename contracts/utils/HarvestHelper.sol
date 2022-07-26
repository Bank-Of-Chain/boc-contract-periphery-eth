// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import '../eth/strategies/IETHStrategy.sol';

contract HarvestHelper is AccessControlMixin {

    constructor(address _accessControlProxy) public {
        _initAccessControl(_accessControlProxy);
    }

    function batchHarvest(address[] memory _strategyAddrs) external isKeeper returns (uint256[] memory _totalAssets) {
        _totalAssets = new uint256[](_strategyAddrs.length);
        for (uint256 i = 0; i < _strategyAddrs.length; i++) {
            IETHStrategy(_strategyAddrs[i]).harvest();
            _totalAssets[i] = IETHStrategy(_strategyAddrs[i]).estimatedTotalAssets();
        }
    }
}
