// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
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
import "../utils/actions/AaveLendActionMixin.sol";
import "../utils/actions/UniswapV3LiquidityActionsMixin.sol";
import "./IRiskOnUniswapV3Strategy.sol";
import './ITreasury.sol';
import "./RiskOnVault.sol";
import "./RiskOnHelper.sol";
import "../../library/RiskOnConstant.sol";

/// @title RiskOnUniswapV3Strategy
/// @author Bank of Chain Protocol Inc
contract RiskOnUniswapV3Strategy is UniswapV3LiquidityActionsMixin, AccessControlMixin, Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    event Rebalance();

    /// @param _rewardTokens The reward tokens
    /// @param _claimAmounts The claim amounts
    event StrategyReported(address[] _rewardTokens, uint256[] _claimAmounts);

    /// @param _wantToken The want token
    /// @param _amount The amount list of token wanted
    event LendToStrategy(address _wantToken, uint256 _amount);

    /// @param _wantToken The want token
    /// @param _redeemAmount The amount of redeem
    event Redeem(address _wantToken, uint256 _redeemAmount);

    /// @param _redeemAmount The amount of redeem
    event RedeemToVault(uint256 _redeemAmount);

    /// @notice  emergency shutdown
    bool public emergencyShutdown;

    address internal wantToken;
    int24 internal baseThreshold;
    int24 internal limitThreshold;
    int24 internal minTickMove;
    int24 internal maxTwapDeviation;
    int24 internal lastTick;
    int24 internal tickSpacing;
    uint32 internal twapDuration;
    uint256 internal period;
    uint256 internal lastTimestamp;

    // @notice  last harvest timestamp
    uint256 public lastHarvest;

    // @notice  amount of yield collected in basis points
    uint256 public profitFeeBps;

    MintInfo internal baseMintInfo;
    MintInfo internal limitMintInfo;
    RiskOnVault internal riskOnVault;
    RiskOnHelper internal riskOnHelper;
    ITreasury internal treasury;

    /// @param tokenId The tokenId of V3 LP NFT minted
    /// @param _tickLower The lower tick of the position in which to add liquidity
    /// @param _tickUpper The upper tick of the position in which to add liquidity
    struct MintInfo {
        uint256 tokenId;
        int24 tickLower;
        int24 tickUpper;
    }

    /// @notice Initialize this contract
    /// @param _wantToken The want token
    /// @param _pool The uniswap V3 pool
    /// @param _baseThreshold The new base threshold
    /// @param _limitThreshold The new limit threshold
    /// @param _period The new period
    /// @param _minTickMove The minium tick to move
    /// @param _maxTwapDeviation The max TWAP deviation
    /// @param _twapDuration The max TWAP duration
    /// @param _tickSpacing The tick spacing
    /// @param _riskOnHelper The uniswap v3 helper
    /// @param _treasury The treasury
    /// @param _accessControlProxy The access control proxy address
    function _initialize(
        address _wantToken,
        address _pool,
        uint256 _profitFeeBps,
        int24 _baseThreshold,
        int24 _limitThreshold,
        uint256 _period,
        int24 _minTickMove,
        int24 _maxTwapDeviation,
        uint32 _twapDuration,
        int24 _tickSpacing,
        address _riskOnVault,
        address _riskOnHelper,
        address _treasury,
        address _accessControlProxy
    ) internal {
        super._initializeUniswapV3Liquidity(_pool);
        wantToken = _wantToken;
        profitFeeBps = _profitFeeBps;
        baseThreshold = _baseThreshold;
        limitThreshold = _limitThreshold;
        period = _period;
        minTickMove = _minTickMove;
        maxTwapDeviation = _maxTwapDeviation;
        twapDuration = _twapDuration;
        tickSpacing = _tickSpacing;
        riskOnVault = RiskOnVault(_riskOnVault);
        riskOnHelper = RiskOnHelper(_riskOnHelper);
        treasury = ITreasury(_treasury);
        _initAccessControl(_accessControlProxy);
        IERC20Upgradeable(token0).safeApprove(address(_riskOnVault), type(uint256).max);
        IERC20Upgradeable(token1).safeApprove(address(_riskOnVault), type(uint256).max);
        IERC20Upgradeable(token0).safeApprove(address(treasury), type(uint256).max);
        IERC20Upgradeable(token1).safeApprove(address(treasury), type(uint256).max);
    }

    /// @notice Return the version of strategy
    function getVersion() external pure returns (string memory) {
        return "1.0.0";
    }

    /// @notice Gets the statuses about uniswap V3
    /// @return _baseThreshold The new base threshold
    /// @return _limitThreshold The new limit threshold
    /// @return _minTickMove The minium tick to move
    /// @return _maxTwapDeviation The max TWAP deviation
    /// @return _lastTick The last tick
    /// @return _period The new period
    /// @return _lastTimestamp The timestamp of last action
    /// @return _twapDuration The max TWAP duration
    function getStatus() external view returns (int24 _baseThreshold, int24 _limitThreshold, int24 _minTickMove, int24 _maxTwapDeviation, int24 _lastTick, uint256 _period, uint256 _lastTimestamp, uint32 _twapDuration) {
        return (baseThreshold, limitThreshold, minTickMove, maxTwapDeviation, lastTick, period, lastTimestamp, twapDuration);
    }

    /// @notice Gets the info of LP V3 NFT minted
    function getMintInfo() external view returns (uint256 _baseTokenId, int24 _baseTickUpper, int24 _baseTickLower, uint256 _limitTokenId, int24 _limitTickUpper, int24 _limitTickLower) {
        return (baseMintInfo.tokenId, baseMintInfo.tickUpper, baseMintInfo.tickLower, limitMintInfo.tokenId, limitMintInfo.tickUpper, limitMintInfo.tickLower);
    }

    /// @notice Deposit to 3rd pool total assets
    function estimatedTotalAssets() external view returns (uint256 _totalAssets) {
        (uint256 _amount0, uint256 _amount1) = balanceOfPoolWants(baseMintInfo);
        uint256 amount0 = _amount0;
        uint256 amount1 = _amount1;
        (_amount0, _amount1) = balanceOfPoolWants(limitMintInfo);
        amount0 += _amount0;
        amount1 += _amount1;
        amount0 += balanceOfToken(token0);
        amount1 += balanceOfToken(token1);
        if (wantToken == token0) {
            _totalAssets = amount0 + riskOnHelper.calcCanonicalAssetValue(token1, amount1, token0);
        } else {
            _totalAssets = amount1 + riskOnHelper.calcCanonicalAssetValue(token0, amount0, token1);
        }
    }

    /// @notice Deposit
    /// @param _token0Amount The amount of token0
    /// @param _token1Amount The amount of token1
    function deposit(uint256 _token0Amount, uint256 _token1Amount) external whenNotEmergency nonReentrant {
        IERC20Upgradeable(token0).safeTransferFrom(msg.sender, address(this), _token0Amount);
        IERC20Upgradeable(token1).safeTransferFrom(msg.sender, address(this), _token1Amount);

        (, int24 _tick,,,,,) = pool.slot0();
        if (baseMintInfo.tokenId == 0) {
            depositTo3rdPool(_tick);
        } else {
            rebalance(_tick);
        }
    }

    /// @notice Deposit to 3rd pool
    /// @param _tick The new tick to invest
    function depositTo3rdPool(int24 _tick) internal {
        // Mint new base and limit position
        (int24 _tickFloor, int24 _tickCeil, int24 _tickLower, int24 _tickUpper) = riskOnHelper.getSpecifiedRangesOfTick(_tick, tickSpacing, baseThreshold);
        uint256 _balance0 = balanceOfToken(token0);
        uint256 _balance1 = balanceOfToken(token1);
        if (_balance0 > 10000 && _balance1 > 10000) {
            mintNewPosition(_tickLower, _tickUpper, _balance0, _balance1, true);
            _balance0 = balanceOfToken(token0);
            _balance1 = balanceOfToken(token1);
        }

        if (_balance0 > 10000 || _balance1 > 10000) {
            if (_balance0 > 10000) {
                _balance1 = 0;
            }
            if (_balance1 > 10000) {
                _balance0 = 0;
            }
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

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares) external returns (uint256 _amount0, uint256 _amount1) {
        if (_withdrawShares == _totalShares) {
            withdrawAll();
            _amount0 = balanceOfToken(token0);
            _amount1 = balanceOfToken(token1);
        } else {
            uint256 beforeAmount0 = balanceOfToken(token0);
            uint256 beforeAmount1 = balanceOfToken(token1);
            withdraw(baseMintInfo.tokenId, _withdrawShares, _totalShares);
            withdraw(limitMintInfo.tokenId, _withdrawShares, _totalShares);
            uint256 afterAmount0 = balanceOfToken(token0);
            uint256 afterAmount1 = balanceOfToken(token1);
            _amount0 = afterAmount0 + (beforeAmount0 * _withdrawShares / _totalShares) - beforeAmount0;
            _amount1 = afterAmount1 + (beforeAmount0 * _withdrawShares / _totalShares) - beforeAmount1;
        }
    }

    /// @notice Burn all liquidity
    function withdrawAll() internal {
        harvest();
        // Withdraw all current liquidity
        uint128 _baseLiquidity = balanceOfLpToken(baseMintInfo.tokenId);
        if (_baseLiquidity > 0) {
            __purge(baseMintInfo.tokenId, type(uint128).max, 0, 0);
            delete baseMintInfo;
        }

        uint128 _limitLiquidity = balanceOfLpToken(limitMintInfo.tokenId);
        if (_limitLiquidity > 0) {
            __purge(limitMintInfo.tokenId, type(uint128).max, 0, 0);
            delete limitMintInfo;
        }
    }

    /// @notice Remove partial liquidity of `_tokenId`
    /// @param _tokenId One tokenId to remove liquidity
    /// @param _withdrawShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    function withdraw(uint256 _tokenId, uint256 _withdrawShares, uint256 _totalShares) internal {
        uint128 _withdrawLiquidity = uint128(balanceOfLpToken(_tokenId) * _withdrawShares / _totalShares);
        if (_withdrawLiquidity <= 0) return;
        // remove liquidity
        (uint256 _amount0, uint256 _amount1) = nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId : _tokenId,
        liquidity : _withdrawLiquidity,
        amount0Min : 0,
        amount1Min : 0,
        deadline : block.timestamp
        }));
        if (_amount0 > 0 || _amount1 > 0) {
            __collect(_tokenId, uint128(_amount0), uint128(_amount1));
        }
    }

    /// @notice Harvests the Strategy
    /// @return  _rewardsTokens The reward tokens list
    /// @return _claimAmounts The claim amounts list
    function harvest() public returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts) {
        lastHarvest = block.timestamp;
        _rewardsTokens = new address[](2);
        _rewardsTokens[0] = token0;
        _rewardsTokens[1] = token1;
        _claimAmounts = new uint256[](2);
        uint256 _amount0;
        uint256 _amount1;
        if (baseMintInfo.tokenId > 0) {
            (_amount0, _amount1) = __collectAll(baseMintInfo.tokenId);
            _claimAmounts[0] += _amount0;
            _claimAmounts[1] += _amount1;
        }
        if (limitMintInfo.tokenId > 0) {
            (_amount0, _amount1) = __collectAll(limitMintInfo.tokenId);
            _claimAmounts[0] += _amount0;
            _claimAmounts[1] += _amount1;
        }

        if (profitFeeBps > 0 && address(treasury) != address(0)) {
            if (_claimAmounts[0] > 0) {
                uint256 claimAmount0Fee = _claimAmounts[0] * profitFeeBps / 10000;
                _claimAmounts[0] -= claimAmount0Fee;
                treasury.receiveProfitFromVault(token0, claimAmount0Fee);
            }
            if (_claimAmounts[1] > 0) {
                uint256 claimAmount1Fee = _claimAmounts[1] * profitFeeBps / 10000;
                _claimAmounts[1] -= claimAmount1Fee;
                treasury.receiveProfitFromVault(token1, claimAmount1Fee);
            }
        }
        emit StrategyReported(_rewardsTokens, _claimAmounts);
    }

    /// @notice Rebalance the position of this strategy
    /// Requirements: only keeper can call
    function rebalanceByKeeper() external whenNotEmergency nonReentrant isKeeper {
        require(baseMintInfo.tokenId > 0 || limitMintInfo.tokenId > 0, "CNRBK");
        (, int24 _tick,,,,,) = pool.slot0();
        require(shouldRebalance(_tick), "NR");
        rebalance(_tick);
    }

    function forceRebalance() external {
        (, int24 _tick,,,,,) = pool.slot0();
        rebalance(_tick);
    }

    /// @notice Rebalance the position of this strategy
    /// @param _tick The new tick to invest
    function rebalance(int24 _tick) internal {
        harvest();
        // Withdraw all current liquidity
        uint128 _baseLiquidity = balanceOfLpToken(baseMintInfo.tokenId);
        if (_baseLiquidity > 0) {
            __purge(baseMintInfo.tokenId, type(uint128).max, 0, 0);
            delete baseMintInfo;
        }

        uint128 _limitLiquidity = balanceOfLpToken(limitMintInfo.tokenId);
        if (_limitLiquidity > 0) {
            __purge(limitMintInfo.tokenId, type(uint128).max, 0, 0);
            delete limitMintInfo;
        }

        if (_baseLiquidity <= 0 && _limitLiquidity <= 0) return;

        depositTo3rdPool(_tick);
        emit Rebalance();
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
        int24 _twap = riskOnHelper.getTwap(address(pool), twapDuration);
        int24 _twapDeviation = _tick > _twap ? _tick - _twap : _twap - _tick;
        if (_twapDeviation > maxTwapDeviation) {
            return false;
        }

        // check price not too close to boundary
        int24 _maxThreshold = baseThreshold > limitThreshold ? baseThreshold : limitThreshold;
        if (_tick < TickMath.MIN_TICK + _maxThreshold + tickSpacing || _tick > TickMath.MAX_TICK - _maxThreshold - tickSpacing) {
            return false;
        }

        (, , int24 _tickLower, int24 _tickUpper) = riskOnHelper.getSpecifiedRangesOfTick(_tick, tickSpacing, baseThreshold);
        if (baseMintInfo.tokenId != 0 && _tickLower == baseMintInfo.tickLower && _tickUpper == baseMintInfo.tickUpper) {
            return false;
        }

        return true;
    }

    /// @notice Mints a new uniswap V3 position, receiving an nft as a receipt
    /// @param _tickLower The lower tick of the new position in which to add liquidity
    /// @param _tickUpper The upper tick of the new position in which to add liquidity
    /// @param _amount0Desired The amount of token0 desired to invest
    /// @param _amount1Desired The amount of token1 desired to invest
    /// @param _base The boolean flag to start base mint, 'true' to base mint,'false' to limit mint
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
        (_tokenId, _liquidity, _amount0, _amount1) = __mint(INonfungiblePositionManager.MintParams({
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
        }));
        if (_base) {
            baseMintInfo = MintInfo({tokenId : _tokenId, tickLower : _tickLower, tickUpper : _tickUpper});
        } else {
            limitMintInfo = MintInfo({tokenId : _tokenId, tickLower : _tickLower, tickUpper : _tickUpper});
        }
    }

    /// @notice Gets the total liquidity of `_tokenId` NFT position.
    /// @param _tokenId One tokenId
    /// @return The total liquidity of `_tokenId` NFT position
    function balanceOfLpToken(uint256 _tokenId) internal view returns (uint128) {
        if (_tokenId == 0) return 0;
        return __getLiquidityForNFT(_tokenId);
    }

    /// @notice Gets the liquidity for the two amounts
    /// @param _tickLower  The specified lower tick
    /// @param _tickUpper  The specified upper tick
    /// @param _amount0 The amount of token0
    /// @param _amount1 The amount of token1
    /// @return The liquidity being valued
    function getLiquidityForAmounts(int24 _tickLower, int24 _tickUpper, uint256 _amount0, uint256 _amount1) internal view returns (uint128) {
        (uint160 _sqrtPriceX96, , , , , ,) = pool.slot0();
        return LiquidityAmounts.getLiquidityForAmounts(_sqrtPriceX96, TickMath.getSqrtRatioAtTick(_tickLower), TickMath.getSqrtRatioAtTick(_tickUpper), _amount0, _amount1);
    }

    /// @notice Return the token's balance Of this contract
    function balanceOfToken(address _tokenAddress) internal view returns (uint256) {
        return IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    }

    /// @notice Gets the two tokens' balances of LP V3 NFT
    /// @param _mintInfo  The info of LP V3 NFT
    /// @return The amount of token0
    /// @return The amount of token1
    function balanceOfPoolWants(MintInfo memory _mintInfo) internal view returns (uint256, uint256) {
        if (_mintInfo.tokenId == 0) return (0, 0);
        (uint160 _sqrtPriceX96, , , , , ,) = pool.slot0();
        return LiquidityAmounts.getAmountsForLiquidity(_sqrtPriceX96, TickMath.getSqrtRatioAtTick(_mintInfo.tickLower), TickMath.getSqrtRatioAtTick(_mintInfo.tickUpper), balanceOfLpToken(_mintInfo.tokenId));
    }

    modifier whenNotEmergency() {
        require(!emergencyShutdown, "ES");
        _;
    }

    /// @dev Shutdown the vault when an emergency occurs, cannot mint/burn.
    /// Requirements: only vault manager can call
    function setEmergencyShutdown(bool _active) external isVaultManager {
        emergencyShutdown = _active;
    }

    /// @dev Sets the profitFeeBps to the percentage of yield that should be received in basis points.
    function setProfitFeeBps(uint256 _basis) external isVaultManager {
        require(_basis <= 5000, "PFBCE");
        profitFeeBps = _basis;
    }

    /// @notice Sets `baseThreshold` state variable
    /// Requirements: only vault manager  can call
    function setBaseThreshold(int24 _baseThreshold) external isVaultManager {
        _checkThreshold(_baseThreshold);
        baseThreshold = _baseThreshold;
    }

    /// @notice Sets `limitThreshold` state variable
    /// Requirements: only vault manager  can call
    function setLimitThreshold(int24 _limitThreshold) external isVaultManager {
        _checkThreshold(_limitThreshold);
        limitThreshold = _limitThreshold;
    }

    /// @notice Check the Validity of `_threshold`
    function _checkThreshold(int24 _threshold) internal view {
        require(_threshold >= 0 && _threshold <= TickMath.MAX_TICK && _threshold % tickSpacing == 0, "TE");
    }

    /// @notice Sets `period` state variable
    /// Requirements: only vault manager  can call
    function setPeriod(uint256 _period) external isVaultManager {
        period = _period;
    }

    /// @notice Sets `minTickMove` state variable
    /// Requirements: only vault manager  can call
    function setMinTickMove(int24 _minTickMove) external isVaultManager {
        require(_minTickMove >= 0, "MINE");
        minTickMove = _minTickMove;
    }

    /// @notice Sets `maxTwapDeviation` state variable
    /// Requirements: only vault manager  can call
    function setMaxTwapDeviation(int24 _maxTwapDeviation) external isVaultManager {
        require(_maxTwapDeviation >= 0, "MAXE");
        maxTwapDeviation = _maxTwapDeviation;
    }

    /// @notice Sets `twapDuration` state variable
    /// Requirements: only vault manager  can call
    function setTwapDuration(uint32 _twapDuration) external isVaultManager {
        require(_twapDuration > 0, "TWAPE");
        twapDuration = _twapDuration;
    }
}
