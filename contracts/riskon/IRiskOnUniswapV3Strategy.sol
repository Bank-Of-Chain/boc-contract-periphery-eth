// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRiskOnUniswapV3Strategy {

    /// @notice Get token0 address of uniswap V3 pool invested by this vault
    function token0() external view returns (address);

    /// @notice Get token1 address of uniswap V3 pool invested by this vault
    function token1() external view returns (address);

    /// @notice The fee of uniswap V3 `pool`
    function fee() external view returns (uint24);

    /// @notice Emergency shutdown
    function emergencyShutdown() external view returns (bool);

    /// @notice Version of strategy
    function getVersion() external pure returns (string memory);

    /// @notice Gets the statuses about uniswap V3
    function getStatus() external view returns (int24 _baseThreshold, int24 _limitThreshold, int24 _minTickMove, int24 _maxTwapDeviation, int24 _lastTick, uint256 _period, uint256 _lastTimestamp, uint32 _twapDuration);

    /// @notice Gets the info of LP V3 NFT minted
    function getMintInfo() external view returns (uint256 _baseTokenId, int24 _baseTickUpper, int24 _baseTickLower, uint256 _limitTokenId, int24 _limitTickUpper, int24 _limitTickLower);

    /// @notice Total assets
    function estimatedTotalAssets() external view returns (uint256 _totalAssets);

    /// @notice Allocate funds in Vault to strategies
    function deposit(uint256 _token0Amount, uint256 _token1Amount) external;

    /// @notice Withdraw the funds from specified strategy.
    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares) external returns (uint256 _amount0, uint256 _amount1);

    /// @notice Harvests the Strategy
    function harvest() external returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts);

    /// @notice Rebalance the position of this strategy
    function rebalanceByKeeper() external;

    /// @notice Force rebalance the position of this strategy
    function forceRebalance() external;

    /// @notice Check if rebalancing is possible
    function shouldRebalance(int24 _tick) external view returns (bool);

    /// @notice Shutdown the vault when an emergency occurs
    function setEmergencyShutdown(bool _active) external;

    /// @notice Sets the profitFeeBps to the percentage of yield that should be received in basis points
    function setProfitFeeBps(uint256 _basis) external;

    /// @notice Sets `baseThreshold` state variable
    /// Requirements: only vault manager  can call
    function setBaseThreshold(int24 _baseThreshold) external;

    /// @notice Sets `limitThreshold` state variable
    /// Requirements: only vault manager  can call
    function setLimitThreshold(int24 _limitThreshold) external;

    /// @notice Sets `period` state variable
    /// Requirements: only vault manager  can call
    function setPeriod(uint256 _period) external;

    /// @notice Sets `minTickMove` state variable
    /// Requirements: only vault manager  can call
    function setMinTickMove(int24 _minTickMove) external;

    /// @notice Sets `maxTwapDeviation` state variable
    /// Requirements: only vault manager  can call
    function setMaxTwapDeviation(int24 _maxTwapDeviation) external;

    /// @notice Sets `twapDuration` state variable
    function setTwapDuration(uint32 _twapDuration) external;
}
