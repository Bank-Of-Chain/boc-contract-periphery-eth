// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol';
import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";
import '../../../external/uniswapV3/INonfungiblePositionManager.sol';
import '../../../external/uniswapV3/libraries/LiquidityAmounts.sol';
import '../../../utils/actions/UniswapV3LiquidityActionsMixin.sol';
import './../../enums/ProtocolEnum.sol';
import 'hardhat/console.sol';

abstract contract UniswapV3BaseStrategy is BaseClaimableStrategy, UniswapV3LiquidityActionsMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event UniV3SetBaseThreshold(int24 _baseThreshold);
    event UniV3SetLimitThreshold(int24 _limitThreshold);
    event UniV3SetPeriod(uint256 _period);
    event UniV3SetMinTickMove(int24 _minTickMove);
    event UniV3SetMaxTwapDeviation(int24 _maxTwapDeviation);
    event UniV3SetTwapDuration(uint32 _twapDuration);

    int24 public baseThreshold;
    int24 public limitThreshold;
    int24 public minTickMove;
    int24 public maxTwapDeviation;
    int24 public lastTick;
    uint256 public period;
    uint256 public lastTimestamp;
    uint32 public twapDuration;

    struct MintInfo {
        uint256 tokenId;
        int24 tickLower;
        int24 tickUpper;
    }

    MintInfo public baseMintInfo;
    MintInfo public limitMintInfo;

    function _initialize(
        address _vault,
        address _harvester,
        address _pool,
        int24 _baseThreshold,
        int24 _limitThreshold,
        uint256 _period,
        int24 _minTickMove,
        int24 _maxTwapDeviation,
        uint32 _twapDuration
    ) internal {
        _initializeUniswapV3Liquidity(_pool);
        address[] memory _wants = new address[](2);
        _wants[0] = token0;
        _wants[1] = token1;
        console.log('UniswapV3BaseStrategy _initialize _wants[0]: %s, _wants[1]: %s', _wants[0], _wants[1]);
        super._initialize(_vault, _harvester, uint16(ProtocolEnum.UniswapV3), _wants);
        baseThreshold = _baseThreshold;
        limitThreshold = _limitThreshold;
        period = _period;
        minTickMove = _minTickMove;
        maxTwapDeviation = _maxTwapDeviation;
        twapDuration = _twapDuration;
    }

    function getTickSpacing() internal pure virtual returns (int24);

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function getWantsInfo() public view override returns (address[] memory _assets, uint256[] memory _ratios) {
        _assets = wants;
        int24 tickLower = baseMintInfo.tickLower;
        int24 tickUpper = baseMintInfo.tickUpper;
        (, int24 tick,,,,,) = pool.slot0();
        if (baseMintInfo.tokenId == 0 || shouldRebalance(tick)) {
            (,, tickLower, tickUpper) = getSpecifiedRangesOfTick(tick);
        }

        (uint256 amount0, uint256 amount1) = getAmountsForLiquidity(tickLower, tickUpper, pool.liquidity());
        console.log('UniswapV3BaseStrategy getWantsInfo amount0: %d, amount1: %d', amount0, amount1);
        _ratios = new uint256[](2);
        _ratios[0] = amount0;
        _ratios[1] = amount1;
    }

    function getSpecifiedRangesOfTick(int24 tick) internal view returns (int24 tickFloor, int24 tickCeil, int24 tickLower, int24 tickUpper) {
        tickFloor = _floor(tick);
        tickCeil = tickFloor + getTickSpacing();
        tickLower = tickFloor - baseThreshold;
        tickUpper = tickCeil + baseThreshold;
        console.log('UniswapV3BaseStrategy getSpecifiedRangesOfTick tick:');
        console.logInt(tick);
        console.log('UniswapV3BaseStrategy getSpecifiedRangesOfTick tickFloor:');
        console.logInt(tickFloor);
        console.log('UniswapV3BaseStrategy getSpecifiedRangesOfTick tickCeil:');
        console.logInt(tickCeil);
        console.log('UniswapV3BaseStrategy getSpecifiedRangesOfTick tickLower:');
        console.logInt(tickLower);
        console.log('UniswapV3BaseStrategy getSpecifiedRangesOfTick tickUpper:');
        console.logInt(tickUpper);
    }

    function getAmountsForLiquidity(int24 _tickLower, int24 _tickUpper, uint128 _liquidity) internal view returns (uint256, uint256) {
        (uint160 sqrtPriceX96, , , , , ,) = pool.slot0();
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, TickMath.getSqrtRatioAtTick(_tickLower), TickMath.getSqrtRatioAtTick(_tickUpper), _liquidity);
        return (amount0, amount1);
    }

    function getPositionDetail() public view override returns (address[] memory _tokens, uint256[] memory _amounts, bool _isUsd, uint256 _usdValue) {
        _tokens = wants;
        _amounts = new uint256[](2);
        _amounts[0] = balanceOfToken(token0);
        _amounts[1] = balanceOfToken(token1);
        (uint256 amount0, uint256 amount1) = balanceOfPoolWants(baseMintInfo);
        _amounts[0] += amount0;
        _amounts[1] += amount1;
        (amount0, amount1) = balanceOfPoolWants(limitMintInfo);
        _amounts[0] += amount0;
        _amounts[1] += amount1;
    }

    function balanceOfPoolWants(MintInfo memory _mintInfo) internal view returns (uint256, uint256) {
        if (_mintInfo.tokenId == 0) return (0, 0);
        return getAmountsForLiquidity(_mintInfo.tickLower, _mintInfo.tickUpper, balanceOfLpToken(_mintInfo.tokenId));
    }

    function get3rdPoolAssets() external view override returns (uint256 totalAssets) {
        address pool = IUniswapV3Factory(nonfungiblePositionManager.factory()).getPool(token0, token1, fee);
        console.log('UniswapV3BaseStrategy get3rdPoolAssets pool: %s', pool);
        totalAssets = queryTokenValue(token0, IERC20Minimal(token0).balanceOf(pool));
        totalAssets += queryTokenValue(token1, IERC20Minimal(token1).balanceOf(pool));
    }

    function claimRewards() internal override returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts) {
        if (baseMintInfo.tokenId > 0) {
            __collectAll(baseMintInfo.tokenId);
        }

        if (limitMintInfo.tokenId > 0) {
            __collectAll(limitMintInfo.tokenId);
        }
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal override {
        console.log('UniswapV3BaseStrategy depositTo3rdPool balanceOfToken0 before: ', balanceOfToken(token0));
        console.log('UniswapV3BaseStrategy depositTo3rdPool balanceOfToken1 before: ', balanceOfToken(token1));
        (, int24 tick,,,,,) = pool.slot0();
        if (baseMintInfo.tokenId == 0) {
            console.log('UniswapV3BaseStrategy depositTo3rdPool mintNewPosition');
            (,, int24 tickLower, int24 tickUpper) = getSpecifiedRangesOfTick(tick);
            mintNewPosition(tickLower, tickUpper, balanceOfToken(token0), balanceOfToken(token1), true);
            console.log('UniswapV3BaseStrategy depositTo3rdPool mintNewPosition end');
        } else {
            if (shouldRebalance(tick)) {
                console.log('UniswapV3BaseStrategy depositTo3rdPool rebalance');
                rebalance(tick);
            } else {
                console.log('UniswapV3BaseStrategy depositTo3rdPool addLiquidity');
                //添加流动性
                INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId : baseMintInfo.tokenId,
                amount0Desired : balanceOfToken(token0),
                amount1Desired : balanceOfToken(token1),
                amount0Min : 0,
                amount1Min : 0,
                deadline : block.timestamp
                });
                __addLiquidity(params);
            }
        }

        console.log('UniswapV3BaseStrategy depositTo3rdPool balanceOfToken0 after: ', balanceOfToken(token0));
        console.log('UniswapV3BaseStrategy depositTo3rdPool balanceOfToken1 after: ', balanceOfToken(token1));
        console.log('UniswapV3BaseStrategy depositTo3rdPool liquidity after: ', __getLiquidityForNFT(baseMintInfo.tokenId));
    }

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares) internal override {
        console.log('UniswapV3BaseStrategy withdrawFrom3rdPool balanceOfLpToken0 before: ', balanceOfLpToken(baseMintInfo.tokenId));
        console.log('UniswapV3BaseStrategy withdrawFrom3rdPool balanceOfLpToken1 before: ', balanceOfLpToken(limitMintInfo.tokenId));
        withdraw(baseMintInfo.tokenId, _withdrawShares, _totalShares);
        withdraw(limitMintInfo.tokenId, _withdrawShares, _totalShares);
        console.log('UniswapV3BaseStrategy withdrawFrom3rdPool base balanceOfLpToken after: ', balanceOfLpToken(baseMintInfo.tokenId));
        console.log('UniswapV3BaseStrategy withdrawFrom3rdPool limit balanceOfLpToken after: ', balanceOfLpToken(limitMintInfo.tokenId));
    }

    function withdraw(uint256 _tokenId, uint256 _withdrawShares, uint256 _totalShares) internal {
        uint128 withdrawLiquidity = uint128(balanceOfLpToken(_tokenId) * _withdrawShares / _totalShares);
        if (withdrawLiquidity > 0) {
            removeLiquidity(_tokenId, withdrawLiquidity);
        }
    }

    function removeLiquidity(uint256 _tokenId, uint128 _liquidity) internal {
        console.log('UniswapV3BaseStrategy removeLiquidity liquidity %d', _liquidity);
        // remove liquidity
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId : _tokenId,
        liquidity : _liquidity,
        amount0Min : 0,
        amount1Min : 0,
        deadline : block.timestamp
        });
        console.log('UniswapV3BaseStrategy removeLiquidity balanceOfToken0 before: ', balanceOfToken(token0));
        console.log('UniswapV3BaseStrategy removeLiquidity balanceOfToken1 before: ', balanceOfToken(token1));
        __removeLiquidity(params);
        console.log('UniswapV3BaseStrategy removeLiquidity balanceOfToken0 after: ', balanceOfToken(token0));
        console.log('UniswapV3BaseStrategy removeLiquidity balanceOfToken1 after: ', balanceOfToken(token1));
    }

    function balanceOfLpToken(uint256 _tokenId) public view returns (uint128) {
        if (_tokenId == 0) return 0;
        return __getLiquidityForNFT(_tokenId);
    }

    function rebalanceByKeeper() external isKeeper {
        (, int24 tick,,,,,) = pool.slot0();
        require(shouldRebalance(tick), "cannot rebalance");
        rebalance(tick);
        vault.report(new address[](0), new uint256[](0));
    }

    function rebalance(int24 tick) internal {
        // Withdraw all current liquidity
        console.log('UniswapV3BaseStrategy rebalance baseMintInfo.tokenId: ', baseMintInfo.tokenId);
        uint128 baseLiquidity = balanceOfLpToken(baseMintInfo.tokenId);
        if (baseLiquidity > 0) {
            removeLiquidity(baseMintInfo.tokenId, baseLiquidity);
            __collectAll(baseMintInfo.tokenId);
        }

        console.log('UniswapV3BaseStrategy rebalance limitMintInfo.tokenId: ', limitMintInfo.tokenId);
        uint128 limitLiquidity = balanceOfLpToken(limitMintInfo.tokenId);
        if (limitLiquidity > 0) {
            removeLiquidity(limitMintInfo.tokenId, limitLiquidity);
            __collectAll(limitMintInfo.tokenId);
        }

        // Mint new base and limit position
        (int24 tickFloor, int24 tickCeil, int24 tickLower, int24 tickUpper) = getSpecifiedRangesOfTick(tick);
        uint256 balance0 = balanceOfToken(token0);
        uint256 balance1 = balanceOfToken(token1);
        console.log('UniswapV3BaseStrategy rebalance base mintNewPosition before balance0: %d, balance1: %d', balance0, balance1);
        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = mintNewPosition(tickLower, tickUpper, balance0, balance1, true);

        balance0 = balanceOfToken(token0);
        balance1 = balanceOfToken(token1);
        if (balance0 > 0 || balance1 > 0) {
            int24 bidLower = tickFloor - limitThreshold;
            int24 askUpper = tickCeil + limitThreshold;
            console.log('UniswapV3BaseStrategy rebalance limit mintNewPosition before balance0: %d, balance1: %d', balance0, balance1);
            // Place bid or ask order on Uniswap depending on which token is left
            if (getLiquidityForAmounts(bidLower, tickFloor, balance0, balance1) > getLiquidityForAmounts(tickCeil, askUpper, balance0, balance1)) {
                mintNewPosition(bidLower, tickFloor, balance0, balance1, false);
                console.log('UniswapV3BaseStrategy rebalance limit bid mintNewPosition');
            } else {
                mintNewPosition(tickCeil, askUpper, balance0, balance1, false);
                console.log('UniswapV3BaseStrategy rebalance limit ask mintNewPosition');
            }
            console.log('UniswapV3BaseStrategy rebalance limit mintNewPosition after balance0: %d, balance1: %d', balanceOfToken(token0), balanceOfToken(token1));
        }
        lastTimestamp = block.timestamp;
        lastTick = tick;
    }

    function shouldRebalance(int24 tick) public view returns (bool) {
        // check enough time has passed
        if (block.timestamp < lastTimestamp + period) {
            return false;
        }

        // check price has moved enough
        if ((tick > lastTick ? tick - lastTick : lastTick - tick) < minTickMove) {
            return false;
        }

        // check price near twap
        int24 twap = getTwap();
        int24 twapDeviation = tick > twap ? tick - twap : twap - tick;
        if (twapDeviation > maxTwapDeviation) {
            return false;
        }

        // check price not too close to boundary
        int24 maxThreshold = baseThreshold > limitThreshold ? baseThreshold : limitThreshold;
        if (tick < TickMath.MIN_TICK + maxThreshold + getTickSpacing() || tick > TickMath.MAX_TICK - maxThreshold - getTickSpacing()) {
            return false;
        }

        return true;
    }

    function getLiquidityForAmounts(int24 _tickLower, int24 _tickUpper, uint256 _amount0, uint256 _amount1) internal view returns (uint128) {
        (uint160 sqrtPriceX96, , , , , ,) = pool.slot0();
        return LiquidityAmounts.getLiquidityForAmounts(sqrtPriceX96, TickMath.getSqrtRatioAtTick(_tickLower), TickMath.getSqrtRatioAtTick(_tickUpper), _amount0, _amount1);
    }

    // Fetches time-weighted average price in ticks from Uniswap pool.
    function getTwap() public view returns (int24) {
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = twapDuration;
        secondsAgo[1] = 0;

        (int56[] memory tickCumulatives,) = pool.observe(secondsAgo);
        return int24((tickCumulatives[1] - tickCumulatives[0]) / int32(twapDuration));
    }

    // Rounds tick down towards negative infinity so that it's a multiple of `tickSpacing`.
    function _floor(int24 tick) internal view returns (int24) {
        // compressed=-27633, tick=-276330, tickSpacing=10
        int24 compressed = tick / getTickSpacing();
        if (tick < 0 && tick % getTickSpacing() != 0) compressed--;
        return compressed * getTickSpacing();
    }

    function mintNewPosition(int24 _tickLower, int24 _tickUpper, uint256 _amount0Desired, uint256 _amount1Desired, bool _base) internal returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
        token0 : token0,
        token1 : token1,
        fee : fee,
        tickLower : _tickLower,
        tickUpper : _tickUpper,
        amount0Desired : _amount0Desired,
        amount1Desired : _amount1Desired,
        amount0Min : 0,
        amount1Min : 0,
        recipient : address(this),
        deadline : block.timestamp
        });
        (tokenId, liquidity, amount0, amount1) = __mint(params);
        if (_base) {
            baseMintInfo = MintInfo({tokenId : tokenId, tickLower : _tickLower, tickUpper : _tickUpper});
        } else {
            limitMintInfo = MintInfo({tokenId : tokenId, tickLower : _tickLower, tickUpper : _tickUpper});
        }
    }

    function _checkThreshold(int24 _threshold) internal pure {
        require(_threshold > 0 && _threshold <= TickMath.MAX_TICK && _threshold % getTickSpacing() == 0, "threshold validate error");
    }

    function setBaseThreshold(int24 _baseThreshold) external onlyGovOrDelegate {
        _checkThreshold(_baseThreshold);
        baseThreshold = _baseThreshold;
        emit UniV3SetBaseThreshold(_baseThreshold);
    }

    function setLimitThreshold(int24 _limitThreshold) external onlyGovOrDelegate {
        _checkThreshold(_limitThreshold);
        limitThreshold = _limitThreshold;
        emit UniV3SetLimitThreshold(_limitThreshold);
    }

    function setPeriod(uint256 _period) external onlyGovOrDelegate {
        period = _period;
        emit UniV3SetPeriod(_period);
    }

    function setMinTickMove(int24 _minTickMove) external onlyGovOrDelegate {
        require(_minTickMove >= 0, "minTickMove must be >= 0");
        minTickMove = _minTickMove;
        emit UniV3SetMinTickMove(_minTickMove);
    }

    function setMaxTwapDeviation(int24 _maxTwapDeviation) external onlyGovOrDelegate {
        require(_maxTwapDeviation >= 0, "maxTwapDeviation must be >= 0");
        maxTwapDeviation = _maxTwapDeviation;
        emit UniV3SetMaxTwapDeviation(_maxTwapDeviation);
    }

    function setTwapDuration(uint32 _twapDuration) external onlyGovOrDelegate {
        require(_twapDuration > 0, "twapDuration must be > 0");
        twapDuration = _twapDuration;
        emit UniV3SetTwapDuration(_twapDuration);
    }
}
