// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
    uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;

    uint256 constant MAX_VALID_LTV = 65535;
    uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 constant MAX_VALID_DECIMALS = 255;
    uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;


    /**
     * @dev Gets the Loan to Value of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The loan to value
   **/
    function getLtv(uint256 _dataLocal) internal view returns (uint256) {
        return _dataLocal & ~LTV_MASK;
    }


    /**
     * @dev Gets the liquidation threshold of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The liquidation threshold
   **/
    function getLiquidationThreshold(uint _dataLocal)
    internal
    view
    returns (uint256)
    {
        return (_dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }


    /**
     * @dev Gets the liquidation bonus of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The liquidation bonus
   **/
    function getLiquidationBonus(uint256 _dataLocal)
    internal
    view
    returns (uint256)
    {
        return (_dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
    }


    /**
     * @dev Gets the decimals of the underlying asset of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The decimals of the asset
   **/
    function getDecimals(uint256 _dataLocal) internal view returns (uint256) {
        return (_dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }


    /**
     * @dev Gets the active state of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The active state
   **/
    function getActive(uint256 _dataLocal) internal view returns (bool) {
        return (_dataLocal & ~ACTIVE_MASK) != 0;
    }


    /**
     * @dev Gets the frozen state of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The frozen state
   **/
    function getFrozen(uint256 _dataLocal) internal view returns (bool) {
        return (_dataLocal & ~FROZEN_MASK) != 0;
    }


    /**
     * @dev Gets the borrowing state of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The borrowing state
   **/
    function getBorrowingEnabled(uint256 _dataLocal) internal view returns (bool) {
        return (_dataLocal & ~BORROWING_MASK) != 0;
    }


    /**
     * @dev Gets the stable rate borrowing state of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The stable rate borrowing state
   **/
    function getStableRateBorrowingEnabled(uint256 _dataLocal)
    internal
    view
    returns (bool)
    {
        return (_dataLocal & ~STABLE_BORROWING_MASK) != 0;
    }


    /**
     * @dev Gets the reserve factor of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The reserve factor
   **/
    function getReserveFactor(uint256 _dataLocal) internal view returns (uint256) {
        return (_dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
    }

    /**
     * @dev Gets the configuration flags of the reserve
   * @param _dataLocal The reserve configuration's data
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
    function getFlags(uint256 _dataLocal)
    internal
    view
    returns (
        bool,
        bool,
        bool,
        bool
    )
    {
        uint256 dataLocal = _dataLocal;

        return (
        (dataLocal & ~ACTIVE_MASK) != 0,
        (dataLocal & ~FROZEN_MASK) != 0,
        (dataLocal & ~BORROWING_MASK) != 0,
        (dataLocal & ~STABLE_BORROWING_MASK) != 0
        );
    }

    /**
     * @dev Gets the configuration paramters of the reserve
   * @param  _dataLocal self The reserve configuration's data
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
    function getParams(uint256 _dataLocal)
    internal
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        return (
        _dataLocal & ~LTV_MASK,
        (_dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
        (_dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
        (_dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
        (_dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @dev Gets the configuration paramters of the reserve from a memory object
   * @param _dataLocal The reserve configuration's data
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
    function getParamsMemory(uint256 _dataLocal)
    internal
    pure
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        return (
        _dataLocal & ~LTV_MASK,
        (_dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
        (_dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
        (_dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
        (_dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @dev Gets the configuration flags of the reserve from a memory object
   * @param _dataLocal The reserve configuration's data
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
    function getFlagsMemory(uint256 _dataLocal)
    internal
    pure
    returns (
        bool,
        bool,
        bool,
        bool
    )
    {
        return (
        (_dataLocal & ~ACTIVE_MASK) != 0,
        (_dataLocal & ~FROZEN_MASK) != 0,
        (_dataLocal & ~BORROWING_MASK) != 0,
        (_dataLocal & ~STABLE_BORROWING_MASK) != 0
        );
    }
}