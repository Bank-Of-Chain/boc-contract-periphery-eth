// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "hardhat/console.sol";
import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";
import "./../../enums/ProtocolEnum.sol";

import "../../../external/dodo/DodoVaultV1.sol";
import "../../../external/dodo/DodoStakePoolV1.sol";
import "../../../utils/actions/DodoPoolV1ActionsMixin.sol";

abstract contract DodoBaseStrategyV1 is BaseClaimableStrategy, DodoPoolV1ActionsMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // deposit pool
    address internal lpTokenPool;
    // reward token address
    address internal constant DODO = 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd;

    mapping(address => address[]) internal rewardsExchangePath;

    function _initialize(
        address _vault,
        address _harvester,
        address _lpTokenPool,
        address _stakePoll
    ) internal {
        require(_vault != address(0), "vault cannot be 0.");
        require(_stakePoll != address(0), "stakePoll cannot be 0.");
        require(_lpTokenPool != address(0), "lpTokenPool cannot be 0.");
        lpTokenPool = _lpTokenPool;
        STAKE_POOL_V1_ADDRESS = _stakePoll;

        BASE_LP_TOKEN = DodoVaultV1(_lpTokenPool)._BASE_CAPITAL_TOKEN_();
        QUOTE_LP_TOKEN = DodoVaultV1(_lpTokenPool)._QUOTE_CAPITAL_TOKEN_();

        address[] memory _wants = new address[](2);
        _wants[0] = DodoVaultV1(_lpTokenPool)._BASE_TOKEN_();
        _wants[1] = DodoVaultV1(_lpTokenPool)._QUOTE_TOKEN_();

        super._initialize(_vault, _harvester, uint16(ProtocolEnum.Dodo), _wants);
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function getWantsInfo() public view override returns (address[] memory _assets, uint256[] memory _ratios) {
        _assets = wants;
        (uint256 baseExpectedTarget, uint256 quoteExpectedTarget) = DodoVaultV1(lpTokenPool).getExpectedTarget();
        _ratios = new uint256[](_assets.length);
        _ratios[0] = baseExpectedTarget;
        _ratios[1] = quoteExpectedTarget;
    }

    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool isUsd,
            uint256 usdValue
        )
    {
        _tokens = wants;
        _amounts = valueOfLpTokens();
        address _lpTokenPool = lpTokenPool;
        uint256 basePenalty = DodoVaultV1(_lpTokenPool).getWithdrawBasePenalty(_amounts[0]);
        uint256 quotePenalty = DodoVaultV1(_lpTokenPool).getWithdrawQuotePenalty(_amounts[1]);
        _amounts[0] -= basePenalty;
        _amounts[1] -= quotePenalty;
        _amounts[0] += balanceOfToken(_tokens[0]);
        _amounts[1] += balanceOfToken(_tokens[1]);
    }

    function balanceOfLpTokens() private view returns (uint256[] memory) {
        uint256[] memory lpTokenAmounts = new uint256[](2);
        lpTokenAmounts[0] = balanceOfBaseLpToken();
        lpTokenAmounts[1] = balanceOfQuoteLpToken();
        return lpTokenAmounts;
    }

    function valueOfLpTokens() private view returns (uint256[] memory) {
        uint256[] memory lpTokenAmounts = balanceOfLpTokens();
        uint256[] memory amounts = new uint256[](2);
        address _lpTokenPool = lpTokenPool;
        amounts[0] = (lpTokenAmounts[0] * DodoVaultV1(_lpTokenPool)._TARGET_BASE_TOKEN_AMOUNT_()) / DodoVaultV1(_lpTokenPool).getTotalBaseCapital();
        amounts[1] = (lpTokenAmounts[1] * DodoVaultV1(_lpTokenPool)._TARGET_QUOTE_TOKEN_AMOUNT_()) / DodoVaultV1(_lpTokenPool).getTotalQuoteCapital();
        return amounts;
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _wants = wants;
        address _lpTokenPool = lpTokenPool;
        uint256 targetPoolTotalAssets;

        uint256 baseTokenAmount = DodoVaultV1(_lpTokenPool)._TARGET_BASE_TOKEN_AMOUNT_();
        if (baseTokenAmount > 0) {
            targetPoolTotalAssets += queryTokenValue(_wants[0], baseTokenAmount);
        }

        uint256 quoteTokenAmount = DodoVaultV1(_lpTokenPool)._TARGET_QUOTE_TOKEN_AMOUNT_();
        if (quoteTokenAmount > 0) {
            targetPoolTotalAssets += queryTokenValue(_wants[1], quoteTokenAmount);
        }

        return targetPoolTotalAssets;
    }

    function getPendingRewards() internal view returns (address[] memory _rewardsTokens, uint256[] memory _pendingAmounts) {
        _rewardsTokens = new address[](1);
        _rewardsTokens[0] = DODO;
        _pendingAmounts = new uint256[](1);
        _pendingAmounts[0] = balanceOfToken(DODO) + getPendingReward();
    }

    function claimRewards() internal override returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts) {
        (_rewardTokens, _claimAmounts) = getPendingRewards();
        if (_claimAmounts[0] > 0) {
            __claimRewards(BASE_LP_TOKEN);
            __claimRewards(QUOTE_LP_TOKEN);
        }
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal override {
        uint8 rStatus = DodoVaultV1(lpTokenPool)._R_STATUS_();
        // Deposit fewer coins first ,so than will get rewards
        if (rStatus == 2) {
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
            uint256 baseLiquidity = balanceOfToken(BASE_LP_TOKEN);
            IERC20Upgradeable(BASE_LP_TOKEN).safeApprove(STAKE_POOL_V1_ADDRESS, 0);
            IERC20Upgradeable(BASE_LP_TOKEN).safeApprove(STAKE_POOL_V1_ADDRESS, baseLiquidity);
            DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).deposit(BASE_LP_TOKEN, baseLiquidity);
        }
    }

    function _depositQuoteToken(address _asset, uint256 _amount) internal {
        if (_amount > 0) {
            address _lpTokenPool = lpTokenPool;
            IERC20Upgradeable(_asset).safeApprove(_lpTokenPool, 0);
            IERC20Upgradeable(_asset).safeApprove(_lpTokenPool, _amount);
            DodoVaultV1(_lpTokenPool).depositQuote(_amount);
            uint256 quoteLiquidity = balanceOfToken(QUOTE_LP_TOKEN);
            IERC20Upgradeable(QUOTE_LP_TOKEN).safeApprove(STAKE_POOL_V1_ADDRESS, 0);
            IERC20Upgradeable(QUOTE_LP_TOKEN).safeApprove(STAKE_POOL_V1_ADDRESS, quoteLiquidity);
            DodoStakePoolV1(STAKE_POOL_V1_ADDRESS).deposit(QUOTE_LP_TOKEN, quoteLiquidity);
        }
    }

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares) internal override {
        address _lpTokenPool = lpTokenPool;
        uint256 _baseWithdrawAmount = (balanceOfBaseLpToken() * _withdrawShares) / _totalShares;
        uint256 _quoteWithdrawAmount = (balanceOfQuoteLpToken() * _withdrawShares) / _totalShares;
        (uint256 baseExpectedTarget, uint256 quoteExpectedTarget) = DodoVaultV1(_lpTokenPool).getExpectedTarget();
        uint256 totalBaseCapital = DodoVaultV1(_lpTokenPool).getTotalBaseCapital();
        uint256 totalQuoteCapital = DodoVaultV1(_lpTokenPool).getTotalQuoteCapital();
        uint8 rStatus = DodoVaultV1(_lpTokenPool)._R_STATUS_();
        if (rStatus == 2) {
            if (_baseWithdrawAmount > 0) {
                __withdrawLpToken(BASE_LP_TOKEN, _baseWithdrawAmount);
                DodoVaultV1(_lpTokenPool).withdrawBase((_baseWithdrawAmount * baseExpectedTarget) / totalBaseCapital);
            }
            if (_quoteWithdrawAmount > 0) {
                __withdrawLpToken(QUOTE_LP_TOKEN, _quoteWithdrawAmount);
                DodoVaultV1(_lpTokenPool).withdrawQuote((_quoteWithdrawAmount * quoteExpectedTarget) / totalQuoteCapital);
            }
        } else {
            if (_quoteWithdrawAmount > 0) {
                __withdrawLpToken(QUOTE_LP_TOKEN, _quoteWithdrawAmount);
                DodoVaultV1(_lpTokenPool).withdrawQuote((_quoteWithdrawAmount * quoteExpectedTarget) / totalQuoteCapital);
            }
            if (_baseWithdrawAmount > 0) {
                __withdrawLpToken(BASE_LP_TOKEN, _baseWithdrawAmount);
                DodoVaultV1(_lpTokenPool).withdrawBase((_baseWithdrawAmount * baseExpectedTarget) / totalBaseCapital);
            }
        }
    }
}
