// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/curve/ICurveLiquidityPool.sol";

import "./ConvexBaseStrategy.sol";

/// @title ConvexSusdStrategy
/// @notice Investment strategy for investing SUSD via Convex 
/// @author Bank of Chain Protocol Inc
contract ConvexSusdStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant SNX = address(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _name The name of strategy
    function initialize(address _vault, address _harvester,string memory _name) public {
        address[] memory _wants = new address[](4);
        // the oder is same with underlying coins
        // DAI
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        // USDC
        _wants[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        // USDT
        _wants[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        // sUSD
        _wants[3] = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
        super._initialize(
            _vault,
            _harvester,
            _name,
            _wants,
            0xA5407eAE9Ba41422680e2e00537571bcC53efBfD,
            0x22eE18aca7F3Ee920D01F25dA85840D12d98E8Ca
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
        int128 _index = 0;
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _assets.length; i++) {
            _ratios[i] = _pool.balances(_index);
            _index++;
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
        _amounts = new uint256[](_tokens.length);
        // curve LP token amount = convex LP token amount
        uint256 _lpAmount = balanceOfLpToken();
        // curve LP total supply
        uint256 _totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        // calc balances
        int128 _index = 0;
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 _depositedTokenAmount = (_pool.balances(_index) * _lpAmount) / _totalSupply;
            _amounts[i] = balanceOfToken(_tokens[i]) + _depositedTokenAmount;
            _index++;
        }
    }

    /// @notice Return the third party protocol's pool total assets in USD(1e18).
    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _assets = wants;
        uint256 _thirdPoolAssets;
        int128 _index = 0;
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _thirdPoolAssetBalance = _pool.balances(_index);
            _thirdPoolAssets += queryTokenValue(_assets[i], _thirdPoolAssetBalance);
            _index++;
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
        ICurveLiquidityPool(_curvePool).add_liquidity([_amounts[0], _amounts[1], _amounts[2], _amounts[3]], 0);
        uint256 _lpAmount = balanceOfToken(lpToken);
        return _lpAmount;
    }

    /// @notice Remove liquidity from curve pool
    /// @param liquidity The amount of liquidity to remove
    /// @param _outputCode The code of output
    function curveRemoveLiquidity(uint256 liquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool(curvePool).remove_liquidity(liquidity, [uint256(0), uint256(0), uint256(0), uint256(0)]);
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
        _rewardTokens[2] = SNX;
        _claimAmounts = new uint256[](3);
        _claimAmounts[0] = balanceOfToken(CRV);
        _claimAmounts[1] = balanceOfToken(CVX);
        _claimAmounts[2] = balanceOfToken(SNX);
    }
}
