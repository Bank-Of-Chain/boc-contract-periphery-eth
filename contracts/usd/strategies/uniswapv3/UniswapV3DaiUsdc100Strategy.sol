// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UniswapV3BaseStrategy.sol';

contract UniswapV3DaiUsdc100Strategy is UniswapV3BaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            // https://info.uniswap.org/#/pools/0x5777d92f208679db4b9778590fa3cab3ac9e2168
            address(0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168),
            5,
            2,
            41400,
            0,
            100,
            60
        );
    }

    function name() public pure override returns (string memory) {
        return 'UniswapV3DaiUsdc100Strategy';
    }

    function getTickSpacing() override internal pure returns (int24){
        return 1;
    }
}
