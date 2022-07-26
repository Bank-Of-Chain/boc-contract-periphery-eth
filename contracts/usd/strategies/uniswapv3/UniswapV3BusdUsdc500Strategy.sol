// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UniswapV3BaseStrategy.sol';

contract UniswapV3BusdUsdc500Strategy is UniswapV3BaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            // https://info.uniswap.org/#/pools/0x00cef0386ed94d738c8f8a74e8bfd0376926d24c
            address(0x00cEf0386Ed94d738c8f8A74E8BFd0376926d24C),
            10,
            10,
            41400,
            0,
            100,
            60
        );
    }

    function name() public pure override returns (string memory) {
        return 'UniswapV3BusdUsdc500Strategy';
    }

    function getTickSpacing() override internal pure returns (int24){
        return 10;
    }
}
