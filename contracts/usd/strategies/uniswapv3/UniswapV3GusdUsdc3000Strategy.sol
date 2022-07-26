// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UniswapV3BaseStrategy.sol';

contract UniswapV3GusdUsdc3000Strategy is UniswapV3BaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault, //165589
            _harvester,
            // https://info.uniswap.org/#/pools/0x93f267fd92b432bebf4da4e13b8615bb8eb2095c
            address(0x93f267fD92B432BeBf4dA4E13B8615Bb8Eb2095C),
            60,
            60,
            41400,
            0,
            100,
            60
        );
    }

    function name() public pure override returns (string memory) {
        return 'UniswapV3GusdUsdc3000Strategy';
    }

    function getTickSpacing() override internal pure returns (int24){
        return 60;
    }
}
