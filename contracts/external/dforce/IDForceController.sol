// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDForceController {
    struct Market {
        /*
         *  Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be in [0, 0.9], and stored as a mantissa.
         */
        uint256 collateralFactorMantissa;
        /*
         *  Multiplier representing the most one can borrow the asset.
         *  For instance, 0.5 to allow borrowing this asset 50% * collateral value * collateralFactor.
         *  When calculating equity, 0.5 with 100 borrow balance will produce 200 borrow value
         *  Must be between (0, 1], and stored as a mantissa.
         */
        uint256 borrowFactorMantissa;
        /*
         *  The borrow capacity of the asset, will be checked in beforeBorrow()
         *  -1 means there is no limit on the capacity
         *  0 means the asset can not be borrowed any more
         */
        uint256 borrowCapacity;
        /*
         *  The supply capacity of the asset, will be checked in beforeMint()
         *  -1 means there is no limit on the capacity
         *  0 means the asset can not be supplied any more
         */
        uint256 supplyCapacity;
        // Whether market's mint is paused
        bool mintPaused;
        // Whether market's redeem is paused
        bool redeemPaused;
        // Whether market's borrow is paused
        bool borrowPaused;
    }

    /**
     * @notice Calculates current account equity
     * @param _account The account to query equity of
     * @return account equity, shortfall, collateral value, borrowed value.
     */
    function calcAccountEquity(address _account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Add markets to `msg.sender`'s markets list for liquidity calculations
     * @param _iTokens The list of addresses of the iToken markets to be entered
     * @return _results Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] calldata _iTokens) external returns (bool[] memory _results);

    /// @notice Return teh corresponding market's info of the '_iTokens'
    function markets(address _iTokens) external view returns (Market memory);

    /// @notice Return the address of price oracle
    function priceOracle() external view returns (address);

    /// @notice Return the address of reward distributor
    function rewardDistributor() external view returns (address);

    /**
     * @notice Returns the markets list the account has entered
     * @param _account The address of the account to query
     * @return _accountCollaterals The markets list the account has entered
     */
    function getEnteredMarkets(address _account)
        external
        view
        returns (address[] memory _accountCollaterals);

    /**
     * @notice Returns whether the given account has entered the market
     * @param _account The address of the account to check
     * @param _iToken The iToken to check against
     * @return True if the account has entered the market, otherwise false.
     */
    function hasEnteredMarket(address _account, address _iToken) external view returns (bool);

    /**
     * @notice Returns the asset list the account has borrowed
     * @param _account The address of the account to query
     * @return _borrowedAssets The asset list the account has borrowed
     */
    function getBorrowedAssets(address _account)
        external
        view
        returns (address[] memory _borrowedAssets);

    /**
     * @notice Returns whether the given account has borrowed the given iToken
     * @param _account The address of the account to check
     * @param _iToken The iToken to check against
     * @return True if the account has borrowed the iToken, otherwise false.
     */
    function hasBorrowed(address _account, address _iToken) external view returns (bool);

    /**
     * @notice Return all of the iTokens
     * @return _alliTokens The list of iToken addresses
     */
    function getAlliTokens() external view returns (address[] memory _alliTokens);
}
