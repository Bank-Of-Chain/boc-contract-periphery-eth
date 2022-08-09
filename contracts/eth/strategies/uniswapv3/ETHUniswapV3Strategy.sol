// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ETHUniswapV3BaseStrategy.sol";

contract ETHUniswapV3Strategy is ETHUniswapV3BaseStrategy {
    function initialize(
        address _vault,
        string memory _name,
        address _pool,
        int24 _baseThreshold,
        int24 _limitThreshold,
        uint256 _period,
        int24 _minTickMove,
        int24 _maxTwapDeviation,
        uint32 _twapDuration,
        int24 _tickSpacing
    ) public initializer {
        super._initialize(
            _vault,
            _name,
            _pool,
            _baseThreshold,
            _limitThreshold,
            _period,
            _minTickMove,
            _maxTwapDeviation,
            _twapDuration,
            _tickSpacing
        );
    }

    // function name() public pure override returns (string memory) {
    //     return "UniswapV3RethEth3000Strategy";
    // }

    // function getTickSpacing() internal pure override returns (int24) {
    //     return 60;
    // }
}
