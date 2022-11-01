// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "../oracle/IPriceOracleConsumer.sol";
import "../strategies/IETHStrategy.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";

/// @title MockETHVault
/// @notice The mock contract of ETHVault
/// @author Bank of Chain Protocol Inc
contract MockETHVault is AccessControlMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // strategy info
    mapping(address => StrategyParams) public strategies;
    //all strategy asset
    uint256 public totalDebt;
    address public priceProvider;

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
        priceProvider = _valueInterpreter;
    }

    receive() external payable {}

    fallback() external payable {}

    /// @notice Return the address of treasury
    function treasury() external view returns (address) {
        return address(this);
    }

    /// @notice Mock function for burning
    /// @param _amount Amount of ETHi to burn
    function burn(uint256 _amount) external {}

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
            if (_token == NativeToken.NATIVE_TOKEN) {
                payable(address(_strategy)).transfer(_amount);
            } else {
                IERC20Upgradeable _item = IERC20Upgradeable(_token);
                _item.safeTransfer(_strategy, _amount);
            }
        }
        IETHStrategy(_strategy).borrow(_assets, _amounts);
    }

    /// @notice Withdraw the funds from specified strategy.
    /// @param _strategy The specified strategy to redeem
    /// @param _ethValue The amount to redeem in ETH 
    /// @param _outputCode The code of output 
    function redeem(
        address _strategy,
        uint256 _ethValue,
        uint256 _outputCode
    ) external payable {
        uint256 _totalValue = strategies[_strategy].totalDebt;
        if (_ethValue > _totalValue) {
            _ethValue = _totalValue;
        }
        IETHStrategy(_strategy).repay(_ethValue, _totalValue, _outputCode);
    }

    /// @dev Report the current asset of strategy caller
    /// @param _rewardTokens The reward token list
    /// @param _claimAmounts The claim amount list
    /// Emits a {StrategyReported} event.
    function report(address[] memory _rewardTokens, uint256[] memory _claimAmounts) external {
        _report(msg.sender, _rewardTokens, _claimAmounts, 0);
        emit StrategyReported(msg.sender, 0, 0, 0, 0, _rewardTokens, _claimAmounts, 0);
    }

    function _report(
        address _strategy,
        address[] memory _rewardTokens,
        uint256[] memory _claimAmounts,
        uint256 _lendValue
    ) private {
        StrategyParams memory _strategyParam = strategies[_strategy];
        uint256 _lastStrategyTotalDebt = _strategyParam.totalDebt + _lendValue;
        uint256 _nowStrategyTotalDebt = IETHStrategy(_strategy).estimatedTotalAssets();
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
        uint256 _type = 0;
        if (_lendValue > 0) {
            _type = 1;
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
