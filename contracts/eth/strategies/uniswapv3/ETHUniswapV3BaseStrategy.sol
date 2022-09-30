// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "../ETHBaseClaimableStrategy.sol";
import "../../../external/uniswap/IUniswapV3.sol";
import "./../../../external/uniswapV3/INonfungiblePositionManager.sol";
import "./../../../external/uniswapV3/libraries/LiquidityAmounts.sol";
import "../../../utils/actions/UniswapV3LiquidityActionsMixin.sol";
import "./../../enums/ProtocolEnum.sol";
import 'hardhat/console.sol';
import "../../../utils/actions/AaveLendActionMixin.sol";
import "./../../../external/aave/ILendingPoolAddressesProvider.sol";
import "../../../external/aave/IPriceOracleGetter.sol";

/// @title ETHUniswapV3BaseStrategy
/// @author Bank of Chain Protocol Inc
abstract contract ETHUniswapV3BaseStrategy is ETHBaseClaimableStrategy, AaveLendActionMixin, IUniswapV3MintCallback, UniswapV3LiquidityActionsMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    address internal constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /// @param _baseThreshold The new base threshold
    event UniV3SetBaseThreshold(int24 _baseThreshold);

    /// @param _limitThreshold The new limit threshold
    event UniV3SetLimitThreshold(int24 _limitThreshold);

    /// @param _period The new period
    event UniV3SetPeriod(uint256 _period);

    /// @param _minTickMove The new minium tick to move
    event UniV3SetMinTickMove(int24 _minTickMove);

    /// @param _maxTwapDeviation The new max TWAP deviation
    event UniV3SetMaxTwapDeviation(int24 _maxTwapDeviation);

    /// @param _twapDuration The new max TWAP duration
    event UniV3SetTwapDuration(uint32 _twapDuration);

    int24 internal baseThreshold;
    int24 internal limitThreshold;
    int24 internal minTickMove;
    int24 internal maxTwapDeviation;
    int24 internal lastTick;
    int24 internal tickSpacing;
    uint256 internal period;
    uint256 internal lastTimestamp;
    uint32 internal twapDuration;
    address[] public realTokens;

    /// @param tokenId The tokenId of V3 LP NFT minted
    /// @param _tickLower The lower tick of the position in which to add liquidity
    /// @param _tickUpper The upper tick of the position in which to add liquidity
    struct MintInfo {
        uint256 tokenId;
        int24 tickLower;
        int24 tickUpper;
    }

    MintInfo internal baseMintInfo;
    MintInfo internal limitMintInfo;

    ILendingPoolAddressesProvider internal constant lendingPoolAddressesProvider = ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    IPriceOracleGetter internal priceOracleGetter;

    /// @notice Initialize this contract
    /// @param _vault The ETH vaults
    /// @param _name The name of strategy
    /// @param _baseThreshold The new base threshold
    /// @param _pool The uniswap V3 pool
    /// @param _limitThreshold The new limit threshold
    /// @param _period The new period
    /// @param _minTickMove The minium tick to move
    /// @param _maxTwapDeviation The max TWAP deviation
    /// @param _twapDuration The max TWAP duration
    function _initialize(
        address _vault,
        string memory _name,
        address _pool,
        int24 _baseThreshold,
        int24 _limitThreshold,
        uint256 _period,
        int24 _minTickMove,
        int24 _maxTwapDeviation,
        uint32 _twapDuration,
        int24 _tickSpacing
    ) internal {
        uniswapV3Initialize(_pool, _baseThreshold, _limitThreshold, _period, _minTickMove, _maxTwapDeviation, _twapDuration, _tickSpacing);
        address[] memory _wants = new address[](1);
        _wants[0] = token1;
        realTokens = new address[](2);
        realTokens[0] = token0;
        realTokens[1] = token1;
        __initLendConfigation(2, token1, token0);
        console.log('----------------lendingPoolAddressesProvider.getPriceOracle(): %s', lendingPoolAddressesProvider.getPriceOracle());
        priceOracleGetter = IPriceOracleGetter(lendingPoolAddressesProvider.getPriceOracle());
        super._initialize(_vault, uint16(ProtocolEnum.UniswapV3), _name, _wants);
    }

    /// @notice Initialize the status about uniswap V3
    /// @param _pool The uniswap V3 pool
    /// @param _baseThreshold The new base threshold
    /// @param _limitThreshold The new limit threshold
    /// @param _period The new period
    /// @param _minTickMove The minium tick to move
    /// @param _maxTwapDeviation The max TWAP deviation
    /// @param _twapDuration The max TWAP duration
    /// @param _tickSpacing The number of tickSpacing
    function uniswapV3Initialize(
        address _pool,
        int24 _baseThreshold,
        int24 _limitThreshold,
        uint256 _period,
        int24 _minTickMove,
        int24 _maxTwapDeviation,
        uint32 _twapDuration,
        int24 _tickSpacing
    ) internal {
        super._initializeUniswapV3Liquidity(_pool);
        baseThreshold = _baseThreshold;
        limitThreshold = _limitThreshold;
        period = _period;
        minTickMove = _minTickMove;
        maxTwapDeviation = _maxTwapDeviation;
        twapDuration = _twapDuration;
        tickSpacing = _tickSpacing;
    }

    /// @inheritdoc ETHBaseStrategy
    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    /// @notice Gets the statuses about uniswap V3
    /// @return _baseThreshold The new base threshold
    /// @return _limitThreshold The new limit threshold
    /// @return _minTickMove The minium tick to move
    /// @return _maxTwapDeviation The max TWAP deviation
    /// @return _lastTick The last tick
    /// @return _tickSpacing The number of tickSpacing
    /// @return _period The new period
    /// @return _lastTimestamp The timestamp of last action
    /// @return _twapDuration The max TWAP duration
    function getStatus() public view returns (int24 _baseThreshold, int24 _limitThreshold, int24 _minTickMove, int24 _maxTwapDeviation, int24 _lastTick, int24 _tickSpacing, uint256 _period, uint256 _lastTimestamp, uint32 _twapDuration) {
        return (baseThreshold, limitThreshold, minTickMove, maxTwapDeviation, lastTick, tickSpacing, period, lastTimestamp, twapDuration);
    }

    /// @notice Gets the info of LP V3 NFT minted
    function getMintInfo() public view returns (uint256 baseTokenId, int24 baseTickUpper, int24 baseTickLower, uint256 limitTokenId, int24 limitTickUpper, int24 limitTickLower) {
        return (baseMintInfo.tokenId, baseMintInfo.tickUpper, baseMintInfo.tickLower, limitMintInfo.tokenId, limitMintInfo.tickUpper, limitMintInfo.tickLower);
    }

    /// @inheritdoc ETHBaseStrategy
    function getWantsInfo() public view override virtual returns (address[] memory _assets, uint256[] memory _ratios) {
        _assets = wants;
        //        int24 _tickLower = baseMintInfo.tickLower;
        //        int24 _tickUpper = baseMintInfo.tickUpper;
        //        (, int24 _tick,,,,,) = pool.slot0();
        //        if (baseMintInfo.tokenId == 0 || shouldRebalance(_tick)) {
        //            (,, _tickLower, _tickUpper) = getSpecifiedRangesOfTick(_tick);
        //        }
        //
        //        _ratios = new uint256[](2);
        //        (_ratios[0], _ratios[1]) = getAmountsForLiquidity(_tickLower, _tickUpper, pool.liquidity());
        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
    }

    /// @inheritdoc ETHBaseStrategy
    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory _outputsInfo){
        _outputsInfo = new OutputInfo[](1);
        _outputsInfo[0].outputTokens = wants;
    }

    /// @notice Gets the specifie ranges of `_tick`
    /// @param _tick The input number of tick
    /// @return _tickFloor The nearest tick which LTE `_tick`
    /// @return _tickCeil The nearest tick which GTE `_tick`
    /// @return _tickLower  `_tickFloor` subtrace `baseThreshold`
    /// @return _tickUpper  `_tickFloor` add `baseThreshold`
    function getSpecifiedRangesOfTick(int24 _tick) internal view returns (int24 _tickFloor, int24 _tickCeil, int24 _tickLower, int24 _tickUpper) {
        // Rounds _tick down towards negative infinity so that it"s a multiple of `tickSpacing`.
        int24 _tickSpacing = tickSpacing;
        int24 _compressed = _tick / _tickSpacing;
        if (_tick < 0 && _tick % _tickSpacing != 0) _compressed--;
        _tickFloor = _compressed * _tickSpacing;
        _tickCeil = _tickFloor + _tickSpacing;
        _tickLower = _tickFloor - baseThreshold;
        _tickUpper = _tickCeil + baseThreshold;
    }

    /// @notice Gets the amounts for the specified liquidity
    /// @param _tickLower  The specified lower tick
    /// @param _tickUpper  The specified upper tick
    /// @param _liquidity The liquidity being valued
    /// @return The amount of token0
    /// @return The amount of token1
    function getAmountsForLiquidity(int24 _tickLower, int24 _tickUpper, uint128 _liquidity) internal view returns (uint256, uint256) {
        (uint160 _sqrtPriceX96, , , , , ,) = pool.slot0();
        (uint256 _amount0, uint256 _amount1) = LiquidityAmounts.getAmountsForLiquidity(
            _sqrtPriceX96, TickMath.getSqrtRatioAtTick(_tickLower), TickMath.getSqrtRatioAtTick(_tickUpper), _liquidity
        );
        return (_amount0, _amount1);
    }

    /// @inheritdoc ETHBaseStrategy
    function getPositionDetail() public view virtual override returns (address[] memory _tokens, uint256[] memory _amounts, bool _isETH, uint256 _ethValue) {
//        _tokens = realTokens;
//        _amounts = new uint256[](2);
        uint256 amounts0 = balanceOfToken(token0);
        uint256 amounts1 = balanceOfToken(token1);
        (uint256 _amount0, uint256 _amount1) = balanceOfPoolWants(baseMintInfo);
        amounts0 += _amount0;
        amounts1 += _amount1;
        (_amount0, _amount1) = balanceOfPoolWants(limitMintInfo);
        amounts0 += _amount0;
        amounts1 += _amount1;
        (uint256 _totalCollateralETH, uint256 _totalDebtETH, uint256 _availableBorrowsETH, uint256 _currentLiquidationThreshold, uint256 _ltv, uint256 _healthFactor) = borrowInfo();
//        console.log('----------------%d,%d', _totalCollateralETH, _totalDebtETH);
//        console.log('----------------%d,%d', _availableBorrowsETH, _currentLiquidationThreshold);
//        console.log('----------------%d,%d', _ltv, _healthFactor);
//        console.log('----------------%d,%d', amounts0, getCurrentBorrow());
//        console.log('----------------%d', priceOracleConsumer.usdcPriceInEth());

        amounts1 += _totalCollateralETH;
        console.log('---------getPositionDetail-------%d', priceOracleConsumer.usdcPriceInEth());
        console.log('---------getPositionDetail-------%d', priceOracleGetter.getAssetPrice(token0));
        _ethValue = amounts1 + amounts0.mul(priceOracleGetter.getAssetPrice(token0)).div(1e18) - getCurrentBorrow().mul(priceOracleGetter.getAssetPrice(token0)).div(1e18);
        _isETH = true;
    }

    /// @notice Gets the two tokens' balances of LP V3 NFT
    /// @param _mintInfo  The info of LP V3 NFT
    /// @return The amount of token0
    /// @return The amount of token1
    function balanceOfPoolWants(MintInfo memory _mintInfo) internal view returns (uint256, uint256) {
        if (_mintInfo.tickLower == 0 && _mintInfo.tickUpper == 0) return (0, 0);
        (uint128 liquidity, , ,uint128 tokensOwed0,uint128 tokensOwed1) = __position(_mintInfo.tickLower, _mintInfo.tickUpper);
        console.log('----------------balanceOfPoolWants tokensOwed0:%d tokensOwed1:%d', tokensOwed0, tokensOwed1);
        (uint256 amount0, uint256 amount1) = getAmountsForLiquidity(_mintInfo.tickLower, _mintInfo.tickUpper, liquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        console.log('----------------balanceOfPoolWants amount0:%d amount1:%d', amount0, amount1);
        return (amount0, amount1);
    }

    /// @inheritdoc ETHBaseStrategy
    function get3rdPoolAssets() external view override returns (uint256 totalAssets) {
        address _pool = IUniswapV3Factory(nonfungiblePositionManager.factory()).getPool(token0, token1, fee);
        totalAssets = queryTokenValueInETH(token0, IERC20Minimal(token0).balanceOf(_pool));
        totalAssets += queryTokenValueInETH(token1, IERC20Minimal(token1).balanceOf(_pool));
    }

    /// @inheritdoc ETHBaseClaimableStrategy
    function claimRewards() internal override virtual returns (bool _isWorth, address[] memory _assets, uint256[] memory _claimAmounts) {
        _poke(baseMintInfo.tickLower, baseMintInfo.tickUpper);
        _poke(limitMintInfo.tickLower, limitMintInfo.tickUpper);
        _assets = realTokens;
        _claimAmounts = new uint256[](2);
        if (baseMintInfo.tickLower != 0 || baseMintInfo.tickUpper != 0) {
            (uint256 _amount0, uint256 _amount1) = __poolCollectAll(baseMintInfo.tickLower, baseMintInfo.tickUpper);
            _claimAmounts[0] += _amount0;
            _claimAmounts[1] += _amount1;
        }

        if (limitMintInfo.tickLower != 0 || limitMintInfo.tickUpper != 0) {
            (uint256 _amount0, uint256 _amount1) = __poolCollectAll(limitMintInfo.tickLower, limitMintInfo.tickUpper);
            _claimAmounts[0] += _amount0;
            _claimAmounts[1] += _amount1;
        }
    }

    /// @inheritdoc ETHBaseClaimableStrategy
    function swapRewardsToWants() internal virtual override returns (address[] memory _wantTokens, uint256[] memory _wantAmounts){}

    /// @inheritdoc ETHBaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal virtual override {
        uint256 collateralAmount = _amounts[0].mul(2).div(3);
        __addCollaternal(collateralAmount);
        console.log('===============depositTo3rdPool========priceOracleGetter.getAssetPrice: %d========', _amounts[0].mul(1e6).div(3).div(priceOracleGetter.getAssetPrice(token0)));
        console.log('===============depositTo3rdPool========priceOracleConsumer.valueInTargetToken: %d========', priceOracleConsumer.valueInTargetToken(token1, _amounts[0].div(3), token0));

        uint256 borrowAmount = _amounts[0].mul(1e6).div(3).div(priceOracleGetter.getAssetPrice(token0));
        __borrow(borrowAmount);
        (, int24 _tick,,,,,) = pool.slot0();
        if (baseMintInfo.tickLower == 0 && baseMintInfo.tickUpper == 0) {

            // Mint new base and limit position
            (
            int24 _tickFloor,
            int24 _tickCeil,
            int24 _tickLower,
            int24 _tickUpper
            ) = getSpecifiedRangesOfTick(_tick);
            uint256 _balance0 = balanceOfToken(token0);
            uint256 _balance1 = balanceOfToken(token1);
            if (_balance0 > 0 && _balance1 > 0) {
                mintNewPosition(
                    _tickLower,
                    _tickUpper,
                    _balance0,
                    _balance1,
                    true
                );
                _balance0 = balanceOfToken(token0);
                _balance1 = balanceOfToken(token1);
            }

            if (_balance0 > 0 || _balance1 > 0) {
                // Place bid or ask order on Uniswap depending on which token is left
                if (
                    getLiquidityForAmounts(_tickFloor - limitThreshold, _tickFloor, _balance0, _balance1) >
                    getLiquidityForAmounts(_tickCeil, _tickCeil + limitThreshold, _balance0, _balance1)
                ) {
                    mintNewPosition(_tickFloor - limitThreshold, _tickFloor, _balance0, _balance1, false);
                } else {
                    mintNewPosition(_tickCeil, _tickCeil + limitThreshold, _balance0, _balance1, false);
                }
            }

            lastTimestamp = block.timestamp;
            lastTick = _tick;
        } else {
            if (shouldRebalance(_tick)) {
                rebalance(_tick);
            } else {
                (uint160 sqrtRatioX96, , , , , ,) = pool.slot0();
                uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(sqrtRatioX96, TickMath.getSqrtRatioAtTick(baseMintInfo.tickLower), TickMath.getSqrtRatioAtTick(baseMintInfo.tickUpper), balanceOfToken(token0), balanceOfToken(token1));
                __poolMint(baseMintInfo.tickLower, baseMintInfo.tickUpper, liquidity);
            }
        }
    }

    /// @inheritdoc ETHBaseStrategy
    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares, uint256 _outputCode) internal virtual override {
        console.log('withdrawFrom3rdPool _withdrawShares:%d, _totalShares:%d, _outputCode:%d', _withdrawShares, _totalShares, _outputCode);
        _poke(baseMintInfo.tickLower, baseMintInfo.tickUpper);
        _poke(limitMintInfo.tickLower, limitMintInfo.tickUpper);
        withdraw(baseMintInfo.tickLower, baseMintInfo.tickUpper, _withdrawShares, _totalShares);
        withdraw(limitMintInfo.tickLower, limitMintInfo.tickUpper, _withdrawShares, _totalShares);
        uint256 currentBorrow = getCurrentBorrow();
        console.log('withdrawFrom3rdPool balanceOfToken(token0):%d, balanceOfToken(token1):%d, currentBorrow:%d', balanceOfToken(token0), balanceOfToken(token1), currentBorrow);
        if (currentBorrow > balanceOfToken(token0)) {
            IERC20(token1).approve(UNISWAP_V3_ROUTER, type(uint256).max);
            IUniswapV3(UNISWAP_V3_ROUTER).exactOutputSingle(IUniswapV3.ExactOutputSingleParams(token1, token0, 500, address(this), block.timestamp, currentBorrow - balanceOfToken(token0), type(uint256).max, 0));
        }
        console.log('withdrawFrom3rdPool balanceOfToken(token0):%d, balanceOfToken(token1):%d, currentBorrow:%d', balanceOfToken(token0), balanceOfToken(token1), currentBorrow);
        __repay(currentBorrow);
        if (balanceOfToken(token0) > 0) {
            IERC20(token0).approve(UNISWAP_V3_ROUTER, type(uint256).max);
            IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(IUniswapV3.ExactInputSingleParams(token0, token1, 500, address(this), block.timestamp, balanceOfToken(token0), 0, 0));
        }
        (uint256 _totalCollateralETH, uint256 _totalDebtETH, uint256 _availableBorrowsETH, uint256 _currentLiquidationThreshold, uint256 _ltv, uint256 _healthFactor) = borrowInfo();
        __removeCollaternal(_totalCollateralETH);
        if (_withdrawShares == _totalShares) {
            delete baseMintInfo;
            delete limitMintInfo;
        }
    }

    function withdraw(int24 _tickLower, int24 _tickUpper, uint256 _withdrawShares, uint256 _totalShares) internal {
        uint128 _withdrawLiquidity = uint128(balanceOfLpToken(_tickLower, _tickUpper) * _withdrawShares / _totalShares);
        if (_withdrawLiquidity <= 0) return;
        if (_withdrawShares == _totalShares) {
            __poolPurge(_tickLower, _tickUpper, type(uint128).max, 0, 0);
        } else {
            removeLiquidity(_tickLower, _tickUpper, _withdrawLiquidity);
        }
    }

    function removeLiquidity(int24 _tickLower, int24 _tickUpper, uint128 _liquidity) internal {
        // remove _liquidity
        (uint256 amount0, uint256 amount1) = pool.burn(_tickLower, _tickUpper, _liquidity);
        if (amount0 > 0 || amount1 > 0) {
            __poolCollect(_tickLower, _tickUpper, uint128(amount0), uint128(amount1));
        }
    }

    function balanceOfLpToken(int24 _tickLower, int24 _tickUpper) public view returns (uint128) {
        if (_tickLower == 0 && _tickUpper == 0) return 0;
        (uint128 liquidity, , , ,) = __position(_tickLower, _tickUpper);
        return liquidity;
    }

    function rebalanceByKeeper() external nonReentrant isKeeper {
        (, int24 _tick,,,,,) = pool.slot0();
        require(shouldRebalance(_tick), "NR");
        rebalance(_tick);
    }

    function borrowRebalance() external nonReentrant isKeeper {
        console.log('---------getPositionDetail-------%d', priceOracleGetter.getAssetPrice(token0));
        (uint256 _totalCollateralETH, uint256 _totalDebtETH, uint256 _availableBorrowsETH, uint256 _currentLiquidationThreshold, uint256 _ltv, uint256 _healthFactor) = borrowInfo();
        console.log('----------------%d,%d', _totalCollateralETH, _totalDebtETH);
        console.log('----------------%d,%d', _availableBorrowsETH, _currentLiquidationThreshold);
        console.log('----------------%d,%d', _ltv, _healthFactor);
        console.log('----------------%d', getCurrentBorrow());

        if (_totalDebtETH.mul(10000).div(_totalCollateralETH) >= 7500) {
            uint256 newTotalDebtETH = _totalDebtETH.mul(5000).div(_totalDebtETH.mul(10000).div(_totalCollateralETH));
            console.log('borrowRebalance priceOracleGetter.getAssetPrice:%d', (_totalDebtETH - newTotalDebtETH).mul(1e6).div(priceOracleGetter.getAssetPrice(token0)));
            console.log('borrowRebalance priceOracleGetter.getAssetPrice:%d', priceOracleConsumer.valueInTargetToken(token1, (_totalDebtETH - newTotalDebtETH), token0));
            uint256 repayAmount = (_totalDebtETH - newTotalDebtETH).mul(1e6).div(priceOracleGetter.getAssetPrice(token0));
            burnAll();
            console.log('borrowRebalance balanceOfToken(token0):%d, balanceOfToken(token1):%d, repayAmount:%d', balanceOfToken(token0), balanceOfToken(token1), repayAmount);
            if (balanceOfToken(token0) >= repayAmount) {
                console.log('borrowRebalance before getCurrentBorrow():%d', getCurrentBorrow());
                __repay(repayAmount);
                console.log('borrowRebalance after getCurrentBorrow():%d', getCurrentBorrow());
                console.log('borrowRebalance balanceOfToken(token0):%d, balanceOfToken(token1):%d, >=', balanceOfToken(token0), balanceOfToken(token1));
            } else {
                IERC20(token1).approve(UNISWAP_V3_ROUTER, type(uint256).max);
                IUniswapV3(UNISWAP_V3_ROUTER).exactOutputSingle(IUniswapV3.ExactOutputSingleParams(token1, token0, 500, address(this), block.timestamp, repayAmount - balanceOfToken(token0), type(uint256).max, 0));
                __repay(repayAmount);
                console.log('borrowRebalance balanceOfToken(token0):%d, balanceOfToken(token1):%d, else', balanceOfToken(token0), balanceOfToken(token1));
            }
        }
        if (_totalDebtETH.mul(10000).div(_totalCollateralETH) <= 3750) {
            uint256 newTotalDebtETH = _totalDebtETH.mul(5000).div(_totalDebtETH.mul(10000).div(_totalCollateralETH));
            console.log('borrowRebalance priceOracleGetter.getAssetPrice:%d', (newTotalDebtETH - _totalDebtETH).mul(1e6).div(priceOracleGetter.getAssetPrice(token0)));
            console.log('borrowRebalance priceOracleGetter.getAssetPrice:%d', priceOracleConsumer.valueInTargetToken(token1, (newTotalDebtETH - _totalDebtETH), token0));
            uint256 borrowAmount = (newTotalDebtETH - _totalDebtETH).mul(1e6).div(priceOracleGetter.getAssetPrice(token0));
            console.log('borrowRebalance borrowAmount:%d', borrowAmount);
            __borrow(borrowAmount);
        }
        (_totalCollateralETH, _totalDebtETH, _availableBorrowsETH, _currentLiquidationThreshold, _ltv, _healthFactor) = borrowInfo();
        console.log('----------------%d,%d', _totalCollateralETH, _totalDebtETH);
        console.log('----------------%d,%d', _availableBorrowsETH, _currentLiquidationThreshold);
        console.log('----------------%d,%d', _ltv, _healthFactor);
        console.log('----------------%d', getCurrentBorrow());
        (, int24 _tick,,,,,) = pool.slot0();
        rebalance(_tick);
    }

    function burnAll() internal {
        harvest();
        // Withdraw all current liquidity
        uint128 _baseLiquidity = balanceOfLpToken(baseMintInfo.tickLower, baseMintInfo.tickUpper);
        if (_baseLiquidity > 0) {
            __poolPurge(baseMintInfo.tickLower, baseMintInfo.tickUpper, type(uint128).max, 0, 0);
            delete baseMintInfo;
        }

        uint128 _limitLiquidity = balanceOfLpToken(limitMintInfo.tickLower, limitMintInfo.tickUpper);
        if (_limitLiquidity > 0) {
            __poolPurge(limitMintInfo.tickLower, limitMintInfo.tickUpper, type(uint128).max, 0, 0);
            delete limitMintInfo;
        }
    }

    /// @notice Rebalance the position of this strategy
    /// @param _tick The new tick to invest
    function rebalance(int24 _tick) internal {
        harvest();
        // Withdraw all current liquidity
        uint128 _baseLiquidity = balanceOfLpToken(baseMintInfo.tickLower, baseMintInfo.tickUpper);
        if (_baseLiquidity > 0) {
            __poolPurge(baseMintInfo.tickLower, baseMintInfo.tickUpper, type(uint128).max, 0, 0);
            delete baseMintInfo;
        }

        uint128 _limitLiquidity = balanceOfLpToken(limitMintInfo.tickLower, limitMintInfo.tickUpper);
        if (_limitLiquidity > 0) {
            __poolPurge(limitMintInfo.tickLower, limitMintInfo.tickUpper, type(uint128).max, 0, 0);
            delete limitMintInfo;
        }

        uint256 _balance0 = balanceOfToken(token0);
        uint256 _balance1 = balanceOfToken(token1);
        if (_baseLiquidity <= 0 && _limitLiquidity <= 0 && _balance0 <= 0 && _balance1 <= 0) return;

        // Mint new base and limit position
        (int24 _tickFloor, int24 _tickCeil, int24 _tickLower, int24 _tickUpper) = getSpecifiedRangesOfTick(_tick);
        if (_balance0 > 0 && _balance1 > 0) {
            mintNewPosition(_tickLower, _tickUpper, _balance0, _balance1, true);
            _balance0 = balanceOfToken(token0);
            _balance1 = balanceOfToken(token1);
        }

        if (_balance0 > 0 || _balance1 > 0) {
            // Place bid or ask order on Uniswap depending on which token is left
            if (getLiquidityForAmounts(_tickFloor - limitThreshold, _tickFloor, _balance0, _balance1) > getLiquidityForAmounts(_tickCeil, _tickCeil + limitThreshold, _balance0, _balance1)) {
                mintNewPosition(_tickFloor - limitThreshold, _tickFloor, _balance0, _balance1, false);
            } else {
                mintNewPosition(_tickCeil, _tickCeil + limitThreshold, _balance0, _balance1, false);
            }
        }
        lastTimestamp = block.timestamp;
        lastTick = _tick;
    }

    /// @notice Check if rebalancing is possible
    /// @param _tick The tick to check
    /// @return Returns 'true' if it should rebalance, otherwise return 'false'
    function shouldRebalance(int24 _tick) public view returns (bool) {
        // check enough time has passed
        if (block.timestamp < lastTimestamp + period) {
            return false;
        }

        // check price has moved enough
        if ((_tick > lastTick ? _tick - lastTick : lastTick - _tick) < minTickMove) {
            return false;
        }

        // check price near _twap
        int24 _twap = getTwap();
        int24 _twapDeviation = _tick > _twap ? _tick - _twap : _twap - _tick;
        if (_twapDeviation > maxTwapDeviation) {
            return false;
        }

        // check price not too close to boundary
        int24 _maxThreshold = baseThreshold > limitThreshold ? baseThreshold : limitThreshold;
        if (_tick < TickMath.MIN_TICK + _maxThreshold + tickSpacing || _tick > TickMath.MAX_TICK - _maxThreshold - tickSpacing) {
            return false;
        }

        //        (, , int24 _tickLower, int24 _tickUpper) = getSpecifiedRangesOfTick(_tick);
        //        if (baseMintInfo.tokenId != 0 && _tickLower == baseMintInfo.tickLower && _tickUpper == baseMintInfo.tickUpper) {
        //            return false;
        //        }

        return true;
    }

    /// @notice Gets the liquidity for the two amounts
    /// @param _tickLower  The specified lower tick
    /// @param _tickUpper  The specified upper tick
    /// @param _amount0 The amount of token0
    /// @param _amount1 The amount of token1
    /// @return The liquidity being valued
    function getLiquidityForAmounts(int24 _tickLower, int24 _tickUpper, uint256 _amount0, uint256 _amount1) public view returns (uint128) {
        (uint160 _sqrtPriceX96, , , , , ,) = pool.slot0();
        return LiquidityAmounts.getLiquidityForAmounts(_sqrtPriceX96, TickMath.getSqrtRatioAtTick(_tickLower), TickMath.getSqrtRatioAtTick(_tickUpper), _amount0, _amount1);
    }

    /// @notice Fetches time-weighted average price in ticks from Uniswap pool.
    function getTwap() public view returns (int24) {
        uint32[] memory _secondsAgo = new uint32[](2);
        _secondsAgo[0] = twapDuration;
        _secondsAgo[1] = 0;

        (int56[] memory _tickCumulatives,) = pool.observe(_secondsAgo);
        return int24((_tickCumulatives[1] - _tickCumulatives[0]) / int32(twapDuration));
    }

    /// @notice Mints a new uniswap V3 position, receiving an nft as a receipt
    /// @param _tickLower The lower tick of the new position in which to add liquidity
    /// @param _tickUpper The upper tick of the new position in which to add liquidity
    /// @param _amount0Desired The amount of token0 desired to invest
    /// @param _amount1Desired The amount of token1 desired to invest
    /// @param _base The boolean flag to start base mint,
    ///     'true' to base mint,'false' to limit mint
    /// @return _tokenId The ID of the token that represents the minted position
    /// @return _liquidity The amount of liquidity for this new position minted
    /// @return _amount0 The amount of token0 that was paid to mint the given amount of liquidity
    /// @return _amount1 The amount of token1 that was paid to mint the given amount of liquidity
    function mintNewPosition(
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _amount0Desired,
        uint256 _amount1Desired,
        bool _base
    ) internal returns (
        uint256 _tokenId,
        uint128 _liquidity,
        uint256 _amount0,
        uint256 _amount1
    )
    {
        (uint160 sqrtRatioX96, , , , , ,) = pool.slot0();
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(sqrtRatioX96, TickMath.getSqrtRatioAtTick(_tickLower), TickMath.getSqrtRatioAtTick(_tickUpper), _amount0Desired, _amount1Desired);
        (_tokenId, _liquidity, _amount0, _amount1) = __poolMint(_tickLower, _tickUpper, liquidity);
        if (_base) {
            baseMintInfo = MintInfo({tokenId : _tokenId, tickLower : _tickLower, tickUpper : _tickUpper});
        } else {
            limitMintInfo = MintInfo({tokenId : _tokenId, tickLower : _tickLower, tickUpper : _tickUpper});
        }
    }

    function _poke(int24 tickLower, int24 tickUpper) internal {
        (uint128 liquidity, , , , ) = __position(tickLower, tickUpper);
        if (liquidity > 0) {
            pool.burn(tickLower, tickUpper, 0);
        }
    }

    /// @notice Check the Validity of `_threshold`
    function _checkThreshold(int24 _threshold) internal view {
        require(_threshold > 0 && _threshold <= TickMath.MAX_TICK && _threshold % tickSpacing == 0, "TE");
    }

    /// @notice Sets `baseThreshold` state variable
    /// Requirements: only vault manager  can call
    function setBaseThreshold(int24 _baseThreshold) external isVaultManager {
        _checkThreshold(_baseThreshold);
        baseThreshold = _baseThreshold;
        emit UniV3SetBaseThreshold(_baseThreshold);
    }

    /// @notice Sets `limitThreshold` state variable
    /// Requirements: only vault manager  can call
    function setLimitThreshold(int24 _limitThreshold) external isVaultManager {
        _checkThreshold(_limitThreshold);
        limitThreshold = _limitThreshold;
        emit UniV3SetLimitThreshold(_limitThreshold);
    }

    /// @notice Sets `period` state variable
    /// Requirements: only vault manager  can call
    function setPeriod(uint256 _period) external isVaultManager {
        period = _period;
        emit UniV3SetPeriod(_period);
    }

    /// @notice Sets `minTickMove` state variable
    /// Requirements: only vault manager  can call
    function setMinTickMove(int24 _minTickMove) external isVaultManager {
        require(_minTickMove >= 0, "MINE");
        minTickMove = _minTickMove;
        emit UniV3SetMinTickMove(_minTickMove);
    }

    /// @notice Sets `maxTwapDeviation` state variable
    /// Requirements: only vault manager  can call
    function setMaxTwapDeviation(int24 _maxTwapDeviation) external isVaultManager {
        require(_maxTwapDeviation >= 0, "MAXE");
        maxTwapDeviation = _maxTwapDeviation;
        emit UniV3SetMaxTwapDeviation(_maxTwapDeviation);
    }

    /// @notice Sets `twapDuration` state variable
    /// Requirements: only vault manager  can call
    function setTwapDuration(uint32 _twapDuration) external isVaultManager {
        require(_twapDuration > 0, "TWAPE");
        twapDuration = _twapDuration;
        emit UniV3SetTwapDuration(_twapDuration);
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        console.log('----------------uniswapV3MintCallback amount0:%d amount1:%d', amount0, amount1);
        if (amount0 > 0) IERC20Upgradeable(token0).safeTransfer(msg.sender, amount0);
        if (amount1 > 0) IERC20Upgradeable(token1).safeTransfer(msg.sender, amount1);
    }
}
