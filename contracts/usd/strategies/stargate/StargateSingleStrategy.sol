// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";
import "./../../enums/ProtocolEnum.sol";
import "../../../external/stargate/IStargateLiquidityPool.sol";
import "../../../external/stargate/IStargateStakePool.sol";
import "../../../external/stargate/IStargatePool.sol";

/// @title StargateSingleStrategy
/// @notice Investment strategy for investing stablecoins via Stargate
/// @author Bank of Chain Protocol Inc
contract StargateSingleStrategy is BaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public constant REWARD_TOKEN_STG = address(0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6);
    IStargateStakePool internal constant STARGATE_STAKE_POOL =
        IStargateStakePool(0xB0D502E938ed5f4df2E681fE6E419ff29631d62b);
    IStargateRouterPool internal stargateRouterPool;
    IStargatePool internal stargatePool;
    uint256 poolId;
    uint256 stakePoolId;

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _name The name of strategy
    /// @param _router The router address of Stargate
    /// @param _underlying The lending asset of the Vault contract
    /// @param _lpToken The LP token address
    /// @param _poolId The Id of stargate's liquidity pool
    /// @param _stakePoolId The Id of stake pool on stargate
    function initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address _underlying,
        address _router,
        address _lpToken,
        uint256 _poolId,
        uint256 _stakePoolId
    ) external initializer {
        address[] memory _wants = new address[](1);
        _wants[0] = _underlying;
        stargatePool = IStargatePool(_lpToken);
        stargateRouterPool = IStargateRouterPool(_router);
        poolId = _poolId;
        stakePoolId = _stakePoolId;
        super._initialize(_vault, _harvester, _name, uint16(ProtocolEnum.Stargate), _wants);
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
        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
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
        IStargatePool _stargatePoolTmp = stargatePool;
        uint256 _localDecimals = _stargatePoolTmp.localDecimals();
        uint256 _decimals = _stargatePoolTmp.decimals();
        _tokens = wants;
        _amounts = new uint256[](1);
        _amounts[0] =
            balanceOfLpToken() *
            10**(_localDecimals - _decimals) +
            balanceOfToken(_tokens[0]);
    }

    /// @notice Gets the amount of liquidity this strategy deposited into `STARGATE_STAKE_POOL`
    function balanceOfLpToken() private view returns (uint256 _lpAmount) {
        (_lpAmount, ) = STARGATE_STAKE_POOL.userInfo(stakePoolId, address(this));
    }

    /// @notice Return the third party protocol's pool total assets in USD.
    function get3rdPoolAssets() external view override returns (uint256) {
        IStargatePool _stargatePoolTmp = stargatePool;
        uint256 _localDecimals = _stargatePoolTmp.localDecimals();
        uint256 _decimals = _stargatePoolTmp.decimals();
        uint256 _totalLiquidity = _stargatePoolTmp.totalLiquidity();
        return
            _totalLiquidity != 0
                ? queryTokenValue(wants[0], _totalLiquidity * 10**(_localDecimals - _decimals))
                : 0;
    }

    /// @notice Collect the rewards from third party protocol
    /// @return _rewardTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function claimRewards()
        internal
        override
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        uint256 _stakePoolId = stakePoolId;
        _rewardTokens = new address[](1);
        _rewardTokens[0] = REWARD_TOKEN_STG;
        _claimAmounts = new uint256[](1);
        _claimAmounts[0] = STARGATE_STAKE_POOL.pendingStargate(_stakePoolId, address(this));
        if (_claimAmounts[0] > 0) {
            STARGATE_STAKE_POOL.deposit(_stakePoolId, 0);
        }
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        // addLiquidity
        if (_amounts[0] > 0) {
            address _lpTokenTmp = address(stargatePool);
            address _routerTmp = address(stargateRouterPool);
            IERC20Upgradeable(_assets[0]).safeApprove(_routerTmp, 0);
            IERC20Upgradeable(_assets[0]).safeApprove(_routerTmp, _amounts[0]);
            IStargateRouterPool(_routerTmp).addLiquidity(poolId, _amounts[0], address(this));
            // stake liquidity
            uint256 _lpAmount = balanceOfToken(_lpTokenTmp);
            IERC20Upgradeable(_lpTokenTmp).safeApprove(address(STARGATE_STAKE_POOL), 0);
            IERC20Upgradeable(_lpTokenTmp).safeApprove(address(STARGATE_STAKE_POOL), _lpAmount);
            STARGATE_STAKE_POOL.deposit(stakePoolId, _lpAmount);
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
        uint256 _lpAmount = (balanceOfLpToken() * _withdrawShares) / _totalShares;
        if (_lpAmount > 0) {
            // unstake liquidity
            STARGATE_STAKE_POOL.withdraw(stakePoolId, _lpAmount);
            // remove liquidity
            stargateRouterPool.instantRedeemLocal(uint16(poolId), _lpAmount, address(this));
        }
    }
}
