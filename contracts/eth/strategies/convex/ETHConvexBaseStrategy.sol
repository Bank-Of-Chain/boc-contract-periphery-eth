// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../ETHBaseClaimableStrategy.sol";
import "../../../external/convex/IConvexReward.sol";
import "../../../external/convex/IConvex.sol";
import "../../enums/ProtocolEnum.sol";
import "../../../external/uniswap/IUniswapV2Router2.sol";
import "../../../external/curve/ICurveLiquidityPoolPayable.sol";

/// @title ETHConvexBaseStrategy
/// @author Bank of Chain Protocol Inc
abstract contract ETHConvexBaseStrategy is ETHBaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    mapping(address => address[]) public uniswapRewardRoutes;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    IConvex internal constant BOOSTER = IConvex(address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31));
    IUniswapV2Router2 public constant ROUTER2 = IUniswapV2Router2(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    function _initialize(address _vault,string memory _name) internal {
        super._initialize(_vault, uint16(ProtocolEnum.Convex), _name,getConvexWants());
        isWantRatioIgnorable = true;
    }

    /// @notice Sets the path of swap from reward token
    /// @param _token The reward token
    /// @param _uniswapRouteToToken The token address list contains reward token and toToken
    /// Requirements: only vault manager can call
    function setRewardSwapPath(address _token, address[] memory _uniswapRouteToToken) public isVaultManager {
        uniswapRewardRoutes[_token] = _uniswapRouteToToken;
    }

    /// @notice Return the address of the base reward pool
    function getRewardPool() internal pure virtual returns (IConvexReward);

    /// @notice Return the pId
    function getPid() internal pure virtual returns (uint256);

    /// @notice Return the LP token address
    function getLpToken() internal pure virtual returns (address);

    /// @notice Return the underlying token list needed by the strategy via Convex
    function getConvexWants() internal pure virtual returns (address[] memory);

    /// @notice Return the reward token list of this pool
    function getConvexRewards() internal pure virtual returns (address[] memory);

    /// @notice Return the liquidity pool invested of Curve
    function getCurvePool() internal pure virtual returns (ICurveLiquidityPoolPayable);

    /// @notice Add liquidity into curve pool
    /// @param _assets The asset list to add
    /// @param _amounts The amount list to add
    /// @return The amount of liquidity
    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts) internal virtual returns (uint256);

    /// @notice Remove liquidity into curve pool
    /// @param _liquidity The amount of liquidity to remove
    /// @param _outputCode The code of output
    function curveRemoveLiquidity(uint256 _liquidity,uint256 _outputCode) internal virtual;

    /// @notice Sell WETH to wanted token
    function sellWETH2Want() internal virtual;

    /// @inheritdoc ETHBaseStrategy
    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares,uint256 _outputCode) internal override {
        uint256 _lpAmount = (balanceOfLpToken() * _withdrawShares) / _totalShares;
        if (_lpAmount > 0) {
            // https://etherscan.io/tx/0x9afc916be07738a7a4556d555c59e775d17ddc32d6eb48cdab83e006cd613394
            getRewardPool().withdrawAndUnwrap(_lpAmount, false);
            curveRemoveLiquidity(_lpAmount,_outputCode);
        }
    }
    /// @inheritdoc ETHBaseClaimableStrategy
    // https://etherscan.io/tx/0x0d6595b02f7c54ccb669cd72383b0dd54c0a00e3195f109843617889a967db3a
    function claimRewards()
        internal
        virtual
        override
        returns (
            bool _isWorth,
            address[] memory _assets,
            uint256[] memory _amounts
        )
    {
        uint256 _rewardCRVAmount = getRewardPool().earned(address(this));
        if (_rewardCRVAmount > 0) {
            getRewardPool().getReward();
            _assets = getConvexRewards();
            _amounts = new uint256[](_assets.length);
            for (uint256 i = 0; i < _assets.length; i++) {
                _amounts[i] = balanceOfToken(_assets[i]);
            }
            _isWorth = true;
        }
    }

    /// @inheritdoc ETHBaseClaimableStrategy
    function swapRewardsToWants() internal virtual override returns(address[] memory _wantTokens,uint256[] memory _wantAmounts){
        uint256 _wethBalanceLast = balanceOfToken(W_ETH);
        uint256 _wethBalanceCur;

        address[] memory _rewardTokens = getConvexRewards();
        _wantTokens = new address[](_rewardTokens.length);
        _wantAmounts = new uint256[](_rewardTokens.length);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            uint256 _rewardAmount = balanceOfToken(_rewardTokens[i]);
            if (_rewardAmount > 0) {
                IERC20Upgradeable(_rewardTokens[i]).safeApprove(address(ROUTER2), 0);
                IERC20Upgradeable(_rewardTokens[i]).safeApprove(address(ROUTER2), _rewardAmount);
                // sell to one coin then reinvest
                ROUTER2.swapExactTokensForTokens(_rewardAmount, 0, uniswapRewardRoutes[_rewardTokens[i]], address(this), block.timestamp);
            }

            _wantTokens[i] = W_ETH;
            
            _wethBalanceCur = balanceOfToken(W_ETH);
            _wantAmounts[i] = _wethBalanceCur - _wethBalanceLast;
            _wethBalanceLast = _wethBalanceCur;
        }
        sellWETH2Want();
    }

    /// @notice Return the LP token's balance Of this contract
    function balanceOfLpToken() internal view returns (uint256) {
        return getRewardPool().balanceOf(address(this));
    }

    /// @inheritdoc ETHBaseStrategy
    function get3rdPoolAssets() external view override returns (uint256) {
        uint256 _thirdPoolAssets = 0;
        for (uint256 i = 0; i < wants.length; i++) {
            _thirdPoolAssets = _thirdPoolAssets + queryTokenValueInETH(wants[i], getCurvePool().balances(i));
        }
        return _thirdPoolAssets;
    }
}
