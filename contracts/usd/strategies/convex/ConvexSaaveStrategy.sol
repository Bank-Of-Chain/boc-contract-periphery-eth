// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/curve/ICurveLiquidityPool.sol";

import "./ConvexBaseStrategy.sol";

/// @title ConvexSaaveStrategy
/// @notice Investment strategy for investing stablecoins to SAAVE via Convex 
/// @author Bank of Chain Protocol Inc
contract ConvexSaaveStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant STKAAVE = address(0x4da27a545c0c5B758a6BA100e3a049001de870f5);

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _name The name of strategy
    function initialize(
        address _vault,
        address _harvester,
        string memory _name
    ) public {
        address[] memory _wants = new address[](2);
        // the oder is same with underlying coins
        // DAI
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        // sUSD
        _wants[1] = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
        super._initialize(
            _vault,
            _harvester,
            _name,
            _wants,
            0xEB16Ae0052ed37f479f7fe63849198Df1765a733,
            0xF86AE6790654b70727dbE58BF1a863B270317fD0
        );
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
        _ratios = new uint256[](_assets.length);
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _assets.length; i++) {
            _ratios[i] = _pool.balances(i);
        }
    }

    /// @notice Return the output path list of the strategy when withdraw.
    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        address[] memory _wants = wants;
        _outputsInfo = new OutputInfo[](3);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = _wants;

        OutputInfo memory _info1 = _outputsInfo[1];
        _info1.outputCode = 1;
        _info1.outputTokens = new address[](1);
        _info1.outputTokens[0] = _wants[0];

        OutputInfo memory _info2 = _outputsInfo[2];
        _info2.outputCode = 2;
        _info2.outputTokens = new address[](1);
        _info2.outputTokens[0] = _wants[1];
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
        _amounts = new uint256[](_tokens.length);
        // curve LP token amount = convex LP token amount
        uint256 _lpAmount = balanceOfLpToken();
        // curve LP total supply
        uint256 _totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        // calc balances
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 _depositedTokenAmount = (_pool.balances(i) * _lpAmount) / _totalSupply;
            _amounts[i] = balanceOfToken(_tokens[i]) + _depositedTokenAmount;
        }
    }

    /// @notice Return the third party protocol's pool total assets in USD(1e18).
    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _assets = wants;
        uint256 _thirdPoolAssets;
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _thirdPoolAssetBalance = _pool.balances(i);
            _thirdPoolAssets += queryTokenValue(_assets[i], _thirdPoolAssetBalance);
        }
        return _thirdPoolAssets;
    }

    /// @notice Add liquidity into curve pool
    /// @param _assets The asset list to add
    /// @param _amounts The amount list to add
    /// @return The amount of liquidity
    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        address _curvePool = curvePool;
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] > 0) {
                IERC20Upgradeable(_assets[i]).safeApprove(_curvePool, 0);
                IERC20Upgradeable(_assets[i]).safeApprove(_curvePool, _amounts[i]);
            }
        }
        return ICurveLiquidityPool(_curvePool).add_liquidity([_amounts[0], _amounts[1]], 0, true);
    }


    /// @notice Remove liquidity from curve pool
    /// @param liquidity The amount of liquidity to remove
    /// @param _outputCode The code of output
    function curveRemoveLiquidity(uint256 liquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        if (_outputCode == 1) {
            _pool.remove_liquidity_one_coin(liquidity, 0, 0, true);
        } else if (_outputCode == 2) {
            _pool.remove_liquidity_one_coin(liquidity, 1, 0, true);
        } else {
            _pool.remove_liquidity(liquidity, [uint256(0), uint256(0)], true);
        }
    }

    /// @notice Collect the rewards from third party protocol
    /// @return _rewardTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function claimRewards()
        internal
        override
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        IConvexReward(rewardPool).getReward();
        _rewardTokens = new address[](3);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        _rewardTokens[2] = STKAAVE;
        _claimAmounts = new uint256[](3);
        _claimAmounts[0] = balanceOfToken(CRV);
        _claimAmounts[1] = balanceOfToken(CVX);
        _claimAmounts[2] = balanceOfToken(STKAAVE);
    }
}
