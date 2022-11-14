// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../ETHBaseStrategy.sol";

import "./../../enums/ProtocolEnum.sol";
import "../../../external/dforce/DFiToken.sol";
import "../../../external/dforce/IDForceController.sol";
import "../../../external/dforce/IDForcePriceOracle.sol";
import "../../../external/dforce/IRewardDistributorV3.sol";
import "../../../external/uniswap/IUniswapV2Router2.sol";
import "../../../external/weth/IWeth.sol";

/// @title ETHDForceRevolvingLoanStrategy
/// @notice Investment strategy of investing in eth/wsteth and revolving lending through post-staking via DForceRevolvingLoan
/// @author Bank of Chain Protocol Inc
contract ETHDForceRevolvingLoanStrategy is ETHBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address internal constant DF = 0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0;
    address public constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public constant BPS = 10000;
    IUniswapV2Router2 public constant UNIROUTER2 =
        IUniswapV2Router2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public iToken;
    address public iController;
    address public rewardDistributorV3;
    address public priceOracle;
    uint256 public borrowFactor;
    uint256 public borrowFactorMax;
    uint256 public borrowFactorMin;
    uint256 public borrowCount;
    uint256 public leverage;
    uint256 public leverageMax;
    uint256 public leverageMin;

    /// @param _borrowFactor The new borrow factor
    event UpdateBorrowFactor(uint256 _borrowFactor);
    /// @param _borrowFactorMax The new max borrow factor
    event UpdateBorrowFactorMax(uint256 _borrowFactorMax);
    /// @param _borrowFactorMin The new min borrow factor
    event UpdateBorrowFactorMin(uint256 _borrowFactorMin);
    /// @param _borrowCount The new count Of borrow
    event UpdateBorrowCount(uint256 _borrowCount);
    /// @param _remainingAmount The amount of aToken will still be used as collateral to borrow eth
    /// @param _overflowAmount The amount of debt token that exceeds the maximum allowable loan
    event Rebalance(uint256 _remainingAmount, uint256 _overflowAmount);

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _name The name of strategy
    /// @param _underlyingToken The lending asset of the Vault contract
    /// @param _iToken The iToken which wrap `_underlyingToken`.
    /// @param _iController The controller which control `_underlyingToken`.
    /// @param _rewardDistributorV3 The df which wrap `_underlyingToken`.
    function initialize(
        address _vault,
        string memory _name,
        address _underlyingToken,
        address _iToken,
        address _iController,
        address _priceOracle,
        address _rewardDistributorV3
    ) external initializer {
        borrowCount = 10;
        borrowFactor = 8000;
        borrowFactorMax = 8500;
        borrowFactorMin = 7500;
        borrowCount = 10;

        leverage = _calLeverage(8000, 10000, 10);
        leverageMax = _calLeverage(8500, 10000, 10);
        leverageMin = _calLeverage(7500, 10000, 10);
        address[] memory _wants = new address[](1);
        _wants[0] = _underlyingToken;
        iToken = _iToken;
        iController = _iController;
        priceOracle = _priceOracle;
        rewardDistributorV3 = _rewardDistributorV3;
        super._initialize(_vault, uint16(ProtocolEnum.DForce), _name, _wants);
        IERC20Upgradeable(DF).safeApprove(address(UNIROUTER2), type(uint256).max);
    }

    /// @notice Sets `_borrowFactor` to `borrowFactor`
    /// @param _borrowFactor The new value of `borrowFactor`
    /// Requirements: only vault manager can call
    function setBorrowFactor(uint256 _borrowFactor) external isVaultManager {
        require(
            _borrowFactor < BPS &&
                _borrowFactor >= borrowFactorMin &&
                _borrowFactor <= borrowFactorMax,
            "setting output the range"
        );
        borrowFactor = _borrowFactor;
        leverage = _getNewLeverage(_borrowFactor);

        emit UpdateBorrowFactor(_borrowFactor);
    }

    /// @notice Sets `_borrowFactorMax` to `borrowFactorMax`
    /// @param _borrowFactorMax The new value of `borrowFactorMax`
    /// Requirements: only vault manager can call
    function setBorrowFactorMax(uint256 _borrowFactorMax) external isVaultManager {
        require(
            _borrowFactorMax < BPS && _borrowFactorMax > borrowFactor,
            "setting output the range"
        );
        borrowFactorMax = _borrowFactorMax;
        leverageMax = _getNewLeverage(_borrowFactorMax);

        emit UpdateBorrowFactorMax(_borrowFactorMax);
    }

    /// @notice Sets `_borrowFactorMin` to `borrowFactorMin`
    /// @param _borrowFactorMin The new value of `borrowFactorMin`
    /// Requirements: only vault manager can call
    function setBorrowFactorMin(uint256 _borrowFactorMin) external isVaultManager {
        require(
            _borrowFactorMin < BPS && _borrowFactorMin < borrowFactor,
            "setting output the range"
        );
        borrowFactorMin = _borrowFactorMin;
        leverageMin = _getNewLeverage(_borrowFactorMin);

        emit UpdateBorrowFactorMin(_borrowFactorMin);
    }

    /// @notice Sets `_borrowCount` to `borrowCount`
    /// @param _borrowCount The new value of `borrowCount`
    /// Requirements: only keeper can call
    function setBorrowCount(uint256 _borrowCount) external isKeeper {
        require(_borrowCount <= 20, "setting output the range");
        borrowCount = _borrowCount;
        _updateAllLeverage();
        emit UpdateBorrowCount(_borrowCount);
    }

    /// @notice Return the version of strategy
    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc ETHBaseStrategy
    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
    }

    /// @inheritdoc ETHBaseStrategy
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
    }

    /// @inheritdoc ETHBaseStrategy
    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        )
    {
        address _iTokenTmp = iToken;
        _tokens = wants;
        _amounts = new uint256[](1);
        _amounts[0] =
            (balanceOfToken(_iTokenTmp) * DFiToken(_iTokenTmp).exchangeRateStored()) /
            1e18 +
            balanceOfToken(_tokens[0]) -
            DFiToken(_iTokenTmp).borrowBalanceStored(address(this));
    }

    /// @notice Return the third party protocol's pool total assets in USD.
    function get3rdPoolAssets() external view override returns (uint256) {
        address _iTokenTmp = iToken;
        uint256 _iTokenTotalSupply = (DFiToken(_iTokenTmp).totalSupply() *
            DFiToken(_iTokenTmp).exchangeRateStored()) / 1e18;
        return _iTokenTotalSupply != 0 ? queryTokenValueInETH(wants[0], _iTokenTotalSupply) : 0;
    }

    /// @inheritdoc ETHBaseStrategy
    function repay(
        uint256 _repayShares,
        uint256 _totalShares,
        uint256 _outputCode
    )
        public
        virtual
        override
        onlyVault
        returns (address[] memory _assets, uint256[] memory _amounts)
    {
        // if withdraw all need claim rewards
        if (_repayShares == _totalShares) {
            harvest();
        }
        return super.repay(_repayShares, _totalShares, _outputCode);
    }

    /// @inheritdoc ETHBaseStrategy
    function harvest()
        public
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        // sell reward token
        (
            bool _claimIsWorth,
            address[] memory _rewardsTokens,
            uint256[] memory _claimAmounts,
            address[] memory _wantTokens,
            uint256[] memory _wantAmounts
        ) = _claimRewardsAndReInvest();
        if (_claimIsWorth) {
            vault.report(_rewardsTokens, _claimAmounts);
            emit SwapRewardsToWants(
                address(this),
                _rewardsTokens,
                _claimAmounts,
                _wantTokens,
                _wantAmounts
            );
        }
    }

    /// @notice Rebalance the collateral of this strategy
    /// Requirements: only keeper can call
    function rebalance() external isKeeper {
        address _iToken = iToken;
        uint256 _borrowCount = borrowCount;
        DFiToken(_iToken).borrowBalanceCurrent(address(this));
        (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowInfo(_iToken, _borrowCount);
        _rebalance(_remainingAmount, _overflowAmount, _iToken, _borrowCount);
    }

    /// @notice Returns the info of borrow.
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow
    /// @return _overflowAmount The amount of aToken that exceeds the maximum allowable loan
    function borrowInfo() public view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        (_remainingAmount, _overflowAmount) = _borrowInfo(iToken, borrowCount);
    }

    /// @inheritdoc ETHBaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        uint256 _amount = _amounts[0];
        if (_amount > 0) {
            address _iToken = iToken;
            DFiToken(_iToken).mint{value: _amount}(address(this));
            IDForceController _iController = IDForceController(iController);
            if (!_iController.hasEnteredMarket(address(this), _iToken)) {
                address[] memory _iTokens = new address[](1);
                _iTokens[0] = _iToken;
                _iController.enterMarkets(_iTokens);
            }
            DFiToken(_iToken).borrowBalanceCurrent(address(this));
            uint256 _borrowCount = borrowCount;
            (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowStandardInfo(
                _iToken,
                _borrowCount
            );
            _rebalance(_remainingAmount, _overflowAmount, _iToken, _borrowCount);
        }
    }

    /// @inheritdoc ETHBaseStrategy
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        address _iToken = iToken;
        uint256 _collateralITokenAmount = balanceOfToken(_iToken);
        uint256 _redeemAmount = (_collateralITokenAmount * _withdrawShares) / _totalShares;
        DFiToken _dFiToken = DFiToken(_iToken);
        uint256 _debtAmount = _dFiToken.borrowBalanceCurrent(address(this));
        uint256 _repayBorrowAmount = (_debtAmount * _withdrawShares) / _totalShares;
        if (_redeemAmount > 0) {
            uint256 _exchangeRateStored = _dFiToken.exchangeRateStored();
            uint256 _collateralAmount = (_collateralITokenAmount * _exchangeRateStored) / 1e18;
            uint256 _leverage = leverage;
            uint256 _newDebtAmount = (_debtAmount - _repayBorrowAmount) * _leverage;
            uint256 _newCollateralAmount = (((_collateralITokenAmount - _redeemAmount) *
                _exchangeRateStored) / 1e18) * (_leverage - BPS);
            if (_newDebtAmount > _newCollateralAmount) {
                uint256 _decreaseAmount = (_newDebtAmount - _newCollateralAmount) / BPS;
                _redeemAmount = _redeemAmount + (_decreaseAmount * 1e18) / _exchangeRateStored;
                _repayBorrowAmount = _repayBorrowAmount + _decreaseAmount;
            } else {
                uint256 _increaseAmount = (_newCollateralAmount - _newDebtAmount) / BPS;

                _redeemAmount = _redeemAmount - (_increaseAmount * 1e18) / _exchangeRateStored;
                _repayBorrowAmount = _repayBorrowAmount - _increaseAmount;
            }
            _repay(_redeemAmount, _repayBorrowAmount, false, _iToken, borrowCount);
        }
    }

    /// @notice Collect the rewards from third party protocol,then swap from the reward tokens to wanted tokens and reInvest
    /// @return _claimIsWorth The boolean value to check the claim action is worth or not
    /// @return _rewardTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    /// @return _wantTokens The address list of the wanted token
    /// @return _wantAmounts The amount list of the wanted token
    function _claimRewardsAndReInvest()
        internal
        returns (
            bool _claimIsWorth,
            address[] memory _rewardTokens,
            uint256[] memory _claimAmounts,
            address[] memory _wantTokens,
            uint256[] memory _wantAmounts
        )
    {
        address[] memory _holders = new address[](1);
        _holders[0] = address(this);
        address[] memory _iTokens = new address[](1);
        _iTokens[0] = iToken;
        IRewardDistributorV3(rewardDistributorV3).claimReward(_holders, _iTokens);
        _rewardTokens = new address[](1);
        _rewardTokens[0] = DF;
        _claimAmounts = new uint256[](1);
        _wantTokens = wants;
        _wantAmounts = new uint256[](1);
        uint256 _balanceOfDF = balanceOfToken(_rewardTokens[0]);
        _claimAmounts[0] = _balanceOfDF;
        if (_balanceOfDF > 0) {
            _claimIsWorth = true;
            // swap from DF to WETH
            IERC20Upgradeable(DF).safeApprove(address(UNIROUTER2), 0);
            IERC20Upgradeable(DF).safeApprove(address(UNIROUTER2), _balanceOfDF);
            //set up sell reward path
            address[] memory _dfSellPath = new address[](2);
            _dfSellPath[0] = DF;
            _dfSellPath[1] = W_ETH;
            UNIROUTER2.swapExactTokensForTokens(
                _balanceOfDF,
                0,
                _dfSellPath,
                address(this),
                block.timestamp
            );
            uint256 _balanceOfWETH = balanceOfToken(W_ETH);
            IWeth(W_ETH).withdraw(_balanceOfWETH);

            _wantAmounts[0] = _balanceOfWETH;
            DFiToken(_iTokens[0]).mint{value: _wantAmounts[0]}(address(this));
        }
    }

    /// @notice repayBorrow and redeem collateral
    function _repay(
        uint256 _redeemAmount,
        uint256 _repayBorrowAmount,
        bool _allRepayBorrow,
        address _iToken,
        uint256 _borrowCount
    ) internal {
        address _want = wants[0];
        address _iTokenTemp = _iToken;
        uint256 _redeemAmountTemp = _redeemAmount;
        uint256 _repayBorrowAmountTemp = _repayBorrowAmount;
        DFiToken _dFiToken = DFiToken(_iTokenTemp);
        IDForceController _iController = IDForceController(iController);
        uint256 _collateralFactorMantissa = _iController
            .markets(_iTokenTemp)
            .collateralFactorMantissa;
        uint256 _underlyingPrice = IDForcePriceOracle(priceOracle).getUnderlyingPrice(_iTokenTemp);
        // max borrowCount + 2
        for (uint256 i = 0; i < 22; i++) {
            (uint256 _equity, , , uint256 _borrowedValue) = _iController.calcAccountEquity(
                address(this)
            );
            if (_equity > 0 && (_allRepayBorrow || _redeemAmountTemp > 0)) {
                uint256 _allowRedeemAmount = 0;
                {
                    uint256 _exchangeRateStored = _dFiToken.exchangeRateStored();
                    uint256 _balanceOfIToken = balanceOfToken(_iTokenTemp);
                    uint256 _newBalanceOfIToken = (((_borrowedValue *
                        1e18 +
                        _collateralFactorMantissa -
                        1) / _collateralFactorMantissa) *
                        1e18 +
                        (_underlyingPrice * _exchangeRateStored) -
                        1) / (_underlyingPrice * _exchangeRateStored);
                    if (_balanceOfIToken > _newBalanceOfIToken) {
                        _allowRedeemAmount = _balanceOfIToken - _newBalanceOfIToken;
                    }
                }
                if (_allowRedeemAmount > 0) {
                    {
                        uint256 _setupRedeemAmount = _allowRedeemAmount;
                        if ((!_allRepayBorrow) && _setupRedeemAmount > _redeemAmountTemp) {
                            _setupRedeemAmount = _redeemAmountTemp;
                        }
                        _dFiToken.redeem(address(this), _setupRedeemAmount);
                        if (!_allRepayBorrow) {
                            _redeemAmountTemp = _redeemAmountTemp - _setupRedeemAmount;
                        }
                    }
                    if (_allRepayBorrow) {
                        uint256 _setupRepayAmount = balanceOfToken(_want);
                        if (_setupRepayAmount > 0) {
                            _dFiToken.repayBorrow{value: _setupRepayAmount}();
                        }
                    } else if (_repayBorrowAmountTemp > 0) {
                        uint256 _setupRepayAmount = balanceOfToken(_want);
                        if (_setupRepayAmount > _repayBorrowAmountTemp) {
                            _setupRepayAmount = _repayBorrowAmountTemp;
                        }
                        _dFiToken.repayBorrow{value: _setupRepayAmount}();
                        _repayBorrowAmountTemp = _repayBorrowAmountTemp - _setupRepayAmount;
                    }
                } else {
                    break;
                }
            } else {
                break;
            }
        }
    }

    /// @notice Rebalance the collateral of this strategy
    function _rebalance(
        uint256 _remainingAmount,
        uint256 _overflowAmount,
        address _iToken,
        uint256 _borrowCount
    ) internal {
        IDForceController _iController = IDForceController(iController);
        address _want = wants[0];
        DFiToken _dFiToken = DFiToken(_iToken);
        if (_remainingAmount > 0) {
            uint256 _increaseDebtAmount = _remainingAmount;
            uint256 _borrowFactorMantissa = _iController.markets(_iToken).borrowFactorMantissa;
            uint256 _underlyingPrice = IDForcePriceOracle(priceOracle).getUnderlyingPrice(_iToken);
            for (uint256 i = 0; i < _borrowCount; i++) {
                (uint256 _equity, , , ) = _iController.calcAccountEquity(address(this));
                if (_equity > 0 && _increaseDebtAmount > 0) {
                    uint256 _allowBorrowAmount = (_equity * _borrowFactorMantissa) /
                        (_underlyingPrice * 1e18);
                    if (_allowBorrowAmount > 0) {
                        uint256 _setupBorrowAmount = _allowBorrowAmount;
                        if (_increaseDebtAmount < _setupBorrowAmount) {
                            _setupBorrowAmount = _increaseDebtAmount;
                        }
                        _dFiToken.borrow(_setupBorrowAmount);
                        uint256 _setupAmount = balanceOfToken(_want);
                        if (_setupAmount > 0) {
                            _dFiToken.mint{value: _setupAmount}(address(this));
                        }
                        _increaseDebtAmount = _increaseDebtAmount - _setupBorrowAmount;
                    } else {
                        break;
                    }
                } else {
                    break;
                }
            }
        } else if (_overflowAmount > 0) {
            _repay(0, _overflowAmount, true, _iToken, _borrowCount);
        }
        if (_remainingAmount + _overflowAmount > 0) {
            emit Rebalance(_remainingAmount, _overflowAmount);
        }
    }

    /// @notice Returns the info of borrow.
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow eth
    /// @return _overflowAmount The amount of debt token that exceeds the maximum allowable loan
    function _borrowInfo(address _iToken, uint256 _borrowCount)
        private
        view
        returns (uint256 _remainingAmount, uint256 _overflowAmount)
    {
        if (_borrowCount == 0) {
            _overflowAmount = DFiToken(_iToken).borrowBalanceStored(address(this));
        } else {
            uint256 _debtAmount = DFiToken(_iToken).borrowBalanceStored(address(this));
            uint256 _collateralAmount = (balanceOfToken(_iToken) *
                DFiToken(_iToken).exchangeRateStored()) / 1e18;
            uint256 _leverage = leverage;
            uint256 _leverageMax = leverageMax;
            uint256 _leverageMin = leverageMin;
            uint256 _needCollateralAmount = (_debtAmount * _leverage) / (_leverage - BPS);
            uint256 _needCollateralAmountMin = (_debtAmount * _leverageMax) / (_leverageMax - BPS);
            uint256 _needCollateralAmountMax = (_debtAmount * _leverageMin) / (_leverageMin - BPS);
            if (_needCollateralAmountMin > _collateralAmount) {
                _overflowAmount =
                    (_leverage * _debtAmount - (_leverage - BPS) * _collateralAmount) /
                    BPS;
            } else if (_needCollateralAmountMax < _collateralAmount) {
                _remainingAmount =
                    ((_leverage - BPS) * _collateralAmount - _leverage * _debtAmount) /
                    BPS;
            }
        }
    }

    /// @notice Returns the info of borrow with default borrowFactor
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow
    /// @return _overflowAmount The amount of debt token that exceeds the maximum allowable loan
    function _borrowStandardInfo(address _iToken, uint256 _borrowCount)
        private
        view
        returns (uint256 _remainingAmount, uint256 _overflowAmount)
    {
        if (_borrowCount == 0) {
            _overflowAmount = DFiToken(_iToken).borrowBalanceStored(address(this));
        } else {
            uint256 _debtAmount = DFiToken(_iToken).borrowBalanceStored(address(this));
            uint256 _collateralAmount = (balanceOfToken(_iToken) *
                DFiToken(_iToken).exchangeRateStored()) / 1e18;
            uint256 _capitalAmount = _collateralAmount - _debtAmount;
            uint256 _leverage = leverage;
            uint256 _needCollateralAmount = (_debtAmount * _leverage) / (_leverage - BPS);
            if (_needCollateralAmount > _collateralAmount) {
                _overflowAmount =
                    (_leverage * _debtAmount - (_leverage - BPS) * _collateralAmount) /
                    BPS;
            } else if (_needCollateralAmount < _collateralAmount) {
                _remainingAmount =
                    ((_leverage - BPS) * _collateralAmount - _leverage * _debtAmount) /
                    BPS;
            }
        }
    }

    /// @notice Returns the new leverage with the fix borrowFactor
    /// @return _borrowFactor The borrow factor
    function _getNewLeverage(uint256 _borrowFactor) internal view returns (uint256) {
        uint256 _bps = BPS;
        uint256 _borrowCount = borrowCount;
        return _calLeverage(_borrowFactor, _bps, _borrowCount);
    }

    /// @notice update all leverage (leverage leverageMax leverageMin)
    function _updateAllLeverage() internal {
        uint256 _bps = BPS;
        uint256 _borrowCount = borrowCount;
        leverage = _calLeverage(borrowFactor, _bps, _borrowCount);
        leverageMax = _calLeverage(borrowFactorMax, _bps, _borrowCount);
        leverageMin = _calLeverage(borrowFactorMin, _bps, _borrowCount);
    }

    /// @notice Returns the leverage  with by _borrowFactor _bps  _borrowCount
    /// @return _borrowFactor The borrow factor
    function _calLeverage(
        uint256 _borrowFactor,
        uint256 _bps,
        uint256 _borrowCount
    ) private pure returns (uint256) {
        // q = borrowFactor/bps
        // n = borrowCount + 1;
        // _leverage = (1-q^n)/(1-q),(n>=1, q=0.8)
        uint256 _leverage = _bps;
        if (_borrowCount >= 1) {
            _leverage =
                (_bps * _bps - (_borrowFactor**(_borrowCount + 1)) / (_bps**(_borrowCount - 1))) /
                (_bps - _borrowFactor);
        }
        return _leverage;
    }
}
