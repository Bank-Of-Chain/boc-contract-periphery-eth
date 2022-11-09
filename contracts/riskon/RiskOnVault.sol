// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "./../external/uniswap/IUniswapV3.sol";
import "../utils/actions/AaveLendActionMixin.sol";
import './ITreasury.sol';
import "./RiskOnUniswapV3Strategy.sol";
import "./RiskOnHelper.sol";
import "../../library/RiskOnConstant.sol";

/// @title RiskOnVault
/// @author Bank of Chain Protocol Inc
contract RiskOnVault is AaveLendActionMixin, AccessControlMixin, Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    event BorrowRebalance();

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

    bool internal invested;
    address internal owner;
    /// @notice  net market making amount
    uint256 public netMarketMakingAmount;

    address public wantToken;
    address internal token0;
    address internal token1;
    uint24 internal fee;
    uint256 public token0MinLendAmount;
    uint256 public token1MinLendAmount;

    // @notice  amount of manage fee in basis points
    uint256 public manageFeeBps;

    RiskOnUniswapV3Strategy internal riskOnUniswapV3Strategy;
    RiskOnHelper internal riskOnHelper;
    ITreasury internal treasury;

    /// @notice Initialize this contract
    /// @param _wantToken The want token
    /// @param _interestRateMode The interest rate mode
    /// @param _riskOnHelper The uniswap v3 helper
    /// @param _treasury The treasury
    /// @param _accessControlProxy The access control proxy address
    function _initialize(
        address _wantToken,
        uint256 _interestRateMode,
        uint256 _token0MinLendAmount,
        uint256 _token1MinLendAmount,
        uint256 manageFeeBps,
        address _riskOnUniswapV3Strategy,
        address _riskOnHelper,
        address _treasury,
        address _accessControlProxy
    ) internal {
        wantToken = _wantToken;
        riskOnUniswapV3Strategy = RiskOnUniswapV3Strategy(_riskOnUniswapV3Strategy);
        token0 = riskOnUniswapV3Strategy.token0();
        token1 = riskOnUniswapV3Strategy.token1();
        fee = riskOnUniswapV3Strategy.fee();
        token0MinLendAmount = _token0MinLendAmount;
        token1MinLendAmount = _token1MinLendAmount;
        manageFeeBps = manageFeeBps;
        riskOnHelper = RiskOnHelper(_riskOnHelper);
        treasury = ITreasury(_treasury);
        super._initAccessControl(_accessControlProxy);
        super.__initLendConfigation(_interestRateMode, wantToken, wantToken == token0 ? token1 : token0);
        IERC20Upgradeable(wantToken).safeApprove(address(treasury), type(uint256).max);
        IERC20Upgradeable(wantToken).safeApprove(_riskOnUniswapV3Strategy, type(uint256).max);
        IERC20Upgradeable(borrowToken).safeApprove(_riskOnUniswapV3Strategy, type(uint256).max);
        IERC20Upgradeable(wantToken).safeApprove(RiskOnConstant.UNISWAP_V3_ROUTER, type(uint256).max);
        IERC20Upgradeable(borrowToken).safeApprove(RiskOnConstant.UNISWAP_V3_ROUTER, type(uint256).max);
    }

    /// @notice Return the version of strategy
    function getVersion() external pure returns (string memory) {
        return "1.0.0";
    }

    /// @notice Total assets
    function estimatedTotalAssets() public view returns (uint256 _totalAssets) {
        _totalAssets = riskOnUniswapV3Strategy.estimatedTotalAssets() + riskOnHelper.getTotalCollateralTokenAmount(address(this), wantToken) - riskOnHelper.calcCanonicalAssetValue(borrowToken, riskOnHelper.getCurrentBorrow(borrowToken, interestRateMode, address(this)), wantToken);
    }

    /// @notice Lend
    /// @param _amount The amount of lend
    function lend(uint256 _amount) external whenNotEmergency nonReentrant {
        // TODO share
        if (!invested) {
            if (wantToken == token0) {
                require(_amount >= token0MinLendAmount, "MLA");
            } else {
                require(_amount >= token1MinLendAmount, "MLA");
            }
            invested = true;
        } else {
            if (wantToken == token0) {
                require(_amount + estimatedTotalAssets() >= token0MinLendAmount, "MLA");
            } else {
                require(_amount + estimatedTotalAssets() >= token1MinLendAmount, "MLA");
            }
        }

        IERC20Upgradeable(wantToken).safeTransferFrom(msg.sender, address(this), _amount);
        if (manageFeeBps > 0 && address(treasury) != address(0)) {
            uint256 manageFee = _amount * manageFeeBps / 10000;
            treasury.receiveManageFeeFromVault(wantToken, manageFee);
            _amount -= manageFee;
        }

        __addCollateral(_amount.mul(2).div(3));
        __borrow(riskOnHelper.calcCanonicalAssetValue(wantToken, _amount.div(3), borrowToken));
        riskOnUniswapV3Strategy.deposit(balanceOfToken(token0), balanceOfToken(token1));

        netMarketMakingAmount += _amount;
        emit LendToStrategy(wantToken, _amount);
    }

    /// @notice Redeem
    /// @param _redeemShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @return _redeemBalance The balance of redeem
    function redeem(uint256 _redeemShares, uint256 _totalShares) external returns (uint256 _redeemBalance) {
        // TODO share and require
        _redeemBalance = redeemToVault(_redeemShares, _totalShares);
        if (_redeemBalance > netMarketMakingAmount) {
            netMarketMakingAmount = 0;
        } else {
            netMarketMakingAmount -= _redeemBalance;
        }
        IERC20Upgradeable(wantToken).safeTransfer(msg.sender, _redeemBalance);
        emit Redeem(wantToken, _redeemBalance);
    }

    /// @notice Redeem to vault by keeper
    /// @param _redeemShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @return _redeemBalance The balance of redeem
    function redeemToVaultByKeeper(uint256 _redeemShares, uint256 _totalShares) external returns (uint256 _redeemBalance) {
        // TODO share and require
        // TODO isM
        _redeemBalance = redeemToVault(_redeemShares, _totalShares);
        emit RedeemToVault(_redeemBalance);
    }

    /// @notice Redeem to vault
    /// @param _redeemShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @return _redeemBalance The balance of redeem
    function redeemToVault(uint256 _redeemShares, uint256 _totalShares) internal whenNotEmergency nonReentrant returns (uint256 _redeemBalance) {
        // TODO share
        uint256 currentBorrow = riskOnHelper.getCurrentBorrow(borrowToken, interestRateMode, address(this));
        address aCollateralToken = riskOnHelper.getAToken(wantToken);
        if (_redeemShares == _totalShares) {
            redeemFromStrategy(_redeemShares, _totalShares);
            uint256 borrowTokenBalance = balanceOfToken(borrowToken);
            if (currentBorrow > borrowTokenBalance) {
                IUniswapV3(RiskOnConstant.UNISWAP_V3_ROUTER).exactOutputSingle(IUniswapV3.ExactOutputSingleParams(wantToken, borrowToken, fee, address(this), block.timestamp, currentBorrow - borrowTokenBalance, type(uint256).max, 0));
            }
            __repay(currentBorrow);
            __removeCollateral(aCollateralToken, IERC20(aCollateralToken).balanceOf(address(this)));
        } else {
            redeemFromStrategy(_redeemShares, _totalShares);
            uint256 redeemBorrowTokenBalance = balanceOfToken(borrowToken);
            uint256 redeemCurrentBorrow = currentBorrow * _redeemShares / _totalShares;
            if (redeemCurrentBorrow > redeemBorrowTokenBalance) {
                IUniswapV3(RiskOnConstant.UNISWAP_V3_ROUTER).exactOutputSingle(IUniswapV3.ExactOutputSingleParams(wantToken, borrowToken, fee, address(this), block.timestamp, redeemCurrentBorrow - redeemBorrowTokenBalance, type(uint256).max, 0));
            }
            __repay(redeemCurrentBorrow);
            __removeCollateral(aCollateralToken, IERC20(aCollateralToken).balanceOf(address(this)) * _redeemShares / _totalShares);
        }
        uint256 borrowTokenBalance = balanceOfToken(borrowToken);
        if (borrowTokenBalance > 0) {
            IUniswapV3(RiskOnConstant.UNISWAP_V3_ROUTER).exactInputSingle(IUniswapV3.ExactInputSingleParams(borrowToken, wantToken, fee, address(this), block.timestamp, borrowTokenBalance, 0, 0));
        }
        _redeemBalance = balanceOfToken(wantToken);
    }

    function redeemFromStrategy(uint256 _redeemShares, uint256 _totalShares) internal {
        (uint256 _amount0, uint256 _amount1) = riskOnUniswapV3Strategy.withdrawFrom3rdPool(_redeemShares, _totalShares);
        IERC20Upgradeable(token0).safeTransferFrom(address(riskOnUniswapV3Strategy), address(this), _amount0);
        IERC20Upgradeable(token1).safeTransferFrom(address(riskOnUniswapV3Strategy), address(this), _amount1);
    }

    /// @notice Rebalance the position of this strategy
    /// Requirements: only keeper can call
    function borrowRebalance() external whenNotEmergency nonReentrant isKeeper {
        // TODO share: by user
        (uint256 _totalCollateral, uint256 _totalDebt, , , ,) = riskOnHelper.borrowInfo(address(this));
        require(_totalCollateral > 0 || _totalDebt > 0, "CNBR");
        if (_totalDebt.mul(10000).div(_totalCollateral) >= 7500) {
            uint256 repayAmount = riskOnHelper.calcAaveBaseCurrencyValueInAsset((_totalDebt - _totalCollateral.mul(5000).div(10000)), borrowToken);
            redeemFromStrategy(100, 100);
            if (balanceOfToken(borrowToken) < repayAmount) {
                IUniswapV3(RiskOnConstant.UNISWAP_V3_ROUTER).exactOutputSingle(IUniswapV3.ExactOutputSingleParams(wantToken, borrowToken, 500, address(this), block.timestamp, repayAmount - balanceOfToken(borrowToken), type(uint256).max, 0));
            }
            __repay(repayAmount);
            riskOnUniswapV3Strategy.deposit(balanceOfToken(token0), balanceOfToken(token1));
        }
        if (_totalDebt.mul(10000).div(_totalCollateral) <= 4000) {
            __borrow(riskOnHelper.calcAaveBaseCurrencyValueInAsset((_totalCollateral.mul(5000).div(10000) - _totalDebt), borrowToken));
            riskOnUniswapV3Strategy.forceRebalance();
        }
        emit BorrowRebalance();
    }

    /// @notice Return the token's balance Of this contract
    function balanceOfToken(address _tokenAddress) internal view returns (uint256) {
        return IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
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

    /// @dev Sets the manageFeeBps to the percentage of deposit that should be received in basis points.
    /// Requirements: only vault manager can call
    function setManageFeeBps(uint256 _basis) external isVaultManager {
        require(_basis <= 1000, "MFBCE");
        manageFeeBps = _basis;
    }

    /// @dev Sets the token0MinLendAmount to lend.
    /// Requirements: only vault manager can call
    function setToken0MinLendAmount(uint256 _minLendAmount) external isVaultManager {
        token0MinLendAmount = _minLendAmount;
    }

    /// @dev Sets the token1MinLendAmount to lend.
    /// Requirements: only vault manager can call
    function setToken1MinLendAmount(uint256 _minLendAmount) external isVaultManager {
        token1MinLendAmount = _minLendAmount;
    }
}
