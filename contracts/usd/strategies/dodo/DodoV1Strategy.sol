// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";
import "./../../enums/ProtocolEnum.sol";

import "../../../external/dodo/DodoVaultV1.sol";
import "../../../external/dodo/DodoStakePoolV1.sol";
import "../../../utils/actions/DodoPoolV1ActionsMixin.sol";

/// @title DodoV1Strategy
/// @notice Investment strategy for investing stablecoins via DodoV1
/// @author Bank of Chain Protocol Inc
contract DodoV1Strategy is BaseClaimableStrategy, DodoPoolV1ActionsMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // deposit pool
    address internal lpTokenPool;
    // reward token address
    address internal constant DODO = 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd;

    mapping(address => address[]) internal rewardsExchangePath;

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _name The name of strategy
    /// @param _lpTokenPool The LP token pool address
    /// @param _stakePool The Id of the stake pool invested
    function initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address _lpTokenPool,
        address _stakePool
    ) external initializer {
        require(_vault != address(0), "vault cannot be 0.");
        require(_stakePool != address(0), "stakePool cannot be 0.");
        require(_lpTokenPool != address(0), "lpTokenPool cannot be 0.");
        lpTokenPool = _lpTokenPool;
        STAKE_POOL_V1_ADDRESS = _stakePool;

        BASE_LP_TOKEN = DodoVaultV1(_lpTokenPool)._BASE_CAPITAL_TOKEN_();
        QUOTE_LP_TOKEN = DodoVaultV1(_lpTokenPool)._QUOTE_CAPITAL_TOKEN_();

        address[] memory _wants = new address[](2);
        _wants[0] = DodoVaultV1(_lpTokenPool)._BASE_TOKEN_();
        _wants[1] = DodoVaultV1(_lpTokenPool)._QUOTE_TOKEN_();

        super._initialize(_vault, _harvester, _name, uint16(ProtocolEnum.Dodo), _wants);
    }

    /// @notice Return the version of strategy
    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    /// @notice Return the underlying token list and ratio list needed by the strategy
    /// @return _assets the address list of token to deposit
    /// @return _ratios the ratios list of `_assets`. 
    ///     The ratio is the proportion of each asset to total assets
    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        (uint256 _baseExpectedTarget, uint256 _quoteExpectedTarget) = DodoVaultV1(lpTokenPool)
            .getExpectedTarget();
        _ratios = new uint256[](_assets.length);
        _ratios[0] = _baseExpectedTarget;
        _ratios[1] = _quoteExpectedTarget;
    }

    /// @notice Return the output path list of the strategy when withdraw.
    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](1);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = wants;

        // not support remove_liquidity_one_coin
    }

    /// @notice Returns the position details of the strategy.
    /// @return _tokens The list of the position token
    /// @return _amounts The list of the position amount
    /// @return _isUsd Whether to count in USD
    /// @return _usdValue The USD value of positions held
    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        )
    {
        _tokens = wants;
        _amounts = valueOfLpTokens();
        address _lpTokenPool = lpTokenPool;
        uint256 _basePenalty = DodoVaultV1(_lpTokenPool).getWithdrawBasePenalty(_amounts[0]);
        uint256 _quotePenalty = DodoVaultV1(_lpTokenPool).getWithdrawQuotePenalty(_amounts[1]);
        _amounts[0] -= _basePenalty;
        _amounts[1] -= _quotePenalty;
        _amounts[0] += balanceOfToken(_tokens[0]);
        _amounts[1] += balanceOfToken(_tokens[1]);
    }

    function balanceOfLpTokens() private view returns (uint256[] memory) {
        uint256[] memory _lpTokenAmounts = new uint256[](2);
        _lpTokenAmounts[0] = balanceOfBaseLpToken();
        _lpTokenAmounts[1] = balanceOfQuoteLpToken();
        return _lpTokenAmounts;
    }

    function valueOfLpTokens() private view returns (uint256[] memory) {
        uint256[] memory _lpTokenAmounts = balanceOfLpTokens();
        uint256[] memory _amounts = new uint256[](2);
        address _lpTokenPool = lpTokenPool;
        _amounts[0] =
            (_lpTokenAmounts[0] * DodoVaultV1(_lpTokenPool)._TARGET_BASE_TOKEN_AMOUNT_()) /
            DodoVaultV1(_lpTokenPool).getTotalBaseCapital();
        _amounts[1] =
            (_lpTokenAmounts[1] * DodoVaultV1(_lpTokenPool)._TARGET_QUOTE_TOKEN_AMOUNT_()) /
            DodoVaultV1(_lpTokenPool).getTotalQuoteCapital();
        return _amounts;
    }

    /// @notice Return the third party protocol's pool total assets in USD.
    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _wants = wants;
        address _lpTokenPool = lpTokenPool;
        uint256 _targetPoolTotalAssets;

        uint256 _baseTokenAmount = DodoVaultV1(_lpTokenPool)._TARGET_BASE_TOKEN_AMOUNT_();
        if (_baseTokenAmount > 0) {
            _targetPoolTotalAssets += queryTokenValue(_wants[0], _baseTokenAmount);
        }

        uint256 _quoteTokenAmount = DodoVaultV1(_lpTokenPool)._TARGET_QUOTE_TOKEN_AMOUNT_();
        if (_quoteTokenAmount > 0) {
            _targetPoolTotalAssets += queryTokenValue(_wants[1], _quoteTokenAmount);
        }

        return _targetPoolTotalAssets;
    }

    /// @notice Gets the info of pending reward tokens  
    /// @return _rewardsTokens The list of the reward token
    /// @return _pendingAmounts The list of the reward amount pending
    function getPendingRewards()
        internal
        view
        returns (address[] memory _rewardsTokens, uint256[] memory _pendingAmounts)
    {
        _rewardsTokens = new address[](1);
        _rewardsTokens[0] = DODO;
        _pendingAmounts = new uint256[](1);
        _pendingAmounts[0] = balanceOfToken(DODO) + getPendingReward();
    }

    /// @notice Collect the rewards from third party protocol
    /// @return _rewardTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function claimRewards()
        internal
        override
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        (_rewardTokens, _claimAmounts) = getPendingRewards();
        if (_claimAmounts[0] > 0) {
            __claimRewards(BASE_LP_TOKEN);
            __claimRewards(QUOTE_LP_TOKEN);
        }
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        uint8 _rStatus = DodoVaultV1(lpTokenPool)._R_STATUS_();
        // Deposit fewer coins first ,so than will get rewards
        if (_rStatus == 2) {
            _depositQuoteToken(_assets[1], _amounts[1]);
            _depositBaseToken(_assets[0], _amounts[0]);
        } else {
            _depositBaseToken(_assets[0], _amounts[0]);
            _depositQuoteToken(_assets[1], _amounts[1]);
        }
    }

    function _depositBaseToken(address _asset, uint256 _amount) internal {
        if (_amount > 0) {
            address _lpTokenPool = lpTokenPool;
            IERC20Upgradeable(_asset).safeApprove(_lpTokenPool, 0);
            IERC20Upgradeable(_asset).safeApprove(_lpTokenPool, _amount);
            DodoVaultV1(_lpTokenPool).depositBase(_amount);
            uint256 _baseLiquidity = balanceOfToken(BASE_LP_TOKEN);
            IERC20Upgradeable(BASE_LP_TOKEN).safeApprove(STAKE_POOL_V1_ADDRESS, 0);
            IERC20Upgradeable(BASE_LP_TOKEN).safeApprove(STAKE_POOL_V1_ADDRESS, _baseLiquidity);
            DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).deposit(BASE_LP_TOKEN, _baseLiquidity);
        }
    }

    function _depositQuoteToken(address _asset, uint256 _amount) internal {
        if (_amount > 0) {
            address _lpTokenPool = lpTokenPool;
            IERC20Upgradeable(_asset).safeApprove(_lpTokenPool, 0);
            IERC20Upgradeable(_asset).safeApprove(_lpTokenPool, _amount);
            DodoVaultV1(_lpTokenPool).depositQuote(_amount);
            uint256 _quoteLiquidity = balanceOfToken(QUOTE_LP_TOKEN);
            IERC20Upgradeable(QUOTE_LP_TOKEN).safeApprove(STAKE_POOL_V1_ADDRESS, 0);
            IERC20Upgradeable(QUOTE_LP_TOKEN).safeApprove(STAKE_POOL_V1_ADDRESS, _quoteLiquidity);
            DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).deposit(QUOTE_LP_TOKEN, _quoteLiquidity);
        }
    }

    /// @notice Strategy withdraw the funds from third party pool
    /// @param _withdrawShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @param _outputCode The code of output
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        address _lpTokenPool = lpTokenPool;
        uint256 _baseWithdrawAmount = (balanceOfBaseLpToken() * _withdrawShares) / _totalShares;
        uint256 _quoteWithdrawAmount = (balanceOfQuoteLpToken() * _withdrawShares) / _totalShares;
        (uint256 _baseExpectedTarget, uint256 _quoteExpectedTarget) = DodoVaultV1(_lpTokenPool)
            .getExpectedTarget();
        uint256 _totalBaseCapital = DodoVaultV1(_lpTokenPool).getTotalBaseCapital();
        uint256 _totalQuoteCapital = DodoVaultV1(_lpTokenPool).getTotalQuoteCapital();
        uint8 _rStatus = DodoVaultV1(_lpTokenPool)._R_STATUS_();
        if (_rStatus == 2) {
            if (_baseWithdrawAmount > 0) {
                __withdrawLpToken(BASE_LP_TOKEN, _baseWithdrawAmount);
                DodoVaultV1(_lpTokenPool).withdrawBase(
                    (_baseWithdrawAmount * _baseExpectedTarget) / _totalBaseCapital
                );
            }
            if (_quoteWithdrawAmount > 0) {
                __withdrawLpToken(QUOTE_LP_TOKEN, _quoteWithdrawAmount);
                DodoVaultV1(_lpTokenPool).withdrawQuote(
                    (_quoteWithdrawAmount * _quoteExpectedTarget) / _totalQuoteCapital
                );
            }
        } else {
            if (_quoteWithdrawAmount > 0) {
                __withdrawLpToken(QUOTE_LP_TOKEN, _quoteWithdrawAmount);
                DodoVaultV1(_lpTokenPool).withdrawQuote(
                    (_quoteWithdrawAmount * _quoteExpectedTarget) / _totalQuoteCapital
                );
            }
            if (_baseWithdrawAmount > 0) {
                __withdrawLpToken(BASE_LP_TOKEN, _baseWithdrawAmount);
                DodoVaultV1(_lpTokenPool).withdrawBase(
                    (_baseWithdrawAmount * _baseExpectedTarget) / _totalBaseCapital
                );
            }
        }
    }
}
