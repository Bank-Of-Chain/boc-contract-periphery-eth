// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "boc-contract-core/contracts/exchanges/IExchangeAggregator.sol";

interface IETHVault {
    struct StrategyParams {
        //last report timestamp
        uint256 lastReport;
        //total asset
        uint256 totalDebt;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
        bool enforceChangeLimit;
    }

    struct StrategyAdd {
        address strategy;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
    }

    event AddAsset(address _asset);
    event RemoveAsset(address _asset);
    event AddStrategies(address[] _strategies);
    event RemoveStrategies(address[] _strategies);
    event RemoveStrategyByForce(address _strategy);
    event Mint(address _account, address _asset, uint256 _amount, uint256 _mintAmount);
    event Burn(
        address _account,
        address _asset,
        uint256 _amount,
        uint256 _actualAmount,
        uint256 _shareAmount,
        address[] _assets,
        uint256[] _amounts
    );
    event Exchange(
        address _platform,
        address _srcAsset,
        uint256 _srcAmount,
        address _distAsset,
        uint256 _distAmount
    );
    event Redeem(address _strategy, uint256 _debtChangeAmount, address[] _assets, uint256[] _amounts);
    event LendToStrategy(address indexed strategy, address[] wants, uint256[] amounts, uint256 lendValue);
    event RemoveStrategyFromQueue(address[] _strategies);
    event SetEmergencyShutdown(bool _shutdown);
    event RebasePaused();
    event RebaseUnpaused();
    event RebaseThresholdUpdated(uint256 _threshold);
    event TrusteeFeeBpsChanged(uint256 _basis);
    event MinimumInvestmentAmountChanged(uint256 _minimumInvestmentAmount);
    event TreasuryAddressChanged(address _address);
    event ExchangeManagerAddressChanged(address _address);
    event SetAdjustPositionPeriod(bool _adjustPositionPeriod);
    event RedeemFeeUpdated(uint256 _redeemFeeBps);
    event SetWithdrawalQueue(address[] queues);
    event Rebase(uint256 _totalShares, uint256 _totalValue, uint256 _newUnderlyingUnitsPerShare);
    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 lastStrategyTotalDebt,
        uint256 nowStrategyTotalDebt,
        uint256 _type
    );

    event StartAdjustPosition(
        uint256 _totalDebtOfBeforeAdjustPosition,
        address[] _trackedAssets,
        uint256[] _vaultCashDetatil,
        uint256[] _vaultBufferCashDetail
    );
    event EndAdjustPosition(
        uint256 _transferValue,
        uint256 _redeemValue,
        uint256 _totalDebt,
        uint256 _totalValueOfAfterAdjustPosition,
        uint256 _totalValueOfBeforeAdjustPosition
    );
    event PegTokenSwapCash(uint256 _pegTokenAmount, address[] _assets, uint256[] _amounts);

    /// @notice Version of vault
    function getVersion() external pure returns (string memory);

    /// @notice Minting USDi supported assets
    function getSupportAssets() external view returns (address[] memory assets);

    function checkIsSupportAsset(address asset) external view;

    /// @notice Assets held by Vault
    function getTrackedAssets() external view returns (address[] memory assets);

    /// @notice Vault holds asset value directly in ETH (1e18)
    function valueOfTrackedTokens() external view returns (uint256 _totalValue);

    /// @notice Vault and vault buffer holds asset value directly in ETH(1e18)
    function valueOfTrackedTokensIncludeVaultBuffer() external view returns (uint256 _totalValue);

    /// @notice Vault total asset in ETH
    function totalAssets() external view returns (uint256);

    /// @notice Vault and vault buffer total asset in ETH(1e18)
    function totalAssetsIncludeVaultBuffer() external view returns (uint256);

    /// @notice Vault total value(by chainlink price) in USD(1e18)
    function totalValue() external view returns (uint256);

    /// @notice start  Adjust  Position
    function startAdjustPosition() external;

    /// @notice end  Adjust Position
    function endAdjustPosition() external;

    function underlyingUnitsPerShare() external view returns (uint256);

    /**
     * @dev Internal to calculate total value of all assets held in Vault.
     * @return _value Total value(by chainlink price) in USD (1e18)
     */
    function totalValueInVault() external view returns (uint256 _value);

    /**
     * @dev Internal to calculate total value of all assets held in Strategies.
     * @return _value Total value(by chainlink price) in USD (1e18)
     */
    function totalValueInStrategies() external view returns (uint256 _value);

    /// @notice All strategies
    function getStrategies() external view returns (address[] memory _strategies);

    function checkActiveStrategy(address strategy) external view;

    /// @notice estimate Minting ETHi
    /// @param _amount Amount of the asset being deposited
    /// @return _sharesAmount  wethi amount
    function estimateMint(address _asset, uint256 _amount) external view returns (uint256 _sharesAmount);

    /// @notice Minting ETHi with ETH
    /// @return _sharesAmount  wethi amount
    function mint(
        address _asset,
        uint256 _amount,
        uint256 _minimumAmount
    ) external payable returns (uint256 _sharesAmount);

    /// @notice burn USDi,return stablecoins
    /// @param _amount Amount of USDi to burn
    /// @param _asset one of StableCoin asset
    /// @param _minimumAmount Minimum stablecoin units to receive in return
    function burn(
        uint256 _amount,
        address _asset,
        uint256 _minimumAmount,
        bool _needExchange,
        IExchangeAggregator.ExchangeToken[] memory _exchangeTokens
    ) external returns (address[] memory _assets, uint256[] memory _amounts);

    /// @notice Change ETHi supply with Vault total assets.
    function rebase() external;

    /// @notice Allocate funds in Vault to strategies.
    function lend(address _strategy, IExchangeAggregator.ExchangeToken[] calldata _exchangeTokens)
    external;

    /// @notice Withdraw the funds from specified strategy.
    function redeem(address _strategy, uint256 _amount, uint256 _outputCode) external;

    function exchange(
        address _fromToken,
        address _toToken,
        uint256 _amount,
        IExchangeAggregator.ExchangeParam memory exchangeParam
    ) external returns (uint256);

    function report(address[] memory _rewardTokens, uint256[] memory _claimAmounts) external;

    /// @notice Shutdown the vault when an emergency occurs, cannot mint/burn.
    function setEmergencyShutdown(bool active) external;

    /// @notice set adjustPositionPeriod true when adjust position occurs, cannot remove add asset/strategy and cannot mint/burn.
    function setAdjustPositionPeriod(bool _adjustPositionPeriod) external;

    /**
     * @dev Set a minimum difference ratio automatically rebase.
     * rebase
     * @param _threshold _threshold is the numerator and the denominator is 10000000 (x/10000000).
     */
    function setRebaseThreshold(uint256 _threshold) external;

    /**
     * @dev Set a fee in basis points to be charged for a redeem.
     * @param _redeemFeeBps Basis point fee to be charged
     */
    function setRedeemFeeBps(uint256 _redeemFeeBps) external;

    /**
     * @dev Sets the treasuryAddress that can receive a portion of yield.
     *      Setting to the zero address disables this feature.
     */
    function setTreasuryAddress(address _address) external;

    /**
    * @dev Sets the exchangeManagerAddress that can receive a portion of yield.
     */
    function setExchangeManagerAddress(address _exchangeManagerAddress) external;

    //    /**
    //     * @dev Set the EHTi address after initialization(only once)
    //     */
    //    function setETHiAddress(address _address) external;

    /**
     * @dev Sets the TrusteeFeeBps to the percentage of yield that should be
     *      received in basis points.
     */
    function setTrusteeFeeBps(uint256 _basis) external;

    //advance queue
    function setWithdrawalQueue(address[] memory queues) external;

    function setStrategyEnforceChangeLimit(address _strategy, bool _enabled) external;

    function setStrategySetLimitRatio(
        address _strategy,
        uint256 _lossRatioLimit,
        uint256 _profitLimitRatio
    ) external;

    /**
     * @dev Set the deposit paused flag to true to prevent rebasing.
     */
    function pauseRebase() external;

    /**
     * @dev Set the deposit paused flag to true to allow rebasing.
     */
    function unpauseRebase() external;

    /// @notice Added support for specific asset.
    function addAsset(address _asset) external;

    /// @notice Remove support for specific asset.
    function removeAsset(address _asset) external;

    /// @notice Add strategy to strategy list
    /// @dev The strategy added to the strategy list,
    ///      Vault may invest funds into the strategy,
    ///      and the strategy will invest the funds in the 3rd protocol
    function addStrategy(StrategyAdd[] memory strategyAdds) external;

    /// @notice Remove strategy from strategy list
    /// @dev The removed policy withdraws funds from the 3rd protocol and returns to the Vault
    function removeStrategy(address[] memory _strategies) external;

    function forceRemoveStrategy(address _strategy) external;

    /***************************************
                     WithdrawalQueue
     ****************************************/
    function getWithdrawalQueue() external view returns (address[] memory);

    function removeStrategyFromQueue(address[] memory _strategies) external;

    //adjust Position Period
    function adjustPositionPeriod() external view returns (bool);

    // emergency shutdown
    function emergencyShutdown() external view returns (bool);

    // Pausing bools
    function rebasePaused() external view returns (bool);

    // over this difference ratio automatically rebase. rebaseThreshold is the numerator and the denominator is 10000000 x/10000000.
    function rebaseThreshold() external view returns (uint256);

    // Amount of yield collected in basis points
    function trusteeFeeBps() external view returns (uint256);

    // Redemption fee in basis points
    function redeemFeeBps() external view returns (uint256);

    //all strategy asset
    function totalDebt() external view returns (uint256);

    //exchangeManager
    function exchangeManager() external view returns (address);

    // strategy info
    function strategies(address _strategy) external view returns (StrategyParams memory);

    //withdraw strategy set
    function withdrawQueue() external view returns (address[] memory);

    /// @notice Address of treasury
    function treasury() external view returns (address);

    /// @notice Address of price oracle
    function priceProvider() external view returns (address);

    function accessControlProxy() external view returns (address);

    /**
     * @dev Sets the Maximum timestamp between two reported
     */
    function setMaxTimestampBetweenTwoReported(uint256 _maxTimestampBetweenTwoReported) external;

    // Maximum timestamp between two reported
    function maxTimestampBetweenTwoReported() external view returns (uint256);

    // Minimum investment amount
    function setMinimumInvestmentAmount(uint256 _minimumInvestmentAmount) external;

    // Minimum investment amount
    function minimumInvestmentAmount() external view returns (uint256);

    function setVaultBufferAddress(address _address) external;

    function setUnderlyingUnitsPerShare(uint256 _underlyingUnitsPerShare) external;

    function vaultBufferAddress() external view returns (address);

    function setPegTokenAddress(address _address) external;

    function pegTokenAddress() external view returns (address);

    function setAdminImpl(address newImpl) external;
}
