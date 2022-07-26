// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UniswapV3BaseStrategy.sol';

contract UniswapV3DaiUsdt500Strategy is UniswapV3BaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            // https://info.uniswap.org/#/pools/0x6f48eca74b38d2936b02ab603ff4e36a6c0e3a77
            address(0x6f48ECa74B38d2936B02ab603FF4e36A6C0E3A77),
            10,
            10,
            41400,
            0,
            100,
            60
        );
    }

    function name() public pure override returns (string memory) {
        return 'UniswapV3DaiUsdt500Strategy';
    }

    function getTickSpacing() override internal pure returns (int24){
        return 10;
    }
}
