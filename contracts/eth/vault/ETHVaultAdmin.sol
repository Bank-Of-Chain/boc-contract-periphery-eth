// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
/**
 * @title ETHi Vault Admin Contract
 * @notice The VaultAdmin contract makes configuration and admin calls on the vault.
 * @author Bank OF CHAIN Protocol Inc
 */

import "./ETHVaultStorage.sol";

contract ETHVaultAdmin is ETHVaultStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableIntMap for IterableIntMap.AddressToIntMap;

    receive() external payable {}

    fallback() external payable {}

    /// @notice Shutdown the vault when an emergency occurs, cannot mint/burn.
    function setEmergencyShutdown(bool _active) external isVaultManager {
        emergencyShutdown = _active;
        emit SetEmergencyShutdown(_active);
    }

    /// @notice set adjustPositionPeriod true when adjust position occurs, cannot remove add asset/strategy and cannot mint/burn.
    function setAdjustPositionPeriod(bool _adjustPositionPeriod) external isKeeper {
        adjustPositionPeriod = _adjustPositionPeriod;
        emit SetAdjustPositionPeriod(_adjustPositionPeriod);
    }

    /**
     * @dev Set a minimum difference ratio automatically rebase.
     * rebase
     * @param _threshold _threshold is the numerator and the denominator is 10000000 (x/10000000).
     */
    function setRebaseThreshold(uint256 _threshold) external isVaultManager {
        rebaseThreshold = _threshold;
        emit RebaseThresholdUpdated(_threshold);
    }

    /**
     * @dev Set a fee in basis points to be charged for a redeem.
     * @param _redeemFeeBps Basis point fee to be charged
     */
    function setRedeemFeeBps(uint256 _redeemFeeBps) external isVaultManager {
        require(_redeemFeeBps <= 1000, "Redeem fee should not be over 10%");
        redeemFeeBps = _redeemFeeBps;
        emit RedeemFeeUpdated(_redeemFeeBps);
    }

    /**
     * @dev Set the Maximum timestamp between two reported
     */
    function setMaxTimestampBetweenTwoReported(uint256 _maxTimestampBetweenTwoReported)
        external
        isVaultManager
    {
        maxTimestampBetweenTwoReported = _maxTimestampBetweenTwoReported;
        emit MaxTimestampBetweenTwoReportedChanged(_maxTimestampBetweenTwoReported);
    }

    /**
     * @dev Set the minimum strategy total debt that will be checked for the strategy reporting
     */
    function setMinCheckedStrategyTotalDebt(uint256 _minCheckedStrategyTotalDebt)
    external
    isVaultManager
    {
        minCheckedStrategyTotalDebt = _minCheckedStrategyTotalDebt;
        emit MinCheckedStrategyTotalDebtChanged(_minCheckedStrategyTotalDebt);
    }

    /**
     * @dev Sets Minimum Investment Amount
     */
    function setMinimumInvestmentAmount(uint256 _minimumInvestmentAmount) external isVaultManager {
        minimumInvestmentAmount = _minimumInvestmentAmount;
        emit MinimumInvestmentAmountChanged(_minimumInvestmentAmount);
    }

    /**
     * @dev Sets the treasuryAddress that can receive a portion of yield.
     *      Setting to the zero address disables this feature.
     */
    function setTreasuryAddress(address _address) external onlyRole(BocRoles.GOV_ROLE) {
        treasury = _address;
        emit TreasuryAddressChanged(_address);
    }

    /**
     * @dev Sets the exchangeManagerAddress that can receive a portion of yield.
     */
    function setExchangeManagerAddress(address _exchangeManagerAddress)
        external
        onlyRole(BocRoles.GOV_ROLE)
    {
        require(_exchangeManagerAddress != address(0), "exchangeManager ad is 0");
        exchangeManager = _exchangeManagerAddress;
        emit ExchangeManagerAddressChanged(_exchangeManagerAddress);
    }

    function setVaultBufferAddress(address _address) external onlyRole(BocRoles.GOV_ROLE) {
        require(_address != address(0), "vaultBuffer ad is 0");
        vaultBufferAddress = _address;
    }

    function setPegTokenAddress(address _address) external onlyRole(BocRoles.GOV_ROLE) {
        require(_address != address(0), "PegTokenAddress ad is 0");
        pegTokenAddress = _address;
    }

    /**
     * @dev Sets the TrusteeFeeBps to the percentage of yield that should be
     *      received in basis points.
     */
    function setTrusteeFeeBps(uint256 _basis) external isVaultManager {
        require(_basis <= 5000, "basis cannot exceed 50%");
        trusteeFeeBps = _basis;
        emit TrusteeFeeBpsChanged(_basis);
    }

    function setStrategyEnforceChangeLimit(address _strategy, bool _enabled)
        external
        isVaultManager
    {
        strategies[_strategy].enforceChangeLimit = _enabled;
    }

    function setStrategySetLimitRatio(
        address _strategy,
        uint256 _lossRatioLimit,
        uint256 _profitLimitRatio
    ) external isVaultManager {
        strategies[_strategy].lossLimitRatio = _lossRatioLimit;
        strategies[_strategy].profitLimitRatio = _profitLimitRatio;
    }

    /**
     * @dev Set the deposit paused flag to true to prevent rebasing.
     */
    function pauseRebase() external isVaultManager {
        rebasePaused = true;
        emit RebasePaused();
    }

    /**
     * @dev Set the deposit paused flag to true to allow rebasing.
     */
    function unpauseRebase() external isVaultManager {
        rebasePaused = false;
        emit RebaseUnpaused();
    }

    /// @notice Added support for specific asset.
    function addAsset(address _asset) external isVaultManager {
        require(!assetSet.contains(_asset), "existed");
        assetSet.add(_asset);
        // Verify that our oracle supports the asset
        // slither-disable-next-line unused-return
        IPriceOracleConsumer(priceProvider).priceInUSD(_asset);
        trackedAssetsMap.plus(_asset, 1);
        emit AddAsset(_asset);
    }

    /// @notice Remove support for specific asset.
    function removeAsset(address _asset) external isVaultManager {
        if (_asset == NativeToken.NATIVE_TOKEN) {
            require(address(vaultBufferAddress).balance == 0, "vaultBuffer exist this asset");
        } else {
            require(
                IERC20Upgradeable(_asset).balanceOf(vaultBufferAddress) == 0,
                "vaultBuffer exit this asset"
            );
        }
        require(assetSet.contains(_asset), "not exist");
        assetSet.remove(_asset);
        trackedAssetsMap.minus(_asset, 1);
        if (trackedAssetsMap.get(_asset) <= 0) {
            uint256 _balance;
            if (_asset == NativeToken.NATIVE_TOKEN) {
                _balance = address(this).balance;
            } else {
                _balance = IERC20Upgradeable(_asset).balanceOf(address(this));
            }
            if (_balance == 0) {
                trackedAssetsMap.remove(_asset);
            }
        }
        emit RemoveAsset(_asset);
    }

    /// @notice Add strategy to strategy list
    /// @dev The strategy added to the strategy list,
    ///      Vault may invest funds into the strategy,
    ///      and the strategy will invest the funds in the 3rd protocol
    function addStrategy(StrategyAdd[] memory strategyAdds) external isVaultManager {
        address[] memory _strategies = new address[](strategyAdds.length);
        for (uint256 i = 0; i < strategyAdds.length; i++) {
            StrategyAdd memory _strategyAdd = strategyAdds[i];
            address _strategy = _strategyAdd.strategy;
            require(
                (_strategy != ZERO_ADDRESS) &&
                    (!strategySet.contains(_strategy)) &&
                    (IETHStrategy(_strategy).vault() == address(this)),
                "Strategy is invalid"
            );
            _strategies[i] = _strategy;
            _addStrategy(_strategy, _strategyAdd.profitLimitRatio, _strategyAdd.lossLimitRatio);
            address[] memory _wants = IETHStrategy(_strategy).getWants();
            for (uint256 j = 0; j < _wants.length; j++) {
                trackedAssetsMap.plus(_wants[j], 1);
            }
        }

        emit AddStrategies(_strategies);
    }

    /**
     * add strategy
     **/
    function _addStrategy(
        address strategy,
        uint256 _profitLimitRatio,
        uint256 _lossLimitRatio
    ) internal {
        //Add strategy to approved strategies
        strategies[strategy] = StrategyParams({
            lastReport: block.timestamp,
            totalDebt: 0,
            profitLimitRatio: _profitLimitRatio,
            lossLimitRatio: _lossLimitRatio,
            enforceChangeLimit: true
        });
        strategySet.add(strategy);
    }

    /// @notice Remove strategy from strategy list
    /// @dev The removed policy withdraws funds from the 3rd protocol and returns to the Vault
    function removeStrategy(address[] memory _strategies) external isVaultManager {
        for (uint256 i = 0; i < _strategies.length; i++) {
            require(strategySet.contains(_strategies[i]), "Strategy not exist");
            _removeStrategy(_strategies[i], false);
        }
        emit RemoveStrategies(_strategies);
    }

    function forceRemoveStrategy(address _strategy) external onlyGovOrDelegate {
        _removeStrategy(_strategy, true);
        emit RemoveStrategyByForce(_strategy);
    }

    /**
     * @dev Remove a strategy from the Vault.
     * @param _addr Address of the strategy to remove
     */
    function _removeStrategy(address _addr, bool _force) internal {
        if (strategies[_addr].totalDebt > 0) {
            // Withdraw all assets
            try IETHStrategy(_addr).repay(MAX_BPS, MAX_BPS, 0) {} catch {
                if (!_force) {
                    revert();
                }
            }
        }

        address[] memory _wants = IETHStrategy(_addr).getWants();
        for (uint256 i = 0; i < _wants.length; i++) {
            address _wantToken = _wants[i];
            trackedAssetsMap.minus(_wantToken, 1);
            if (trackedAssetsMap.get(_wantToken) <= 0) {
                uint256 _balance;
                if (_wantToken == NativeToken.NATIVE_TOKEN) {
                    _balance = address(this).balance;
                } else {
                    _balance = IERC20Upgradeable(_wantToken).balanceOf(address(this));
                }
                if (_balance == 0) {
                    trackedAssetsMap.remove(_wantToken);
                }
            }
        }
        if (strategies[_addr].totalDebt > 0) {
            totalDebt -= strategies[_addr].totalDebt;
        }
        delete strategies[_addr];
        strategySet.remove(_addr);
        _removeStrategyFromQueue(_addr);
    }

    /***************************************
                     WithdrawalQueue
     ****************************************/
    function getWithdrawalQueue() external view returns (address[] memory) {
        return withdrawQueue;
    }

    //advance queue
    function setWithdrawalQueue(address[] memory _queues) external isKeeper {
        for (uint256 i = 0; i < _queues.length; i++) {
            address _strategy = _queues[i];
            require(strategySet.contains(_strategy), "strategy not exist");
            if (i < withdrawQueue.length) {
                withdrawQueue[i] = _strategy;
            } else {
                withdrawQueue.push(_strategy);
            }
        }
        for (uint256 i = _queues.length; i < withdrawQueue.length; i++) {
            if (withdrawQueue[i] == ZERO_ADDRESS) break;
            withdrawQueue[i] = ZERO_ADDRESS;
        }
        emit SetWithdrawalQueue(_queues);
    }

    function removeStrategyFromQueue(address[] memory _strategies) external isKeeper {
        for (uint256 i = 0; i < _strategies.length; i++) {
            _removeStrategyFromQueue(_strategies[i]);
        }
        emit RemoveStrategyFromQueue(_strategies);
    }

    function _removeStrategyFromQueue(address _strategy) internal {
        for (uint256 i = 0; i < withdrawQueue.length; i++) {
            address _curStrategy = withdrawQueue[i];
            if (_curStrategy == ZERO_ADDRESS) break;
            if (_curStrategy == _strategy) {
                withdrawQueue[i] = ZERO_ADDRESS;
                _organizeWithdrawalQueue();

                return;
            }
        }
    }

    function _organizeWithdrawalQueue() internal {
        uint256 _offset = 0;
        for (uint256 i = 0; i < withdrawQueue.length; i++) {
            address _strategy = withdrawQueue[i];
            if (_strategy == ZERO_ADDRESS) {
                _offset += 1;
            } else if (_offset > 0) {
                withdrawQueue[i - _offset] = _strategy;
                withdrawQueue[i] = ZERO_ADDRESS;
            }
        }
    }
}
