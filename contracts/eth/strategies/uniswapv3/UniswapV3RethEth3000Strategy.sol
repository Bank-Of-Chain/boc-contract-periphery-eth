// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UniswapV3BaseStrategy.sol';

contract UniswapV3RethEth3000Strategy is UniswapV3BaseStrategy {
    function initialize(address _vault) public initializer {
        super._initialize(
            _vault,
            // https://info.uniswap.org/#/pools/0xf0e02cf61b31260fd5ae527d58be16312bda59b1
            address(0xf0E02Cf61b31260fd5AE527d58Be16312BDA59b1),
            60,
            60,
            41400,
            0,
            100,
            60
        );
    }

    function name() public pure override returns (string memory) {
        return 'UniswapV3RethEth3000Strategy';
    }

    function getTickSpacing() override internal pure returns (int24){
        return 60;
    }
}
