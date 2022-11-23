// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEulerEToken {

    /// @notice Address of underlying asset
    function underlyingAsset() external view returns (address);

    /// @notice Given an underlying, lookup the associated DToken
    /// @param underlying Token address
    /// @return DToken address, or address(0) if not activated
    function underlyingToDToken(address underlying) external view returns (address);

    /// @notice Sum of all balances, in internal book-keeping units (non-increasing)
    function totalSupply() external view returns (uint);

    /// @notice Sum of all balances, in underlying units (increases as interest is earned)
    function totalSupplyUnderlying() external view returns (uint);

    /// @notice Balance of a particular account, in internal book-keeping units (non-increasing)
    function balanceOf(address account) external view returns (uint);

    //// @notice Balance of a particular account, in underlying units (increases as interest is earned)
    function balanceOfUnderlying(address account) external view returns (uint);

    /// @notice Balance of the reserves, in internal book-keeping units (non-increasing)
    function reserveBalance() external view returns (uint);

    /// @notice Balance of the reserves, in underlying units (increases as interest is earned)
    function reserveBalanceUnderlying() external view returns (uint);

    /// @notice Convert an eToken balance to an underlying amount, taking into account current exchange rate
    /// @param balance eToken balance, in internal book-keeping units (18 decimals)
    /// @return Amount in underlying units, (same decimals as underlying token)
    function convertBalanceToUnderlying(uint balance) external view returns (uint);

    /// @notice Convert an underlying amount to an eToken balance, taking into account current exchange rate
    /// @param underlyingAmount Amount in underlying units (same decimals as underlying token)
    /// @return eToken balance, in internal book-keeping units (18 decimals)
    function convertUnderlyingToBalance(uint underlyingAmount) external view returns (uint);

    /// @notice Updates interest accumulator and totalBorrows, credits reserves, re-targets interest rate, and logs asset status
    function touch() external;

    /// @notice Transfer underlying tokens from sender to the Euler pool, and increase account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full underlying token balance)
    function deposit(uint subAccountId, uint amount) external;

    /// @notice Transfer underlying tokens from Euler pool to sender, and decrease account's eTokens
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 for full pool balance)
    function withdraw(uint subAccountId, uint amount) external;

    /// @notice Mint eTokens and a corresponding amount of dTokens ("self-borrow")
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units
    function mint(uint subAccountId, uint amount) external;

    /// @notice Pay off dToken liability with eTokens ("self-repay")
    /// @param subAccountId 0 for primary, 1-255 for a sub-account
    /// @param amount In underlying units (use max uint256 to repay the debt in full or up to the available underlying balance)
    function burn(uint subAccountId, uint amount) external;
}
