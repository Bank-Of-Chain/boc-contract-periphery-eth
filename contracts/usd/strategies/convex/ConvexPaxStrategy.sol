// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexBaseStrategy.sol";
import "../../../external/compound/ICToken.sol";
import "../../../external/curve/ICurveLiquidityPool.sol";
import "../../../external/curve/ICurveLiquidityCustomPool.sol";
import "../../../external/yearn/IYearnVault.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title ConvexPaxStrategy
/// @notice Investment strategy for investing stablecoins to Pax via Convex 
/// @author Bank of Chain Protocol Inc
contract ConvexPaxStrategy is Initializable, ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant PAX = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address private constant YC_DAI = 0x99d1Fa417f94dcD62BfE781a1213c092a47041Bc;
    address private constant YC_USDC = 0x9777d7E2b60bB01759D0E2f8be2095df444cb07E;
    address private constant YC_USDT = 0x1bE5d71F2dA660BFdee8012dDc58D024448A0A59;

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _name The name of strategy
    function initialize(address _vault, address _harvester,string memory _name) public initializer {
        address[] memory _wants = new address[](4);
        _wants[0] = DAI;
        _wants[1] = USDC;
        _wants[2] = USDT;
        _wants[3] = PAX;
        super._initialize(
            _vault,
            _harvester,
            _name,
            _wants,
            0x06364f10B501e868329afBc005b3492902d6C763,
            0xe3DaafC8C14147d5B4A7a56F0BfdED240158e51e
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
        ICurveLiquidityCustomPool curvePoolContract = ICurveLiquidityCustomPool(curvePool);
        _ratios[0] =
            IYearnVault(YC_DAI).getPricePerFullShare() *
            curvePoolContract.balances(int128(0));
        _ratios[1] =
            IYearnVault(YC_USDC).getPricePerFullShare() *
            curvePoolContract.balances(int128(1));
        _ratios[2] =
            IYearnVault(YC_USDT).getPricePerFullShare() *
            curvePoolContract.balances(int128(2));
        _ratios[3] = curvePoolContract.balances(int128(3)) * 1e18;
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

    /// @notice Add liquidity into curve pool
    /// @param _assets The asset list to add
    /// @param _amounts The amount list to add
    /// @return The amount of liquidity
    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        uint256[] memory _depositAmounts = new uint256[](4);
        address[] memory _yTokens = new address[](4);
        _yTokens[0] = YC_DAI;
        _yTokens[1] = YC_USDC;
        _yTokens[2] = YC_USDT;
        _yTokens[3] = PAX;
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] > 0) {
                // The last coin, PAX, does not require investment into yearn
                if (_assets.length - 1 != i) {
                    IERC20Upgradeable(_assets[i]).safeApprove(_yTokens[i], 0);
                    IERC20Upgradeable(_assets[i]).safeApprove(_yTokens[i], _amounts[i]);
                    IYearnVault(_yTokens[i]).deposit(_amounts[i]);
                }
                _depositAmounts[i] = balanceOfToken(_yTokens[i]);
                IERC20Upgradeable(_yTokens[i]).safeApprove(curvePool, 0);
                IERC20Upgradeable(_yTokens[i]).safeApprove(curvePool, _depositAmounts[i]);
            }
        }
        ICurveLiquidityPool(curvePool).add_liquidity(
            [_depositAmounts[0], _depositAmounts[1], _depositAmounts[2], _depositAmounts[3]],
            0
        );
        return balanceOfToken(lpToken);
    }

    /// @notice Remove liquidity from curve pool
    /// @param _removeLiquidity The amount of liquidity to remove
    /// @param _outputCode The code of output
    function curveRemoveLiquidity(uint256 _removeLiquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool(curvePool).remove_liquidity(
            _removeLiquidity,
            [uint256(0), uint256(0), uint256(0), uint256(0)]
        );
        uint256 _yDaiBalance = balanceOfToken(YC_DAI);
        if (_yDaiBalance > 0) {
            IYearnVault(YC_DAI).withdraw(_yDaiBalance);
        }
        uint256 _yUsdcBalance = balanceOfToken(YC_USDC);
        if (_yUsdcBalance > 0) {
            IYearnVault(YC_USDC).withdraw(_yUsdcBalance);
        }
        uint256 _yUsdtBalance = balanceOfToken(YC_USDT);
        if (_yUsdtBalance > 0) {
            IYearnVault(YC_USDT).withdraw(_yUsdtBalance);
        }
        uint256 _yTusdBalance = balanceOfToken(PAX);
    }
}
