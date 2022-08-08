// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";
import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";
import "./../../enums/ProtocolEnum.sol";

import "../../../external/dodo/DodoVault.sol";
import "../../../external/dodo/DodoStakePoolV1.sol";
import "../../../utils/actions/DodoPoolActionsMixin.sol";

abstract contract DodoBaseStrategy is BaseClaimableStrategy, DodoPoolActionsMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // reward token address
    address internal constant DODO = 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd;

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
        STAKE_POOL_ADDRESS = _stakePoll;

        address[] memory _wants = new address[](2);
        _wants[0] = DodoVault(_lpTokenPool)._BASE_TOKEN_();
        _wants[1] = DodoVault(_lpTokenPool)._QUOTE_TOKEN_();

        super._initialize(_vault, _harvester, uint16(ProtocolEnum.Dodo), _wants);
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        (uint256 baseReserve, uint256 quoteReserve) = DodoVault(lpTokenPool).getVaultReserve();
        _ratios = new uint256[](_assets.length);
        _ratios[0] = baseReserve;
        _ratios[1] = quoteReserve;
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory outputsInfo)
    {
        outputsInfo = new OutputInfo[](1);
        OutputInfo memory info0 = outputsInfo[0];
        info0.outputCode = 0;
        info0.outputTokens = wants; 

        // not support remove_liquidity_one_coin
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
        address _lpTokenPool = lpTokenPool;
        _tokens = wants;
        _amounts = new uint256[](_tokens.length);
        uint256 lpAmount = balanceOfLpToken(address(this));
        (uint256 reserve0, uint256 reserve1) = DodoVault(_lpTokenPool).getVaultReserve();
        uint256 totalSupply = DodoVault(_lpTokenPool).totalSupply();

        _amounts[0] = (reserve0 * lpAmount) / totalSupply + balanceOfToken(_tokens[0]);
        _amounts[1] = (reserve1 * lpAmount) / totalSupply + balanceOfToken(_tokens[1]);
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _wants = wants;
        address _lpTokenPool = lpTokenPool;
        uint256 targetPoolTotalAssets;

        uint256 baseTokenAmount = DodoVault(_lpTokenPool)._BASE_RESERVE_();
        if (baseTokenAmount > 0) {
            targetPoolTotalAssets += queryTokenValue(_wants[0], baseTokenAmount);
        }

        uint256 quoteTokenAmount = DodoVault(_lpTokenPool)._QUOTE_RESERVE_();
        if (quoteTokenAmount > 0) {
            targetPoolTotalAssets += queryTokenValue(_wants[1], quoteTokenAmount);
        }

        return targetPoolTotalAssets;
    }

    function getPendingRewards()
        internal
        view
        returns (address[] memory _rewardsTokens, uint256[] memory _pendingAmounts)
    {
        _rewardsTokens = new address[](1);
        _rewardsTokens[0] = DODO;
        _pendingAmounts = new uint256[](1);
        _pendingAmounts[0] = balanceOfToken(DODO) + getPendingRewardByToken(DODO);
    }

    function claimRewards()
        internal
        override
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        (_rewardTokens, _claimAmounts) = getPendingRewards();
        if (_claimAmounts[0] > 0) {
            __claimAllRewards();
        }
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        address _lpTokenPool = lpTokenPool;
        IERC20Upgradeable(_assets[0]).safeTransfer(_lpTokenPool, _amounts[0]);
        IERC20Upgradeable(_assets[1]).safeTransfer(_lpTokenPool, _amounts[1]);
        (uint256 shares, uint256 baseInput, uint256 quoteInput) = DodoVault(_lpTokenPool)
            .buyShares(address(this));
        console.log("[%s] buyShares success, shares=%s,", address(this), shares);
        console.log("[%s] buyShares success, baseInput=%s, quoteInput=%s", address(this), baseInput, quoteInput);
        uint256 lpAmount = IERC20Upgradeable(_lpTokenPool).balanceOf(address(this));
        console.log("[%s] lpAmount=", address(this), lpAmount);
        // Pledge lptoken for mining
        __deposit(lpAmount);
    }

    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        console.log("[%s] _withdrawSomeLpToken=", address(this), _withdrawShares, _totalShares);
        uint256 _lpAmount = balanceOfLpToken(address(this));

        if (_lpAmount > 0 && _withdrawShares > 0) {
            uint256 _withdrawAmount = (_lpAmount * _withdrawShares) / _totalShares;
            __withdrawLpToken(_withdrawAmount);
            // Sell the corresponding lp
            DodoVault(lpTokenPool).sellShares(
                _withdrawAmount,
                address(this),
                0,
                0,
                "",
                block.timestamp + 600
            );
        }
    }
}
