// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ETHUniswapV3BaseStrategy.sol";

/// @title ETHUniswapV3Strategy
/// @author Bank of Chain Protocol Inc
contract ETHUniswapV3Strategy is ETHUniswapV3BaseStrategy {

    /// @notice Initialize this contract
    /// @param _vault The ETH vaults
    /// @param _name The name of strategy
    /// @param _pool The uniswap V3 pool
    /// @param _baseThreshold The new base threshold
    /// @param _limitThreshold The new limit threshold
    /// @param _period The new period
    /// @param _minTickMove The minium tick to move
    /// @param _maxTwapDeviation The max TWAP deviation
    /// @param _twapDuration The max TWAP duration 
    /// @param _tickSpacing The specified tickSpacing
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

}
