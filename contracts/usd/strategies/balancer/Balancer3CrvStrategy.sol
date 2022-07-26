// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/balancer/IAsset.sol";
import "../../../external/balancer/IBalancerVault.sol";
import "../../../external/balancer/IStakingLiquidityGauge.sol";
import "../../../external/balancer/IBalancerMinter.sol";

import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";
import "../../enums/ProtocolEnum.sol";
import "hardhat/console.sol";

contract Balancer3CrvStrategy is BaseClaimableStrategy {
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

    bytes32 public constant poolId =
    0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000063;

    address public constant BAL = address(0xba100000625a3754423978a60c9317c58a424e3D);
    //it's a ERC20
    address public constant poolLpToken = address(0x06Df3b2bbB68adc8B0e302443692037ED9f91b42);
    address public constant poolGauge = address(0x34f33CDaED8ba0E1CEECE80e5f4a73bcf234cfac);
    address public constant balancerMinter = address(0x239e55F427D44C3cc793f49bFB507ebe76638a2b);

    IBalancerVault private constant BALANCER_VAULT =
    IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IAsset[] public poolAssets;

    function initialize(address _vault, address _harvester) public initializer {
        address[] memory _wants = new address[](3);
        _wants[0] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //DAI
        _wants[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC
        _wants[2] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; //USDT

        isWantRatioIgnorable = true;

        IAsset[] memory _poolAssets = new IAsset[](_wants.length);
        for (uint256 i = 0; i < _wants.length; i++) {
            _poolAssets[i] = IAsset(_wants[i]);
        }
        poolAssets = _poolAssets;

        super._initialize(_vault, _harvester, uint16(ProtocolEnum.Balancer), _wants);
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "Balancer3CrvStrategy";
    }

    function getWantsInfo()
    external
    view
    override
    returns (address[] memory _assets, uint256[] memory _ratios)
    {
        (_assets, _ratios,) = BALANCER_VAULT.getPoolTokens(poolId);
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
        (_tokens, _amounts,) = BALANCER_VAULT.getPoolTokens(poolId);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = _amounts[i] * IStakingLiquidityGauge(poolGauge).balanceOf(address(this)) /IERC20Upgradeable(poolLpToken).totalSupply() + balanceOfToken(_tokens[i]);
        }
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        uint256 totalAssets;
        (address[] memory tokens, uint256[] memory balances,) = BALANCER_VAULT.getPoolTokens(
            poolId
        );
        for (uint8 i = 0; i < tokens.length; i++) {
            totalAssets += queryTokenValue(tokens[i], balances[i]);
        }
        return totalAssets;
    }

    function claimRewards()
    internal
    override
    returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        IBalancerMinter(balancerMinter).mint(poolGauge);
        _rewardsTokens = new address[](1);
        _rewardsTokens[0] = BAL;
        _claimAmounts = new uint256[](1);
        _claimAmounts[0] = balanceOfToken(BAL);
        console.log('claimed BAL amount: %d',_claimAmounts[0]);
    }

    // UserData struct:https://github.com/balancer-labs/balancer-v2-monorepo/blob/a1e58e0d5910bc41482c31f7921953ec68010a36/pkg/pool-stable/contracts/StablePoolUserDataHelpers.sol
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
    internal
    override
    {
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 amount = _amounts[i];
            if (amount > 0) {
                address token = _assets[i];
                IERC20Upgradeable(token).safeApprove(address(BALANCER_VAULT), 0);
                IERC20Upgradeable(token).safeApprove(address(BALANCER_VAULT), amount);
                console.log("depositTo3rdPool asset:%s,amount:%d", token, amount);
            }
        }

        IBalancerVault.JoinPoolRequest memory joinRequest = IBalancerVault.JoinPoolRequest({
        assets : poolAssets,
        maxAmountsIn : _amounts,
        userData : abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, _amounts, 0),
        fromInternalBalance : false
        });

        BALANCER_VAULT.joinPool(poolId, address(this), address(this), joinRequest);

        uint256 lpAmount = balanceOfToken(poolLpToken);
        IERC20Upgradeable(poolLpToken).safeApprove(poolGauge, 0);
        IERC20Upgradeable(poolLpToken).safeApprove(poolGauge, lpAmount);
        IStakingLiquidityGauge(poolGauge).deposit(lpAmount);
    }

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares) internal override {
        IStakingLiquidityGauge gauge = IStakingLiquidityGauge(poolGauge);
        uint256 _lpAmount = (gauge.balanceOf(address(this)) * _withdrawShares) / _totalShares;
        if (_lpAmount > 0) {
            gauge.withdraw(_lpAmount);
            address payable recipient = payable(address(this));
            IAsset[] memory _poolAssets = poolAssets;
            uint256[] memory minAmountsOut = new uint256[](_poolAssets.length);
            IBalancerVault.ExitPoolRequest memory exitRequest = IBalancerVault.ExitPoolRequest({
            assets : _poolAssets,
            minAmountsOut : minAmountsOut,
            userData : abi.encode(
                    ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT,
                    _lpAmount
                ),
            toInternalBalance : false
            });
            BALANCER_VAULT.exitPool(poolId, address(this), recipient, exitRequest);
        }
    }
}
