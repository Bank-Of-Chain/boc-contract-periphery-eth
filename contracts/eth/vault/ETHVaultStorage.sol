// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/library/IterableIntMap.sol";
import "boc-contract-core/contracts/library/StableMath.sol";
import "boc-contract-core/contracts/token/IPegToken.sol";
import "boc-contract-core/contracts/vault/IVaultBuffer.sol";
import "boc-contract-core/contracts/library/BocRoles.sol";
import "../strategies/IETHStrategy.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "boc-contract-core/contracts/exchanges/IExchangeAggregator.sol";
import "../oracle/IPriceOracleConsumer.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title ETHVaultStorage
/// @notice The VaultStorage contract defines The storage layout for the Vault contract
/// @author Bank of Chain Protocol Inc
contract ETHVaultStorage is Initializable, ReentrancyGuardUpgradeable, AccessControlMixin {
    using StableMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using IterableIntMap for IterableIntMap.AddressToIntMap;

    /// @param lastReport The last report timestamp
    /// @param totalDebt The total asset of this strategy
    /// @param profitLimitRatio The limited ratio of profit
    /// @param lossLimitRatio The limited ratio for loss
    /// @param enforceChangeLimit The switch of enforce change Limit
    /// @param lastClaim The last claim timestamp
    struct StrategyParams {
        uint256 lastReport;
        uint256 totalDebt;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
        bool enforceChangeLimit;
        uint256 lastClaim;
    }

    /// @param strategy The new strategy to add
    /// @param profitLimitRatio The limited ratio of profit
    /// @param lossLimitRatio The limited ratio for loss
    struct StrategyAdd {
        address strategy;
        uint256 profitLimitRatio;
        uint256 lossLimitRatio;
    }

    /// @param _asset The new asset to add
    event AddAsset(address _asset);

    /// @param _asset The new asset to remove
    event RemoveAsset(address _asset);

    /// @param _strategies The new list of strategy to add
    event AddStrategies(address[] _strategies);

    /// @param _strategies The list of strategy to remove
    event RemoveStrategies(address[] _strategies);

    /// @param _strategy The strategy to remove
    event RemoveStrategyByForce(address _strategy);

    /// @param _account The minter
    /// @param _asset The address of the asset depositing
    /// @param _amount The amount of the asset depositing
    /// @param _mintAmount The amount of the asset minting
    event Mint(address _account, address _asset, uint256 _amount, uint256 _mintAmount);

    /// @param _account The owner of token burning
    /// @param _amounts The amount of the USDi token burning
    /// @param _actualAmount The received amount actually
    /// @param _shareAmount The amount of the shares burning
    /// @param _assets The address list of assets to receive
    /// @param _amounts The amount list of assets to receive
    event Burn(
        address _account,
        uint256 _amount,
        uint256 _actualAmount,
        uint256 _shareAmount,
        address[] _assets,
        uint256[] _amounts
    );

    /// @param  _platform The platform used for the exchange
    /// @param _srcAsset The address of asset exchange from
    /// @param _srcAmount The amount of asset exchange from
    /// @param _distAsset The address of asset exchange to
    /// @param _distAmount The amount of asset exchange to
    event Exchange(
        address _platform,
        address _srcAsset,
        uint256 _srcAmount,
        address _distAsset,
        uint256 _distAmount
    );

    /// @param _strategy The specified strategy to redeem
    /// @param _debtChangeAmount The amount to redeem in ETH
    /// @param _assets The address list of asset redeeming
    /// @param _amounts The amount list of asset redeeming
    event Redeem(
        address _strategy,
        uint256 _debtChangeAmount,
        address[] _assets,
        uint256[] _amounts
    );

    /// @param _strategy The specified strategy to lend
    /// @param _wants The address list of token wanted
    /// @param _amounts The amount list of token wanted
    /// @param _lendValue The value to lend
    event LendToStrategy(
        address indexed _strategy,
        address[] _wants,
        uint256[] _amounts,
        uint256 _lendValue
    );

    /// @param _strategy The specified strategy repaying from
    /// @param _strategyWithdrawValue The value of `_strategy` to withdraw
    /// @param _strategyTotalValue The total value of `_strategy` in ETH
    /// @param _assets The address list of asset repaying from `_strategy`
    /// @param _amounts The amount list of asset repaying from `_strategy`
    event RepayFromStrategy(
        address indexed _strategy,
        uint256 _strategyWithdrawValue,
        uint256 _strategyTotalValue,
        address[] _assets,
        uint256[] _amounts
    );

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

    /// @param _strategies The strategy list to remove
    event RemoveStrategyFromQueue(address[] _strategies);

    /// @param _shutdown The new boolean value of the emergency shutdown switch
    event SetEmergencyShutdown(bool _shutdown);

    event RebasePaused();
    event RebaseUnpaused();

    /// @param _threshold is the numerator and the denominator is 1e7. x/1e7
    event RebaseThresholdUpdated(uint256 _threshold);

    /// @param _basis the new value of `trusteeFeeBps`
    event TrusteeFeeBpsChanged(uint256 _basis);

    /// @param _maxTimestampBetweenTwoReported the new value of `maxTimestampBetweenTwoReported`
    event MaxTimestampBetweenTwoReportedChanged(uint256 _maxTimestampBetweenTwoReported);

    /// @param _minCheckedStrategyTotalDebt the new value of `minCheckedStrategyTotalDebt`
    event MinCheckedStrategyTotalDebtChanged(uint256 _minCheckedStrategyTotalDebt);

    /// @param _minimumInvestmentAmount the new value of `minimumInvestmentAmount`
    event MinimumInvestmentAmountChanged(uint256 _minimumInvestmentAmount);

    /// @param _address the new treasury address
    event TreasuryAddressChanged(address _address);

    /// @param _address the new exchange manager address
    event ExchangeManagerAddressChanged(address _address);

    /// @param _adjustPositionPeriod the new boolean value of `adjustPositionPeriod`
    event SetAdjustPositionPeriod(bool _adjustPositionPeriod);

    /// @param _redeemFeeBps the new value of `_redeemFeeBps`
    event RedeemFeeUpdated(uint256 _redeemFeeBps);

    /// @param _queues the new queue to withdraw
    event SetWithdrawalQueue(address[] _queues);

    /// @param _totalShares The total shares when rebasing
    /// @param _totalValue The total value when rebasing
    /// @param _newUnderlyingUnitsPerShare The new value of `underlyingUnitsPerShare` when rebasing
    event Rebase(uint256 _totalShares, uint256 _totalValue, uint256 _newUnderlyingUnitsPerShare);

    /// @param _totalDebtOfBeforeAdjustPosition The total debt Of before adjust position
    /// @param _trackedAssets The address list of assets tracked
    /// @param _vaultCashDetatil The assets's balance list of vault
    /// @param _vaultBufferCashDetail The amount list of assets transfer from vault buffer to vault
    event StartAdjustPosition(
        uint256 _totalDebtOfBeforeAdjustPosition,
        address[] _trackedAssets,
        uint256[] _vaultCashDetatil,
        uint256[] _vaultBufferCashDetail
    );

    /// @param _transferValue The total value to transfer on this adjust position
    /// @param _redeemValue The total value to redeem on this adjust position
    /// @param _totalDebt The all strategy asset value
    /// @param _totalValueOfAfterAdjustPosition The total asset value Of vault after adjust position
    /// @param _totalValueOfBeforeAdjustPosition The total asset value Of vault before adjust position
    event EndAdjustPosition(
        uint256 _transferValue,
        uint256 _redeemValue,
        uint256 _totalDebt,
        uint256 _totalValueOfAfterAdjustPosition,
        uint256 _totalValueOfBeforeAdjustPosition
    );

    /// @param _pegTokenAmount The amount of the pegged token
    /// @param _assets The address list of asset transfer from vault buffer to vault
    /// @param _amounts The amount list of asset transfer from vault buffer to vault
    event PegTokenSwapCash(uint256 _pegTokenAmount, address[] _assets, uint256[] _amounts);

    address internal constant ZERO_ADDRESS = address(0);

    /// @dev max percentage 100%
    uint256 internal constant MAX_BPS = 10000;

    /// @dev all strategy
    EnumerableSet.AddressSet internal strategySet;
    /// @dev Assets supported by the Vault, i.e. Stablecoins
    EnumerableSet.AddressSet internal assetSet;
    /// @dev Assets held by Vault
    IterableIntMap.AddressToIntMap internal trackedAssetsMap;

    /// @notice adjust Position Period
    bool public adjustPositionPeriod;
    /// @notice  emergency shutdown
    bool public emergencyShutdown;

    // Amount of yield collected in basis points
    uint256 public trusteeFeeBps;
    /// @notice  Redemption fee in basis points
    uint256 public redeemFeeBps;
    /// @notice all strategy asset
    uint256 public totalDebt;
    /// @notice  treasury contract that can collect a percentage of yield
    address public treasury;
    /// @notice Address of the Oracle price provider contract
    address public priceProvider;
    /// @notice exchangeManager
    address public exchangeManager;
    /// @notice  strategy info
    mapping(address => StrategyParams) public strategies;

    /// @notice withdraw strategy set
    address[] public withdrawQueue;
    /// @dev calculated from the keccak256("ETHi.vault.governor.admin.impl");
    bytes32 internal constant ADMIN_IMPL_POSITION =
        0xfa89c25d41afc3612e6438675f8ecd0190711981b04c08aa14be180784e299e7;

    // Pausing bools
    bool public rebasePaused;
    // over this difference ratio automatically rebase. rebaseThreshold is the numerator and the denominator is 10000000 x/10000000.
    uint256 public rebaseThreshold;

    /// @notice The vault buffer Address
    address public vaultBufferAddress;
    /// @notice  ethi PegToken address
    address public pegTokenAddress;
    /// @dev Assets held in Vault from vault buffer
    mapping(address => uint256) internal transferFromVaultBufferAssetsMap;
    /// @dev redeem Assets where ad
    mapping(address => uint256) internal redeemAssetsMap;
    /// @dev Assets held in Vault and buffer before Adjust Position
    mapping(address => uint256) internal beforeAdjustPositionAssetsMap;
    /// @dev totalDebt before Adjust Position
    uint256 internal totalDebtOfBeforeAdjustPosition;
    /// @notice  totalAsset/totalShare
    uint256 public underlyingUnitsPerShare;
    /// @notice Maximum timestamp between two reported
    uint256 public maxTimestampBetweenTwoReported;
    /// @notice Minimum strategy total debt that will be checked for the strategy reporting
    uint256 public minCheckedStrategyTotalDebt;
    /// @notice Minimum investment amount
    uint256 public minimumInvestmentAmount;

    /// @dev max percentage 1e7/1e7
    uint256 internal constant TEN_MILLION_BPS = 10000000;

    /// @dev set the implementation for the admin, this needs to be in a base class else we cannot set it
    /// @param _newImpl address of the implementation
    /// Requirements: only governance or delegate role can call
    function setAdminImpl(address _newImpl) external onlyGovOrDelegate {
        require(AddressUpgradeable.isContract(_newImpl), "new implementation is not a contract");
        bytes32 _position = ADMIN_IMPL_POSITION;
        assembly {
            sstore(_position, _newImpl)
        }
    }
}
