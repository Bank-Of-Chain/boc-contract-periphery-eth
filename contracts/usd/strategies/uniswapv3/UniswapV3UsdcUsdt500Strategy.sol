// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UniswapV3BaseStrategy.sol';

contract UniswapV3UsdcUsdt500Strategy is UniswapV3BaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            // https://info.uniswap.org/#/pools/0x7858e59e0c01ea06df3af3d20ac7b0003275d4bf
            address(0x7858E59e0C01EA06Df3aF3D20aC7B0003275D4Bf),
            10,
            10,
            41400,
            0,
            100,
            60
        );
    }

    function name() public pure override returns (string memory) {
        return 'UniswapV3UsdcUsdt500Strategy';
    }

    function getTickSpacing() override internal pure returns (int24){
        return 10;
    }
}
