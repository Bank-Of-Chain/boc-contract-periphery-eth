// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./ConvexBaseStrategy.sol";
import "../../../external/compound/ICToken.sol";
import "../../../external/curve/ICurveLiquidityPool.sol";

/// @title ConvexUsdtStrategy
/// @notice Investment strategy for investing USDT via Convex 
/// @author Bank of Chain Protocol Inc
contract ConvexUsdtStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address private constant cDAI = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    address private constant cUSDC = address(0x39AA39c021dfbaE8faC545936693aC917d5E7563);

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _name The name of strategy
    function initialize(address _vault, address _harvester,string memory _name) public initializer {
        address[] memory _wants = new address[](3);
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        _wants[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        _wants[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        super._initialize(
            _vault,
            _harvester,
            _name,
            _wants,
            0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C,
            0x8B55351ea358e5Eda371575B031ee24F462d503e
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
        _ratios[0] = ((ICToken(cDAI).balanceOf(curvePool) * (ICToken(cDAI).totalBorrows())) /
            ICToken(cDAI).totalSupply());
        _ratios[1] = ((ICToken(cUSDC).balanceOf(curvePool) * (ICToken(cDAI).totalBorrows())) /
            ICToken(cDAI).totalSupply());
        _ratios[2] = IERC20Upgradeable(_assets[2]).balanceOf(curvePool);
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

    /// @notice Add liquidity into curve pool
    /// @param _assets The asset list to add
    /// @param _amounts The amount list to add
    /// @return The amount of liquidity
    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        uint256 _amount = _amounts[2];
        IERC20Upgradeable(_assets[0]).safeApprove(cDAI, 0);
        IERC20Upgradeable(_assets[0]).safeApprove(cDAI, _amounts[0]);
        ICToken(cDAI).mint(_amounts[0]);
        uint256 _cDAIBalance = balanceOfToken(cDAI);
        IERC20Upgradeable(_assets[1]).safeApprove(cUSDC, 0);
        IERC20Upgradeable(_assets[1]).safeApprove(cUSDC, _amounts[1]);
        ICToken(cUSDC).mint(_amounts[1]);
        uint256 _cUSDCBalance = balanceOfToken(cUSDC);

        IERC20Upgradeable(cDAI).safeApprove(curvePool, 0);
        IERC20Upgradeable(cDAI).safeApprove(curvePool, _cDAIBalance);
        IERC20Upgradeable(cUSDC).safeApprove(curvePool, 0);
        IERC20Upgradeable(cUSDC).safeApprove(curvePool, _cUSDCBalance);
        IERC20Upgradeable(_assets[2]).safeApprove(curvePool, 0);
        IERC20Upgradeable(_assets[2]).safeApprove(curvePool, _amount);
        ICurveLiquidityPool(curvePool).add_liquidity([_cDAIBalance, _cUSDCBalance, _amount], 0);
        return balanceOfToken(lpToken);
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
        _isUsd = true;
        _usdValue =
            (ICurveLiquidityPool(curvePool).get_virtual_price() * balanceOfLpToken()) /
            decimalUnitOfToken(lpToken);
    }

    /// @notice Return the third party protocol's pool total assets in USD(1e18).
    function get3rdPoolAssets() external view override returns (uint256) {
        return
            (ICurveLiquidityPool(curvePool).get_virtual_price() *
                IERC20Upgradeable(lpToken).totalSupply()) / decimalUnitOfToken(lpToken);
    }

    /// @notice Remove liquidity from curve pool
    /// @param _removeLiquidity The amount of liquidity to remove
    /// @param _outputCode The code of output
    function curveRemoveLiquidity(uint256 _removeLiquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool(curvePool).remove_liquidity(
            _removeLiquidity,
            [uint256(0), uint256(0), uint256(0)]
        );
        uint256 _daiBalance = balanceOfToken(cDAI);
        if (_daiBalance > 0) {
            ICToken(cDAI).redeem(_daiBalance);
        }
        uint256 _usdcBalance = balanceOfToken(cUSDC);
        if (_usdcBalance > 0) {
            ICToken(cUSDC).redeem(_usdcBalance);
        }
    }
}
