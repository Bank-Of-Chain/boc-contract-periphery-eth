// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/balancer/IAsset.sol";
import "../../../external/balancer/IBalancerVault.sol";
// aura fork from convex
import "../../../external/aura/IRewardPool.sol";
import "../../../external/aura/IAuraBooster.sol";

import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";
import "../../enums/ProtocolEnum.sol";

/// @title Aura3PoolStrategy
/// @notice Investment strategy for investing stablecoins via Aura 
/// @author Bank of Chain Protocol Inc
contract Aura3PoolStrategy is BaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }

    IAuraBooster internal constant AURA_BOOSTER =
        IAuraBooster(0x7818A1DA7BD1E64c199029E86Ba244a9798eEE10);

    IBalancerVault internal constant BALANCER_VAULT =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    address public constant AURA_TOKEN = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function initialize(address _vault, address _harvester,string memory _name) external initializer {
        address[] memory _wants = new address[](3);
        _wants[0] = DAI; //DAI
        _wants[1] = USDC; //USDC
        _wants[2] = USDT; //USDT

        _initialize(_vault, _harvester, _name, uint16(ProtocolEnum.Aura), _wants);

        uint256 _uintMax = type(uint256).max;
        // (address[] memory _tokens, , ) = BALANCER_VAULT.getPoolTokens(_poolKey);
        for (uint256 i = 0; i < _wants.length; i++) {
            address _token = _wants[i];
            // for enter balancer vault
            IERC20Upgradeable(_token).safeApprove(address(BALANCER_VAULT), _uintMax);
        }
        //for Booster deposit
        IERC20Upgradeable(getPoolLpToken()).safeApprove(address(AURA_BOOSTER), _uintMax);
        isWantRatioIgnorable = true;
    }

    /// @notice Return the version of strategy
    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    /// @notice Return the pool key
    function getPoolKey() internal pure returns (bytes32) {
        return 0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000063;
    }

    /// @notice Return the pId
    function getPId() internal pure returns (uint256) {
        return 0;
    }

    function getPoolLpToken() internal pure returns (address) {
        return 0x06Df3b2bbB68adc8B0e302443692037ED9f91b42;
    }

    /// @notice Return the LP token address of the rETH stable pool
    function getRewardPool() internal pure returns (address) {
        return 0x08b8a86B9498AC249bF4B86e14C5d4187085a239;
    }

    /// @notice Return the underlying token list and ratio list needed by the strategy
    /// @return _assets the address list of token to deposit
    /// @return _ratios the ratios list of `_assets`. 
    ///     The ratio is the proportion of each asset to total assets
    function getWantsInfo()
        external
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        (_assets, _ratios, ) = BALANCER_VAULT.getPoolTokens(getPoolKey());
    }

    /// @notice Return the output path list of the strategy when withdraw.
    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](4);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = wants;

        OutputInfo memory _info1 = _outputsInfo[1];
        _info1.outputCode = 1;
        _info1.outputTokens = new address[](1);
        _info1.outputTokens[0] = DAI;

        OutputInfo memory _info2 = _outputsInfo[2];
        _info2.outputCode = 2;
        _info2.outputTokens = new address[](1);
        _info2.outputTokens[0] = USDC;

        OutputInfo memory _info3 = _outputsInfo[3];
        _info3.outputCode = 3;
        _info3.outputTokens = new address[](1);
        _info3.outputTokens[0] = USDT;
    }

    /// @notice Return the 3rd protocol's pool total assets in USD.
    function get3rdPoolAssets() external view override returns (uint256) {
        uint256 _totalAssets;
        (address[] memory _tokens, uint256[] memory _balances, ) = BALANCER_VAULT.getPoolTokens(
            getPoolKey()
        );
        for (uint8 i = 0; i < _tokens.length; i++) {
            _totalAssets += queryTokenValue(_tokens[i], _balances[i]);
        }
        return _totalAssets;
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
        (_tokens, _amounts, ) = BALANCER_VAULT.getPoolTokens(getPoolKey());
        uint256 _stakingAmount = getStakingAmount();
        uint256 _lpTotalSupply = IERC20Upgradeable(getPoolLpToken()).totalSupply();
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] =
                (_amounts[i] * _stakingAmount) /
                _lpTotalSupply +
                balanceOfToken(_tokens[i]);
        }
    }

    /// @notice Return the amount staking on base reward pool
    function getStakingAmount() public view returns (uint256) {
        return IRewardPool(getRewardPool()).balanceOf(address(this));
    }

    function _getPoolAssets(bytes32 _poolKey) internal view returns (IAsset[] memory _poolAssets) {
        (address[] memory _tokens, , ) = BALANCER_VAULT.getPoolTokens(_poolKey);
        _poolAssets = new IAsset[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _poolAssets[i] = IAsset(_tokens[i]);
        }
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets deposit token address
    /// @param _amounts deposit token amount
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        uint256 _receiveLpAmount = _depositToBalancer(_assets, _amounts);
        AURA_BOOSTER.deposit(getPId(), _receiveLpAmount, true);
    }

    /// @notice Strategy deposit funds to the balancer protocol.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function _depositToBalancer(address[] memory _assets, uint256[] memory _amounts)
        internal
        virtual
        returns (uint256 _receiveLpAmount)
    {
        bytes32 _poolKey = getPoolKey();
        IBalancerVault.JoinPoolRequest memory _joinRequest = IBalancerVault.JoinPoolRequest({
            assets: _getPoolAssets(_poolKey),
            maxAmountsIn: _amounts,
            userData: abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, _amounts, 0),
            fromInternalBalance: false
        });

        BALANCER_VAULT.joinPool(_poolKey, address(this), address(this), _joinRequest);
        _receiveLpAmount = balanceOfToken(getPoolLpToken());
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
        uint256 _withdrawAmount = (getStakingAmount() * _withdrawShares) / _totalShares;
        //unstaking
        IRewardPool(getRewardPool()).redeem(_withdrawAmount, address(this), address(this));
        _withdrawFromBalancer(_withdrawAmount, _outputCode);
    }

    /// @notice Strategy withdraw the funds from the balancer protocol
    /// @param _exitAmount The amount to withdraw
    /// @param _outputCode The code of output
    function _withdrawFromBalancer(uint256 _exitAmount, uint256 _outputCode) internal virtual {
        bytes32 _poolKey = getPoolKey();
        address payable _recipient = payable(address(this));
        IAsset[] memory _poolAssets = _getPoolAssets(_poolKey);
        uint256[] memory _minAmountsOut = new uint256[](_poolAssets.length);
        IBalancerVault.ExitPoolRequest memory _exitRequest;
        if (_outputCode > 0 && _outputCode < 4) {
            uint256 index;
            if (_outputCode == 1) {
                index = 0;
            } else if (_outputCode == 2) {
                index = 1;
            } else if (_outputCode == 3) {
                index = 2;
            }
            _exitRequest = IBalancerVault.ExitPoolRequest({
                assets: _poolAssets,
                minAmountsOut: _minAmountsOut,
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, _exitAmount, index),
                toInternalBalance: false
            });
        } else {
            _exitRequest = IBalancerVault.ExitPoolRequest({
                assets: _poolAssets,
                minAmountsOut: _minAmountsOut,
                userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, _exitAmount),
                toInternalBalance: false
            });
        }
        BALANCER_VAULT.exitPool(_poolKey, address(this), _recipient, _exitRequest);
    }

    /// @notice Collect the rewards from 3rd protocol
    /// @return _rewardsTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function claimRewards()
        internal
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        address _rewardPool = getRewardPool();
        IRewardPool(_rewardPool).getReward();
        uint256 _extraRewardsLen = IRewardPool(_rewardPool).extraRewardsLength();
        _rewardsTokens = new address[](2 + _extraRewardsLen);
        _rewardsTokens[0] = BAL;
        _rewardsTokens[1] = AURA_TOKEN;
        _claimAmounts = new uint256[](2 + _extraRewardsLen);
        _claimAmounts[0] = balanceOfToken(BAL);
        _claimAmounts[1] = balanceOfToken(AURA_TOKEN);
        if (_extraRewardsLen > 0) {
            for (uint256 i = 0; i < _extraRewardsLen; i++) {
                address _extraReward = IRewardPool(_rewardPool).extraRewards(i);
                address _rewardToken = IRewardPool(_extraReward).rewardToken();
                // IRewardPool(_extraReward).getReward();
                _rewardsTokens[2 + i] = _rewardToken;
                _claimAmounts[2 + i] = balanceOfToken(_rewardToken);
            }
        }
    }
}
