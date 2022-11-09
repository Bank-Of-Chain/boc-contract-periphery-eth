// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol';
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

    uint256 public minTotalAmountUserLend;
    mapping(address => uint256) public netAmountUserLend;

    RiskOnUniswapV3Strategy internal riskOnUniswapV3Strategy;
    RiskOnHelper internal riskOnHelper;
    ITreasury internal treasury;

    /// @dev decimals：1e27
    uint256 public totalCollateralShares;
    uint256 public totalDebtShares;
    uint256 public totalLPShares;

    /// @dev decimals：1e27
    mapping(address => uint256) public collateralShares;
    mapping(address => uint256) public debtShares;
    mapping(address => uint256) public lpShares;

    /// @param _account The recipient of shares minting
    /// @param _shareAmount The amount of shares minting
    /// @param _sharesType 0 => collateralShares, 1 => debtShares, 2 => lpShares
    event MintShares(address indexed _account,uint256 _sharesAmount, unit8 _sharesType);

    /// @param _account The owner of shares burning
    /// @param _shareAmount The amount of shares burning
    /// @param _sharesType 0 => collateralShares, 1 => debtShares, 2 => lpShares
    event BurnShares(address _account,uint256 _shareAmount, unit8 _sharesType);

    

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
        _totalAssets = 
            riskOnUniswapV3Strategy.estimatedTotalAssets() + 
            riskOnHelper.getTotalCollateralTokenAmount(address(this), wantToken) - 
            riskOnHelper.calcCanonicalAssetValue(borrowToken, riskOnHelper.getCurrentBorrow(borrowToken, interestRateMode, address(this)), wantToken);
    }

    /// @notice Lend
    /// @param _amount The amount of lend
    function lend(uint256 _amount) external whenNotEmergency nonReentrant {
        // TODO share
        //MGM mean 'The total amount user lend must GT the minium total amount user lend
        require(netAmountUserLend[_msgSender()] + _amount >= minTotalAmountUserLend,"MGM");

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

        uint256 _collateralAmount = _amount.mul(2).div(3);
        uint256 _debtAmount = riskOnHelper.calcCanonicalAssetValue(wantToken, _amount.div(3), borrowToken);
        __addCollateral(_collateralAmount);
        __borrow(_debtAmount);
        riskOnUniswapV3Strategy.deposit(balanceOfToken(token0), balanceOfToken(token1));

        // calculate and mint 3 shares
        uint256 _collateralShares = _sharesForCollateral(_collateralAmount);
        uint256 _debtShares = _sharesForDebt(_debtAmount); 
        uint256 _lpShares = _sharesForLP(_amount);

        _mintCollateralShares(_collateralShares, _msgSender());
        _mintDebtShares(_debtShares, _msgSender());
        _mintLPShares(_lpShares, _msgSender());


        netMarketMakingAmount += _amount;

        netAmountUserLend[_msgSender()] += _amount;

        emit LendToStrategy(wantToken, _amount);
    }

    /// @notice Redeem
    /// @param _redeemShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @return _redeemBalance The balance of redeem
    function redeem(uint256 _redeemShares, uint256 _totalShares) external returns (uint256 _redeemBalance) {
        // TODO share and require
        uint256 _lpAmount = _lpForShares(lpShares[_msgSender()]);

        _redeemBalance = redeemToVault(_redeemShares, _totalShares);
        if (_redeemBalance > netMarketMakingAmount) {
            netMarketMakingAmount = 0;
        } else {
            netMarketMakingAmount -= _redeemBalance;
        }
        IERC20Upgradeable(wantToken).safeTransfer(msg.sender, _redeemBalance);

        // cannot netAmountUserLend sub _redeemBalance if _redeemBalance > netAmountUserLend;
        // _redeemShares, _totalShares is owned vault, no user
        netAmountUserLend[_msgSender()] = netAmountUserLend[_msgSender()] * _redeemBalance/ _lpAmount;

        // _redeemBalance is LP amount redeem 
        // calculate and burn lp shares
        uint256 _lpShares = _sharesForLP(_redeemBalance);
        _burnLPShares(_msgSender(), _lpShares);

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
        // calculate and mint 3 shares
        uint256 _collateralShares = 0;
        uint256 _debtShares = 0;
        uint256 _lpShares = 0;

        uint256 currentBorrow = riskOnHelper.getCurrentBorrow(borrowToken, interestRateMode, address(this));
        address aCollateralToken = riskOnHelper.getAToken(wantToken);
        if (_redeemShares == _totalShares) {
            redeemFromStrategy(_redeemShares, _totalShares);
            uint256 borrowTokenBalance = balanceOfToken(borrowToken);
            if (currentBorrow > borrowTokenBalance) {
                IUniswapV3(RiskOnConstant.UNISWAP_V3_ROUTER).exactOutputSingle(IUniswapV3.ExactOutputSingleParams(wantToken, borrowToken, fee, address(this), block.timestamp, currentBorrow - borrowTokenBalance, type(uint256).max, 0));
            }
            __repay(currentBorrow);
            uint256 _removeCollateralAmount = IERC20(aCollateralToken).balanceOf(address(this));
            __removeCollateral(aCollateralToken, _removeCollateralAmount);

            // calculate shares
            _collateralShares = _sharesForCollateral(_removeCollateralAmount);
            _debtShares = _sharesForDebt(currentBorrow);

        } else {
            redeemFromStrategy(_redeemShares, _totalShares);
            uint256 redeemBorrowTokenBalance = balanceOfToken(borrowToken);
            uint256 redeemCurrentBorrow = currentBorrow * _redeemShares / _totalShares;
            if (redeemCurrentBorrow > redeemBorrowTokenBalance) {
                IUniswapV3(RiskOnConstant.UNISWAP_V3_ROUTER).exactOutputSingle(IUniswapV3.ExactOutputSingleParams(wantToken, borrowToken, fee, address(this), block.timestamp, redeemCurrentBorrow - redeemBorrowTokenBalance, type(uint256).max, 0));
            }
            __repay(redeemCurrentBorrow);
            uint256 _removeCollateralAmount = IERC20(aCollateralToken).balanceOf(address(this)) * _redeemShares / _totalShares;
            __removeCollateral(aCollateralToken, _removeCollateralAmount);

            // calculate shares
            _collateralShares = _sharesForCollateral(_removeCollateralAmount);
            _debtShares = _sharesForDebt(redeemCurrentBorrow);
        }

        // burn shares
        _burnCollateralShares(_msgSender(),_collateralShares);
        _burnDebtShares(_msgSender(), _debtShares);

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

    function _mintCollateralShares(uint256 _sharesAmount, address _account) internal {
        totalCollateralShares += _sharesAmount;
        collateralShares[account] += _sharesAmount;
        emit MintShares(_recipient,_sharesAmount, uint8(0));
    }

    function _mintDebtShares(uint256 _sharesAmount, address _account) internal {
        totalDebtShares += _sharesAmount;
        debtShares[account] += _sharesAmount;
        emit MintShares(_recipient,_sharesAmount, uint8(1));
    }

    function _mintLPShares(uint256 _sharesAmount, address _account) internal {
        totalLPShares += _sharesAmount;
        lpShares[account] += _sharesAmount;
        emit MintShares(_recipient,_sharesAmount, uint8(2));
    }

    function _burnCollateralShares(address _account, uint256 _sharesAmount) internal {
        totalCollateralShares -= _sharesAmount;
        collateralShares[account] -= _sharesAmount;
        emit BurnShares(_recipient,_sharesAmount, uint8(0));
    }

    function _burnDebtShares(address _account, uint256 _sharesAmount) internal {
        totalDebtShares -= _sharesAmount;
        debtShares[account] -= _sharesAmount;
        emit BurnShares(_recipient,_sharesAmount, uint8(1));
    }

    function _burnLPShares(address _account, uint256 _sharesAmount) internal {
        totalLPShares -= _sharesAmount;
        lpShares[account] -= _sharesAmount;
        emit BurnShares(_recipient,_sharesAmount, uint8(2));
    }

    // Collateral Shares
    function getCollateralAmountPerShares() public view returns(uint256 _collateralAmountPerShares){
        // init _collateralAmountPerShares is 1 Token / 1 shares, 1 uint shares gets 1 unit Token
        // shares decamals is 27, Token is decimals()
        _collateralAmountPerShares = 10 ** IERC20MetadataUpgradeable(wantToken).decimals();
        uint256 _totalCollateralTokenAmount = riskOnHelper.getTotalCollateralTokenAmount(address(this), wantToken);
        if(_totalCollateralShares > 0) {
            _collateralAmountPerShares = _totalCollateralTokenAmount * 1e27 / totalCollateralShares;
        }
    }

    function _sharesForCollateral(uint _collateralAmount) internal view returns (uint) {
        // collateralAmountByShares = getTotalCollateralTokenAmount * 1e27 / totalCollateralShares
        //  100 amount / 1 shares => 100 amount *e27 / 1 shares *e27
        uint256 _collateralAmountPerShares = getCollateralAmountPerShares();
        // shares decimal 27
        return _collateralAmountPerShares == 0 ? 
            _collateralAmount*1e27 / 10 ** IERC20MetadataUpgradeable(wantToken).decimals() : 
            _collateralAmount * 1e27 / collateralAmountPerShares;
    }

    function _collateralForShares(uint _sharesAmount) internal view returns (uint) {
        uint256 _collateralAmountPerShares = getCollateralAmountPerShares();
        return _sharesAmount * _collateralAmountPerShares / 1e27; // = collateralAmount
    }

    // Debt Shares
    function getDebtAmountPerShares() public view returns(uint256 _debtAmountPerShares){
        // init _debtAmountPerShares is 1 debt Token / 1 shares, 1 uint shares gets 1 unit Token
        // shares decamals is 27, Token is decimals()
        _debtAmountPerShares = 10 ** IERC20MetadataUpgradeable(borrowToken).decimals();
        uint256 _totalDebtTokenAmount = riskOnHelper.getCurrentBorrow(borrowToken, interestRateMode, address(this));
        if(totalDebtShares > 0) {
            _debtAmountPerShares = _totalDebtTokenAmount * 1e27 / totalDebtShares;
        }
    }

    function _sharesForDebt(uint _debtAmount) internal view returns (uint) {
        // collateralAmountByShares = getTotalCollateralTokenAmount * 1e27 / totalCollateralShares
        //  100 amount / 1 shares => 100 amount *e27 / 1 shares *e27
        uint256 _debtAmountPerShares = getDebtAmountPerShares();
        // shares decimal 27
        return _debtAmountPerShares == 0 ? 
            _debtAmount*1e27 / 10 ** IERC20MetadataUpgradeable(borrowToken).decimals() : 
            _debtAmount * 1e27 / _debtAmountPerShares;
    }

    function _debtForShares(uint _sharesAmount) internal view returns (uint) {
        uint256 _debtAmountPerShares = getDebtAmountPerShares();
        return _sharesAmount * _debtAmountPerShares / 1e27; // = debtAmount
    }

    // LP Shares
    function getLPAmountPerShares() public view returns(uint256 _lpAmountPerShares){
        // init _lpAmountPerShares is 1 Token / 1 shares, 1 uint shares gets 1 unit Token
        // shares decamals is 27, Token is decimals()
        _lpAmountPerShares = 10 ** IERC20MetadataUpgradeable(wantToken).decimals();
        // ==== ?????? === use riskOnUniswapV3Strategy.estimatedTotalAssets() or netMarketMakingAmount
        uint256 _totalLPTokenAmount = riskOnUniswapV3Strategy.estimatedTotalAssets();
        if(totalLPShares > 0) {
            _lpAmountPerShares = _totalLPTokenAmount * 1e27 / totalLPShares;
        }
    }

    function _sharesForLP(uint _lpAmount) internal view returns (uint) {
        // lpAmountByShares = getLPAmountPerShares * 1e27 / totalLPShares
        //  100 amount / 1 shares => 100 amount *e27 / 1 shares *e27
        uint256 _lpAmountPerShares = getLPAmountPerShares();
        // shares decimal 27
        return _lpAmountPerShares == 0 ? 
            _lpAmount*1e27 / 10 ** IERC20MetadataUpgradeable(wantToken).decimals() : 
            _lpAmount * 1e27 / lpAmountPerShares;
    }

    function _lpForShares(uint _sharesAmount) internal view returns (uint) {
        uint256 _lpAmountPerShares = getLPAmountPerShares();
        return _sharesAmount * _lpAmountPerShares / 1e27; // = lpAmount
    }
}
