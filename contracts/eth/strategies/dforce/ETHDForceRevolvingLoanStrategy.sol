// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../ETHBaseStrategy.sol";

import "./../../enums/ProtocolEnum.sol";
import "../../../external/euler/IEulerDToken.sol";
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
    address internal constant EULER_ADDRESS = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    address internal constant DF = 0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0;
    address public constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public constant BPS = 10000;
    IUniswapV2Router2 public constant UNIROUTER2 =
        IUniswapV2Router2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public iToken;
    address public iController;
    address public rewardDistributorV3;
    address public priceOracle;
    address public eulerDToken;
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
        address _rewardDistributorV3,
        address _eulerDToken
    ) external initializer {
        borrowCount = 10;
        borrowFactor = 7500;
        borrowFactorMax = 7900;
        borrowFactorMin = 7100;
        borrowCount = 10;

        leverage = _calLeverage(7500, 10000, 10);
        leverageMax = _calLeverage(7900, 10000, 10);
        leverageMin = _calLeverage(7100, 10000, 10);
        address[] memory _wants = new address[](1);
        _wants[0] = _underlyingToken;
        iToken = _iToken;
        iController = _iController;
        priceOracle = _priceOracle;
        rewardDistributorV3 = _rewardDistributorV3;
        eulerDToken = _eulerDToken;
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
        _updateAllLeverage(_borrowCount);
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

    /// @inheritdoc ETHBaseStrategy
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
        (_rewardsTokens, _claimAmounts) = _claimRewardsAndReInvest();
        vault.report(_rewardsTokens, _claimAmounts);
    }

    /// @notice Rebalance the collateral of this strategy
    /// Requirements: only keeper can call
    function rebalance() external isKeeper {
        address _iToken = iToken;
        DFiToken(_iToken).borrowBalanceCurrent(address(this));
        (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowInfo(_iToken, borrowCount);
        _rebalance(_remainingAmount, _overflowAmount, _iToken);
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
            (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowStandardInfo(
                _iToken,
                borrowCount
            );
            _rebalance(_remainingAmount, _overflowAmount, _iToken);
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
            _repay(_redeemAmount, _repayBorrowAmount);
        }
    }

    // euler flashload call only by  euler
    function onFlashLoan(bytes memory data) external {
        address _eulerAddress = EULER_ADDRESS;
        require(msg.sender == _eulerAddress, "invalid call");
        (
            uint256 _mintAmount,
            uint256 _borrowAmount,
            uint256 _redeemAmount,
            uint256 _repayBorrowAmount,
            uint256 _flashLoanAmount,
            uint256 _origBalance
        ) = abi.decode(data, (uint256, uint256, uint256, uint256, uint256, uint256));
        uint256 _wethAmount = balanceOfToken(W_ETH);
        require(_wethAmount >= _origBalance + _flashLoanAmount, "not received enough");
        IWeth(W_ETH).withdraw(_wethAmount);
        DFiToken _dFiToken = DFiToken(iToken);
        if (_mintAmount > 0) {
            _dFiToken.mint{value: _mintAmount}(address(this));
        }
        if (_repayBorrowAmount > 0) {
            _dFiToken.repayBorrow{value: _repayBorrowAmount}();
        }
        if (_borrowAmount > 0) {
            _dFiToken.borrow(_borrowAmount);
        }
        if (_redeemAmount > 0) {
            _dFiToken.redeem(address(this), _redeemAmount);
        }
        IWeth(W_ETH).deposit{value: _flashLoanAmount}();
        IERC20Upgradeable(W_ETH).safeTransfer(_eulerAddress, _flashLoanAmount);
    }

    /// @notice Collect the rewards from third party protocol,then swap from the reward tokens to wanted tokens and reInvest
    /// @return _rewardTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function _claimRewardsAndReInvest()
        internal
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        address[] memory _holders = new address[](1);
        _holders[0] = address(this);
        address[] memory _iTokens = new address[](1);
        _iTokens[0] = iToken;
        IRewardDistributorV3(rewardDistributorV3).claimReward(_holders, _iTokens);
        _rewardTokens = new address[](1);
        _rewardTokens[0] = DF;
        _claimAmounts = new uint256[](1);
        address[] memory _wantTokens = wants;
        uint256[] memory _wantAmounts = new uint256[](1);
        uint256 _balanceOfDF = balanceOfToken(_rewardTokens[0]);
        _claimAmounts[0] = _balanceOfDF;
        if (_balanceOfDF > 0) {
            // swap from DF to WETH
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
            if (_balanceOfWETH > 0) {
                IWeth(W_ETH).withdraw(_balanceOfWETH);
                _wantAmounts[0] = _balanceOfWETH;
                DFiToken(_iTokens[0]).mint{value: _balanceOfWETH}(address(this));
            }
            emit SwapRewardsToWants(
                address(this),
                _rewardTokens,
                _claimAmounts,
                _wantTokens,
                _wantAmounts
            );
        }
    }

    /// @notice repayBorrow and redeem collateral
    function _repay(uint256 _redeemAmount, uint256 _repayBorrowAmount) internal {
        bytes memory _params = abi.encodePacked(
            uint256(0),
            uint256(0),
            _redeemAmount,
            _repayBorrowAmount,
            _repayBorrowAmount,
            balanceOfToken(W_ETH)
        );
        IEulerDToken(eulerDToken).flashLoan(_repayBorrowAmount, _params);
    }

    /// @notice Rebalance the collateral of this strategy
    function _rebalance(
        uint256 _remainingAmount,
        uint256 _overflowAmount,
        address _iToken
    ) internal {
        if (_remainingAmount > 0) {
            bytes memory _params = abi.encodePacked(
                _remainingAmount,
                _remainingAmount,
                uint256(0),
                uint256(0),
                _remainingAmount,
                balanceOfToken(W_ETH)
            );
            IEulerDToken(eulerDToken).flashLoan(_remainingAmount, _params);
        } else if (_overflowAmount > 0) {
            uint256 _exchangeRateStored = DFiToken(_iToken).exchangeRateStored();
            uint256 _redeemAmount = (_overflowAmount * 1e18 + _exchangeRateStored - 1) /
                _exchangeRateStored;
            _repay(_redeemAmount, _overflowAmount);
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
            uint256 _capitalAmount = _collateralAmount - _debtAmount;
            uint256 _BPS = BPS;
            uint256 _needCollateralAmount = (_capitalAmount * leverage) / _BPS;
            uint256 _needCollateralAmountMin = (_capitalAmount * leverageMin) / _BPS;
            uint256 _needCollateralAmountMax = (_capitalAmount * leverageMax) / _BPS;
            if (_needCollateralAmountMin > _collateralAmount) {
                _remainingAmount = _needCollateralAmount - _collateralAmount;
            } else if (_needCollateralAmountMax < _collateralAmount) {
                _overflowAmount = _collateralAmount - _needCollateralAmount;
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
            uint256 _needCollateralAmount = (_capitalAmount * leverage) / BPS;
            if (_needCollateralAmount > _collateralAmount) {
                _remainingAmount = _needCollateralAmount - _collateralAmount;
            } else if (_needCollateralAmount < _collateralAmount) {
                _overflowAmount = _collateralAmount - _needCollateralAmount;
            }
        }
    }

    /// @notice Returns the new leverage with the fix borrowFactor
    /// @return _borrowFactor The borrow factor
    function _getNewLeverage(uint256 _borrowFactor) internal view returns (uint256) {
        return _calLeverage(_borrowFactor, BPS, borrowCount);
    }

    /// @notice update all leverage (leverage leverageMax leverageMin)
    function _updateAllLeverage(uint256 _borrowCount) internal {
        uint256 _bps = BPS;
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
