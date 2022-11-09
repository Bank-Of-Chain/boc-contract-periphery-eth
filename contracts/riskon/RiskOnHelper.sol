// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol';
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "./../external/uniswap/IUniswapV3.sol";
import './../external/uniswapv3/INonfungiblePositionManager.sol';
import './../external/uniswapv3/libraries/LiquidityAmounts.sol';
import './../enums/ProtocolEnum.sol';
import 'hardhat/console.sol';
import "../utils/actions/AaveLendActionMixin.sol";
import "../utils/actions/UniswapV3LiquidityActionsMixin.sol";
import "../external/aave/ILendingPoolAddressesProvider.sol";
import "../external/aave/IPriceOracleGetter.sol";
import "../../library/RiskOnConstant.sol";

/// @title RiskOnHelper
/// @author Bank of Chain Protocol Inc
contract RiskOnHelper is Initializable {
    using SafeMath for uint256;

    uint256 internal constant AAVE_BASE_CURRENCY_UNIT = 10 ** 8;
    uint256 internal constant VALUE_INTERPRETER_PRICE_BASE_UNIT = 10 ** 18;

    ILendingPoolAddressesProvider internal constant lendingPoolAddressesProvider = ILendingPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    /// @dev The price oracle inteface
    IPriceOracleGetter public priceOracleGetter;

    /// @dev The uniswap V3 pool inteface
    IUniswapV3Pool public pool;

    /// @notice Initialize this contract
    function initialize() public initializer {
        priceOracleGetter = IPriceOracleGetter(lendingPoolAddressesProvider.getPriceOracle());
    }

    /// @notice Gets the specifie ranges of `_tick`
    /// @param _tick The input number of tick
    /// @param _tickSpacing The tick spacing
    /// @param _baseThreshold The base threshold
    /// @return _tickFloor The nearest tick which LTE `_tick`
    /// @return _tickCeil The nearest tick which GTE `_tick`
    /// @return _tickLower  `_tickFloor` subtrace `baseThreshold`
    /// @return _tickUpper  `_tickFloor` add `baseThreshold`
    function getSpecifiedRangesOfTick(int24 _tick, int24 _tickSpacing, int24 _baseThreshold) public pure returns (int24 _tickFloor, int24 _tickCeil, int24 _tickLower, int24 _tickUpper) {
        int24 _compressed = _tick / _tickSpacing;
        if (_tick < 0 && _tick % _tickSpacing != 0) _compressed--;
        _tickFloor = _compressed * _tickSpacing;
        _tickCeil = _tickFloor + _tickSpacing;
        _tickLower = _tickFloor - _baseThreshold;
        _tickUpper = _tickCeil + _baseThreshold;
    }

    /// @notice Fetches time-weighted average price in ticks from Uniswap pool.
    function getTwap(address _pool, uint32 _twapDuration) public view returns (int24) {
        uint32[] memory _secondsAgo = new uint32[](2);
        _secondsAgo[0] = _twapDuration;
        _secondsAgo[1] = 0;

        (int56[] memory _tickCumulatives,) = IUniswapV3Pool(_pool).observe(_secondsAgo);
        return int24((_tickCumulatives[1] - _tickCumulatives[0]) / int32(_twapDuration));
    }

    function borrowInfo(address _account) public view returns (
        uint256 _totalCollateralBase,
        uint256 _totalDebtBase,
        uint256 _availableBorrowsBase,
        uint256 _currentLiquidationThreshold,
        uint256 _ltv,
        uint256 _healthFactor
    )
    {
        return ILendingPool(RiskOnConstant.LENDING_POOL).getUserAccountData(_account);
    }

    function getTotalCollateralTokenAmount(address _account, address _collateralToken) public view returns (uint256 _totalCollateralToken) {
        (uint256 _totalCollateralBase,,,,,) = borrowInfo(_account);
        _totalCollateralToken = _totalCollateralBase.mul(decimalUnitOfToken(_collateralToken)).div(priceOracleGetter.getAssetPrice(_collateralToken));
    }

    function getAToken(address _asset) public view returns (address) {
        return ILendingPool(RiskOnConstant.LENDING_POOL).getReserveData(_asset).aTokenAddress;
    }

    function getDebtToken(address _borrowToken, uint256 _interestRateMode) public view returns (address) {
        DataTypes.ReserveData memory reserveData = ILendingPool(RiskOnConstant.LENDING_POOL).getReserveData(_borrowToken);
        if (_interestRateMode == 1) {
            return reserveData.stableDebtTokenAddress;
        } else {
            return reserveData.variableDebtTokenAddress;
        }
    }

    function getCurrentBorrow(address _borrowToken, uint256 _interestRateMode, address _account) public view returns (uint256) {
        return IERC20(getDebtToken(_borrowToken, _interestRateMode)).balanceOf(_account);
    }

    function calcCanonicalAssetValue(address _baseAsset, uint256 _amount, address _quoteAsset) public view returns (uint256) {
        address[] memory assets = new address[](2);
        assets[0] = _baseAsset;
        assets[1] = _quoteAsset;
        uint256[] memory prices = priceOracleGetter.getAssetsPrices(assets);
        return _amount.mul(prices[0]).mul(decimalUnitOfToken(_quoteAsset)).div(prices[1]).div(decimalUnitOfToken(_baseAsset));
    }

    function calcAaveBaseCurrencyValueInAsset(uint256 _amount, address _quoteAsset) public view returns (uint256) {
        uint256 price = priceOracleGetter.getAssetPrice(_quoteAsset);
        return _amount.mul(decimalUnitOfToken(_quoteAsset)).div(price);
    }

    function decimalUnitOfToken(address _token) internal view returns (uint256){
        return 10 ** IERC20MetadataUpgradeable(_token).decimals();
    }
}
