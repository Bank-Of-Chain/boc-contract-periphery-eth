// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../../external/curve/ICurveLiquidityPool.sol";
import "../../../../external/yearn/IYearnVault.sol";

import "../ConvexBaseStrategy.sol";

/// @title ConvexMetaPoolStrategy
/// @notice Investment strategy for investing stablecoins to curve meta pool via Convex
/// @author Bank of Chain Protocol Inc
contract ConvexMetaPoolStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant POOL3 = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address private constant CRV3 = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    uint256 private constant USD_INDEX = 0;
    uint256 private constant CRV3_INDEX = 1;

    /// @notice One of wanted tokens(stablecoins)
    address public pairToken;

    ////// fallback and receive //////
    receive() external payable {}

    fallback() external payable {}

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _name The name of strategy
    /// @param _pairToken One of wanted tokens(stablecoins)
    /// @param _curvePool The curve pool invested 
    /// @param _rewardPool The address of the base reward pool which issue reward linearly
    function initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address _pairToken,
        address _curvePool,
        address _rewardPool
    ) external initializer {
        pairToken = _pairToken;
        address[] memory _wants = new address[](4);
        // the oder is same with underlying coins
        // DAI
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        // USDC
        _wants[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        // USDT
        _wants[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        _wants[3] = _pairToken;
        super._initialize(_vault, _harvester, _name, _wants, _curvePool, _rewardPool);
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
        ICurveLiquidityPool _curveLiquidityPool = ICurveLiquidityPool(curvePool);
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        _ratios[3] = _curveLiquidityPool.balances(USD_INDEX);
        uint256 _crv3Amount = _curveLiquidityPool.balances(CRV3_INDEX);
        uint256 _crv3Supply = IERC20Upgradeable(CRV3).totalSupply();
        for (uint256 i = 0; i < 3; i++) {
            _ratios[i] = (ICurveLiquidityPool(POOL3).balances(i) * _crv3Amount) / _crv3Supply;
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
        _outputsInfo = new OutputInfo[](5);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = _wants; //other

        OutputInfo memory _info1 = _outputsInfo[1];
        _info1.outputCode = 1;
        _info1.outputTokens = new address[](1);
        _info1.outputTokens[0] = _wants[0];

        OutputInfo memory _info2 = _outputsInfo[2];
        _info2.outputCode = 2;
        _info2.outputTokens = new address[](1);
        _info2.outputTokens[0] = _wants[1];

        OutputInfo memory _info3 = _outputsInfo[3];
        _info3.outputCode = 3;
        _info3.outputTokens = new address[](1);
        _info3.outputTokens[0] = _wants[2];

        OutputInfo memory _info4 = _outputsInfo[4];
        _info4.outputCode = 4;
        _info4.outputTokens = new address[](1);
        _info4.outputTokens[0] = _wants[3];
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
        // curve LP token amount = convex LP token amount
        uint256 _lpAmount = balanceOfLpToken();
        // curve LP total supply
        uint256 _totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        // calc balances
        _amounts = new uint256[](_tokens.length);
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        uint256 _crv3Amount = _pool.balances(CRV3_INDEX);
        uint256 _crv3Supply = IERC20Upgradeable(CRV3).totalSupply();
        _amounts[3] = (_pool.balances(USD_INDEX) * _lpAmount) / _totalSupply;
        for (uint256 i = 0; i < 3; i++) {
            _amounts[i] =
                (ICurveLiquidityPool(POOL3).balances(i) * _crv3Amount * _lpAmount) /
                _crv3Supply /
                _totalSupply;
        }
    }

    /// @notice Return the third party protocol's pool total assets in USD(1e18).
    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _assets = wants;
        uint256 _crv3Amount = ICurveLiquidityPool(curvePool).balances(CRV3_INDEX);
        uint256 _crv3Supply = IERC20Upgradeable(CRV3).totalSupply();
        uint256 _thirdPoolAssets = queryTokenValue(
            _assets[3],
            ICurveLiquidityPool(curvePool).balances(USD_INDEX)
        );
        for (uint256 i = 0; i < 3; i++) {
            _thirdPoolAssets += queryTokenValue(
                _assets[i],
                (ICurveLiquidityPool(POOL3).balances(i) * _crv3Amount) / _crv3Supply
            );
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
        bool _has3Crv = false;
        for (uint256 i = 0; i < 3; i++) {
            if (_amounts[i] > 0) {
                _has3Crv = true;
                IERC20Upgradeable(_assets[i]).safeApprove(POOL3, 0);
                IERC20Upgradeable(_assets[i]).safeApprove(POOL3, _amounts[i]);
            }
        }
        uint256 _balanceOf3Crv = 0;
        if (_has3Crv) {
            ICurveLiquidityPool(POOL3).add_liquidity([_amounts[0], _amounts[1], _amounts[2]], 0);
            _balanceOf3Crv = balanceOfToken(CRV3);
            IERC20Upgradeable(CRV3).safeApprove(_curvePool, 0);
            IERC20Upgradeable(CRV3).safeApprove(_curvePool, _balanceOf3Crv);
        }

        if (_amounts[3] > 0) {
            IERC20Upgradeable(_assets[3]).safeApprove(_curvePool, 0);
            IERC20Upgradeable(_assets[3]).safeApprove(_curvePool, _amounts[3]);
        }

        ICurveLiquidityPool(curvePool).add_liquidity([_amounts[3], _balanceOf3Crv], 0);
        return balanceOfToken(lpToken);
    }

    /// @notice Remove liquidity from curve pool
    /// @param _liquidity The amount of liquidity to remove
    /// @param _outputCode The code of output
    function curveRemoveLiquidity(uint256 _liquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool _pool = ICurveLiquidityPool(curvePool);
        if (_outputCode == 4) {
            _pool.remove_liquidity_one_coin(_liquidity, 0, 0);
        } else if (_outputCode > 0 && _outputCode < 4) {
            int128 _index;
            if (_outputCode == 1) {
                _index = 0;
            } else if (_outputCode == 2) {
                _index = 1;
            } else if (_outputCode == 3) {
                _index = 2;
            }
            _pool.remove_liquidity_one_coin(_liquidity, 1, 0);
            uint256 _balanceOf3Crv = balanceOfToken(CRV3);
            ICurveLiquidityPool(POOL3).remove_liquidity_one_coin(_balanceOf3Crv, _index, 0);
        } else {
            _pool.remove_liquidity(_liquidity, [uint256(0), uint256(0)]);
            uint256 _balanceOf3Crv = balanceOfToken(CRV3);
            ICurveLiquidityPool(POOL3).remove_liquidity(
                _balanceOf3Crv,
                [uint256(0), uint256(0), uint256(0)]
            );
        }
    }
}
