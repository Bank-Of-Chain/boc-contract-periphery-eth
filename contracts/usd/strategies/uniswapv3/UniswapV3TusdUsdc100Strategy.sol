// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UniswapV3BaseStrategy.sol';

contract UniswapV3TusdUsdc100Strategy is UniswapV3BaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            // https://info.uniswap.org/#/pools/0x39529e96c28807655b5856b3d342c6225111770e
            address(0x39529E96c28807655B5856b3d342c6225111770e),
            10,
            2,
            41400,
            0,
            100,
            60
        );
    }

    function name() public pure override returns (string memory) {
        return 'UniswapV3TusdUsdc100Strategy';
    }

    function getTickSpacing() override internal pure returns (int24){
        return 1;
    }
}
