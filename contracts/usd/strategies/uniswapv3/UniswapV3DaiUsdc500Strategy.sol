// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UniswapV3BaseStrategy.sol';

contract UniswapV3DaiUsdc500Strategy is UniswapV3BaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            // https://info.uniswap.org/#/pools/0x6c6bc977e13df9b0de53b251522280bb72383700
            address(0x6c6Bc977E13Df9b0de53b251522280BB72383700),
            10,
            10,
            41400,
            0,
            100,
            60
        );
    }

    function name() public pure override returns (string memory) {
        return 'UniswapV3DaiUsdc500Strategy';
    }

    function getTickSpacing() override internal pure returns (int24){
        return 10;
    }
}
