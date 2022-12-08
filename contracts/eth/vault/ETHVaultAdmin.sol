// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ETHVaultStorage.sol";

/// @title ETHi Vault Admin Contract
/// @notice The VaultAdmin contract makes configuration and admin calls on the vault.
/// @author Bank of Chain Protocol Inc
contract ETHVaultAdmin is ETHVaultStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableIntMap for IterableIntMap.AddressToIntMap;

    receive() external payable {}

    fallback() external payable {}

    /// @dev Shutdown the vault when an emergency occurs, cannot mint/burn.
    /// Requirements: only vault manager can call
    function setEmergencyShutdown(bool _active) external isVaultManager {
        emergencyShutdown = _active;
        emit SetEmergencyShutdown(_active);
    }

    /// @dev Sets adjustPositionPeriod true when adjust position occurs,
    ///   cannot remove add asset/strategy and cannot mint/burn.
    /// Requirements: only keeper can call
    function setAdjustPositionPeriod(bool _adjustPositionPeriod) external isKeeper {
        adjustPositionPeriod = _adjustPositionPeriod;
        emit SetAdjustPositionPeriod(_adjustPositionPeriod);
    }

    /// @dev Sets a minimum difference ratio automatically rebase.
    /// @param _threshold _threshold is the numerator and the denominator is 1e7. x/1e7
    /// Requirements: only vault manager can call
    function setRebaseThreshold(uint256 _threshold) external isVaultManager {
        rebaseThreshold = _threshold;
        emit RebaseThresholdUpdated(_threshold);
    }

    /// @dev Sets a fee in basis points to be charged for a redeem.
    /// @param _redeemFeeBps Basis point fee to be charged
    /// Requirements: only vault manager can call
    function setRedeemFeeBps(uint256 _redeemFeeBps) external isVaultManager {
        require(_redeemFeeBps <= 1000, "Redeem fee should not be over 10%");
        redeemFeeBps = _redeemFeeBps;
        emit RedeemFeeUpdated(_redeemFeeBps);
    }

    /// @dev Sets the Maximum timestamp between two reported
    /// Requirements: only vault manager can call
    function setMaxTimestampBetweenTwoReported(uint256 _maxTimestampBetweenTwoReported)
        external
        isVaultManager
    {
        maxTimestampBetweenTwoReported = _maxTimestampBetweenTwoReported;
        emit MaxTimestampBetweenTwoReportedChanged(_maxTimestampBetweenTwoReported);
    }

    /// @dev Sets the minimum strategy total debt that will be checked for the strategy reporting
    /// Requirements: only vault manager can call
    function setMinCheckedStrategyTotalDebt(uint256 _minCheckedStrategyTotalDebt)
        external
        isVaultManager
    {
        minCheckedStrategyTotalDebt = _minCheckedStrategyTotalDebt;
        emit MinCheckedStrategyTotalDebtChanged(_minCheckedStrategyTotalDebt);
    }

    /// @dev Sets Minimum Investment Amount
    /// Requirements: only vault manager can call
    function setMinimumInvestmentAmount(uint256 _minimumInvestmentAmount) external isVaultManager {
        minimumInvestmentAmount = _minimumInvestmentAmount;
        emit MinimumInvestmentAmountChanged(_minimumInvestmentAmount);
    }

    /// @dev Sets the treasuryAddress that can receive a portion of yield.
    ///      Setting to the zero address disables this feature.
    /// Requirements: only governance role can call
    function setTreasuryAddress(address _address) external onlyRole(BocRoles.GOV_ROLE) {
        treasury = _address;
        emit TreasuryAddressChanged(_address);
    }

    /// @dev Sets the exchangeManagerAddress that can receive a portion of yield.
    /// Requirements: only governance role can call
    function setExchangeManagerAddress(address _exchangeManagerAddress)
        external
        onlyRole(BocRoles.GOV_ROLE)
    {
        require(_exchangeManagerAddress != address(0), "exchangeManager ad is 0");
        exchangeManager = _exchangeManagerAddress;
        emit ExchangeManagerAddressChanged(_exchangeManagerAddress);
    }

    /// @dev Sets `_address` to `vaultBufferAddress`
    /// Requirements: only governance role can call
    function setVaultBufferAddress(address _address) external onlyRole(BocRoles.GOV_ROLE) {
        require(_address != address(0), "vaultBuffer ad is 0");
        vaultBufferAddress = _address;
    }

    /// @dev Sets `_address` to `pegTokenAddress`
    /// Requirements: only governance role can call
    function setPegTokenAddress(address _address) external onlyRole(BocRoles.GOV_ROLE) {
        require(_address != address(0), "PegTokenAddress ad is 0");
        pegTokenAddress = _address;
    }

    /// @dev Sets the TrusteeFeeBps to the percentage of yield that should be
    ///      received in basis points.
    /// Requirements: only vault manager can call
    function setTrusteeFeeBps(uint256 _basis) external isVaultManager {
        require(_basis <= 5000, "basis cannot exceed 50%");
        trusteeFeeBps = _basis;
        emit TrusteeFeeBpsChanged(_basis);
    }

    /// @dev Sets '_enabled' to the 'enforceChangeLimit' field of '_strategy'
    /// Requirements: only vault manager can call
    function setStrategyEnforceChangeLimit(address _strategy, bool _enabled)
        external
        isVaultManager
    {
        strategies[_strategy].enforceChangeLimit = _enabled;
    }

    /// @dev Sets '_lossRatioLimit' to the 'lossRatioLimit' field of '_strategy'
    ///      Sets '_profitLimitRatio' to the 'profitLimitRatio' field of '_strategy'
    /// Requirements: only vault manager can call
    function setStrategySetLimitRatio(
        address _strategy,
        uint256 _lossRatioLimit,
        uint256 _profitLimitRatio
    ) external isVaultManager {
        strategies[_strategy].lossLimitRatio = _lossRatioLimit;
        strategies[_strategy].profitLimitRatio = _profitLimitRatio;
    }

    /// @dev Sets the deposit paused flag to true to prevent rebasing.
    /// Requirements: only vault manager can call
    function pauseRebase() external isVaultManager {
        rebasePaused = true;
        emit RebasePaused();
    }

    /// @dev Sets the deposit paused flag to true to allow rebasing.
    /// Requirements: only vault manager can call
    function unpauseRebase() external isVaultManager {
        rebasePaused = false;
        emit RebaseUnpaused();
    }

    /// @dev Added support for specific asset.
    /// Requirements: only vault manager can call
    function addAsset(address _asset) external isVaultManager {
        require(!assetSet.contains(_asset), "existed");
        assetSet.add(_asset);
        // Verify that our oracle supports the asset
        // slither-disable-next-line unused-return
        IPriceOracleConsumer(priceProvider).priceInUSD(_asset);
        trackedAssetsMap.plus(_asset, 1);
        emit AddAsset(_asset);
    }

    /// @dev Remove support for specific asset.
    /// Requirements: only vault manager can call
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
    /// Requirements: only vault manager can call
    function addStrategies(StrategyAdd[] memory strategyAdds) external isVaultManager {
        address[] memory _strategies = new address[](strategyAdds.length);
        for (uint256 i = 0; i < strategyAdds.length; i++) {
            StrategyAdd memory _strategyAdd = strategyAdds[i];
            address _strategy = _strategyAdd.strategy;
            require(
                (_strategy != ZERO_ADDRESS) &&
                    (!strategySet.contains(_strategy)) &&
                    (address(IETHStrategy(_strategy).vault()) == address(this)),
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

    /// @notice Remove multi strategies from strategy list
    /// @dev The removed policy withdraws funds from the 3rd protocol and returns to the Vault
    /// @param _strategies The address list of strategies to remove
    /// Requirements: only vault manager can call
    function removeStrategies(address[] memory _strategies) external isVaultManager {
        for (uint256 i = 0; i < _strategies.length; i++) {
            require(strategySet.contains(_strategies[i]), "Strategy not exist");
            _removeStrategy(_strategies[i], false);
        }
        emit RemoveStrategies(_strategies);
    }

    /// @dev Forced to remove the '_strategy'
    /// Requirements: only governance or delegate role can call
    function forceRemoveStrategy(address _strategy) external onlyGovOrDelegate {
        _removeStrategy(_strategy, true);
        emit RemoveStrategyByForce(_strategy);
    }

    /// @notice Return the `withdrawQueue`
    function getWithdrawalQueue() external view returns (address[] memory) {
        return withdrawQueue;
    }

    /// @dev Sets `withdrawQueue` and add `_queues` to the front of the `withdrawQueue`
    /// @param _queues The advance queue
    /// Requirements: only keeper can call
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

    /// @dev Remove multi strategies from the withdrawal queue
    /// @param _strategies multi strategies to remove
    /// Requirements: only keeper can call
    function removeStrategyFromQueue(address[] memory _strategies) external isKeeper {
        for (uint256 i = 0; i < _strategies.length; i++) {
            _removeStrategyFromQueue(_strategies[i]);
        }
        emit RemoveStrategyFromQueue(_strategies);
    }

    // Internal function

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
            enforceChangeLimit: true,
            lastClaim: block.timestamp
        });
        strategySet.add(strategy);
    }

    /// @dev Remove a strategy from the Vault.
    /// @param _addr Address of the strategy to remove
    /// @param _force Forced to remove if 'true'
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
        uint256 _offset;
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
