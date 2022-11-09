// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRiskOnVault {

    /// @notice Emergency shutdown
    function emergencyShutdown() external view returns (bool);

    /// @notice WantToken
    function wantToken() external view returns (address);

    /// @notice Net market making amount
    function netMarketMakingAmount() external view returns (uint256);

    /// @notice Version of strategy
    function getVersion() external pure returns (string memory);

    /// @notice Total assets
    function estimatedTotalAssets() external view returns (uint256 _totalAssets);

    /// @notice Allocate funds in Vault to strategies
    function lend(uint256 _amount) external;

    /// @notice Withdraw the funds from specified strategy.
    function redeem(uint256 _redeemShares, uint256 _totalShares) external returns (uint256 _redeemBalance);

    /// @notice Withdraw the funds from specified strategy.
    function redeemToVaultByKeeper(uint256 _redeemShares, uint256 _totalShares) external returns (uint256 _redeemBalance);

    /// @notice Borrow Rebalance.
    function borrowRebalance() external;

    /// @notice Shutdown the vault when an emergency occurs
    function setEmergencyShutdown(bool _active) external;

    /// @notice Sets the manageFeeBps to the percentage of deposit that should be received in basis points
    function setManageFeeBps(uint256 _basis) external;

    /// @notice Sets the token0MinLendAmount to lend.
    function setToken0MinLendAmount(uint256 _minLendAmount) external;

    /// @notice Sets the token1MinLendAmount to lend.
    function setToken1MinLendAmount(uint256 _minLendAmount) external;
}
