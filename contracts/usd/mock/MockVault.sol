// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/price-feeds/IValueInterpreter.sol";
import "boc-contract-core/contracts/strategy/IStrategy.sol";

/// @title MockVault
/// @notice The mock contract of Vault
/// @author Bank of Chain Protocol Inc
contract MockVault is AccessControlMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public valueInterpreter;
    // strategy info
    mapping(address => StrategyParams) public strategies;
    //all strategy asset
    uint256 public totalDebt;

    /// @param lastReport The last report timestamp
    /// @param totalDebt The total asset of this strategy
    /// @param profitLimitRatio The limited ratio of profit
    /// @param lossLimitRatio The limited ratio for loss
    /// @param enforceChangeLimit The switch of enforce change Limit
    struct StrategyParams {
        uint256 lastReport;
        uint256 totalDebt;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
        bool enforceChangeLimit;
        uint256 lastClaim;
    }

    /// @param _strategy The strategy for reporting
    /// @param _gain The gain in USD units for this report
    /// @param _loss The loss in USD units for this report
    /// @param _lastStrategyTotalDebt The total debt of `_strategy` for last report
    /// @param _nowStrategyTotalDebt The total debt of `_strategy` for this report
    /// @param _rewardTokens The reward token list
    /// @param _claimAmounts The amount list of `_rewardTokens`
    /// @param _type The type of lend operations
    event StrategyReported(
        address indexed _strategy,
        uint256 _gain,
        uint256 _loss,
        uint256 _lastStrategyTotalDebt,
        uint256 _nowStrategyTotalDebt,
        address[] _rewardTokens,
        uint256[] _claimAmounts,
        uint256 _type
    );

    constructor(address _accessControlProxy, address _valueInterpreter) {
        _initAccessControl(_accessControlProxy);
        valueInterpreter = _valueInterpreter;
    }

    /// @notice Mock function for burning
    /// @param _amount Amount of USDi to burn
    function burn(uint256 _amount, uint256 _minimumAmount, uint256 _redeemFeeBps, uint256 _trusteeFeeBps) external {}

    /// @notice Allocate funds in Vault to strategies.
    /// @param _strategy The specified strategy to lend
    /// @param _assets Address of the asset being lended
    /// @param _amounts Amount of the asset being lended
    function lend(
        address _strategy,
        address[] memory _assets,
        uint256[] memory _amounts
    ) external {
        for (uint8 i = 0; i < _assets.length; i++) {
            address _token = _assets[i];
            uint256 _amount = _amounts[i];
            IERC20Upgradeable _item = IERC20Upgradeable(_token);
            require(_item.balanceOf(address(this)) >= _amount, "Insufficient tokens");
            _item.safeTransfer(_strategy, _amount);
        }
        IStrategy(_strategy).borrow(_assets, _amounts);
    }

    /// @notice Withdraw the funds from specified strategy.
    /// @param _strategy The specified strategy to redeem
    /// @param _usdValue The amount to redeem in USD
    /// @param _outputCode The code of output
    function redeem(
        address _strategy,
        uint256 _usdValue,
        uint256 _outputCode
    ) external {
        uint256 _totalValue = strategies[_strategy].totalDebt;
        if (_usdValue > _totalValue) {
            _usdValue = _totalValue;
        }
        IStrategy(_strategy).repay(_usdValue, _totalValue, _outputCode);
    }

    /// @dev Report the current asset of strategy caller
    /// @param _rewardTokens The reward token list
    /// @param _claimAmounts The claim amount list
    /// Emits a {StrategyReported} event.
    function report(address[] memory _rewardTokens, uint256[] memory _claimAmounts) external {
        _report(msg.sender, _rewardTokens, _claimAmounts, 0, 0);
        emit StrategyReported(msg.sender, 0, 0, 0, 0, _rewardTokens, _claimAmounts, 0);
    }

    function _report(
        address _strategy,
        address[] memory _rewardTokens,
        uint256[] memory _claimAmounts,
        uint256 _lendValue,
        uint256 _type
    ) private {
        StrategyParams memory _strategyParam = strategies[_strategy];
        uint256 _lastStrategyTotalDebt = _strategyParam.totalDebt + _lendValue;
        uint256 _nowStrategyTotalDebt = IStrategy(_strategy).estimatedTotalAssets();
        uint256 _gain = 0;
        uint256 _loss = 0;

        if (_nowStrategyTotalDebt > _lastStrategyTotalDebt) {
            _gain = _nowStrategyTotalDebt - _lastStrategyTotalDebt;
        } else if (_nowStrategyTotalDebt < _lastStrategyTotalDebt) {
            _loss = _lastStrategyTotalDebt - _nowStrategyTotalDebt;
        }

        strategies[_strategy].totalDebt = _nowStrategyTotalDebt;
        totalDebt = totalDebt + _nowStrategyTotalDebt + _lendValue - _lastStrategyTotalDebt;

        strategies[_strategy].lastReport = block.timestamp;
        if (_type == 0) {
            strategies[_strategy].lastClaim = block.timestamp;
        }
        emit StrategyReported(
            _strategy,
            _gain,
            _loss,
            _lastStrategyTotalDebt,
            _nowStrategyTotalDebt,
            _rewardTokens,
            _claimAmounts,
            _type
        );
    }
}
