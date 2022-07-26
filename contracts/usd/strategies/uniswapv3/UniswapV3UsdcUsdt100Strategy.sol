// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UniswapV3BaseStrategy.sol';

contract UniswapV3UsdcUsdt100Strategy is UniswapV3BaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            // https://info.uniswap.org/#/pools/0x3416cf6c708da44db2624d63ea0aaef7113527c6
            address(0x3416cF6C708Da44DB2624D63ea0AAef7113527C6),
            10,
            2,
            41400,
            0,
            100,
            60
        );
    }

    function name() public pure override returns (string memory) {
        return 'UniswapV3UsdcUsdt100Strategy';
    }

    function getTickSpacing() override internal pure returns (int24){
        return 1;
    }
}
