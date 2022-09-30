// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../enums/ProtocolEnum.sol";
import "../ETHBaseStrategy.sol";
import "../../../external/aave/IAaveLendingPool.sol";
import "../../../external/aave/IAaveLendingPoolProvider.sol";
import "../../../external/aave/IAavePriceOracle.sol";
import "../../../external/curve/ICurveLiquidityFarmingPool.sol";
import "../../../external/weth/IWeth.sol";
import "hardhat/console.sol";

contract AaveWETHstETHStrategy is ETHBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public constant DEBT_W_ETH = 0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address public constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant A_ST_ETH = 0x1982b2F5814301d4e9a8b0201555376e62F82428;
    address public constant A_WETH = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    uint256 public constant BPS = 10000;
    /**
     * @dev Aave Lending Pool Provider
     */
    IAaveLendingPoolProvider internal constant aaveProvider =
        IAaveLendingPoolProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    ICurveLiquidityFarmingPool private curvePool;
    uint256 public borrowFactor;
    uint256 public borrowFactorMax;
    uint256 public borrowFactorMin;
    uint256 public borrowCount;

    /// Events

    /// @param _borrowFactor The new borrow factor
    event UpdateBorrowFactor(uint256 _borrowFactor);
    /// @param _borrowFactorMax The new max borrow factor
    event UpdateBorrowFactorMax(uint256 _borrowFactorMax);
    /// @param _borrowFactorMin The new min borrow factor
    event UpdateBorrowFactorMin(uint256 _borrowFactorMin);
    /// @param _borrowCount The new count Of borrow
    event UpdateBorrowCount(uint256 _borrowCount);

    function initialize(address _vault, string memory _name) external initializer {
        curvePool = ICurveLiquidityFarmingPool(
            address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022)
        );
        address[] memory _wants = new address[](1);
        //weth
        _wants[0] = NativeToken.NATIVE_TOKEN;
        borrowFactor = 6900;
        borrowFactorMin = 6300;
        borrowFactorMax = 7500;
        borrowCount = 3;
        super._initialize(_vault, uint16(ProtocolEnum.Aave), _name, _wants);
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

        emit UpdateBorrowFactor(_borrowFactor);
    }

    /// @notice Sets `_borrowFactorMax` to `borrowFactorMax`
    /// @param _borrowFactorMax The new value of `borrowFactorMax`
    /// Requirements: only vault manager can call
    function setBorrowFactorMax(uint256 _borrowFactorMax) external isVaultManager {
        require(
            _borrowFactorMax < BPS && _borrowFactorMax > borrowFactorMin,
            "setting output the range"
        );
        borrowFactorMax = _borrowFactorMax;

        emit UpdateBorrowFactorMax(_borrowFactorMax);
    }

    /// @notice Sets `_borrowFactorMin` to `borrowFactorMin`
    /// @param _borrowFactorMin The new value of `borrowFactorMin`
    /// Requirements: only vault manager can call
    function setBorrowFactorMin(uint256 _borrowFactorMin) external isVaultManager {
        require(
            _borrowFactorMin < BPS && _borrowFactorMin < borrowFactorMax,
            "setting output the range"
        );
        borrowFactorMin = _borrowFactorMin;

        emit UpdateBorrowFactorMin(_borrowFactorMin);
    }

    /// @notice Sets `_borrowCount` to `borrowCount`
    /// @param _borrowCount The new value of `borrowCount`
    /// Requirements: only vault manager can call
    function setBorrowCount(uint256 _borrowCount) external isVaultManager {
        require(_borrowCount <= 10, "setting output the range");
        borrowCount = _borrowCount;

        emit UpdateBorrowCount(_borrowCount);
    }

    /// @inheritdoc ETHBaseStrategy
    function getVersion() external pure virtual override returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc ETHBaseStrategy
    function getWantsInfo()
        external
        view
        virtual
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
        OutputInfo memory _info = _outputsInfo[0];
        _info.outputCode = 0;
        _info.outputTokens = wants;
    }

    /// @inheritdoc ETHBaseStrategy
    function getPositionDetail()
        public
        view
        virtual
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        )
    {
        _tokens = wants;
        _amounts = new uint256[](1);

        uint256 _wethDebtAmount = balanceOfToken(DEBT_W_ETH);
        uint256 _wethAmount = balanceOfToken(W_ETH) + balanceOfToken(NativeToken.NATIVE_TOKEN);
        uint256 _stEthAmount = balanceOfToken(A_ST_ETH) + balanceOfToken(ST_ETH);
        console.log("_wethDebtAmount,_wethAmount,_astEthAmount,_stEthAmount");
        console.log(
            _wethDebtAmount,
            _wethAmount,
            balanceOfToken(A_ST_ETH),
            balanceOfToken(ST_ETH)
        );

        _isETH = true;
        _ethValue = queryTokenValueInETH(ST_ETH, _stEthAmount) + _wethAmount - _wethDebtAmount;
    }

    /// @inheritdoc ETHBaseStrategy
    function get3rdPoolAssets() external view override returns (uint256) {
        return queryTokenValueInETH(ST_ETH, IERC20Upgradeable(A_ST_ETH).totalSupply());
    }

    /// @inheritdoc ETHBaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        uint256 _amount = _amounts[0];
        address _asset = _assets[0];
        curvePool.exchange{value: _amount}(0, 1, _amount, 0);
        uint256 _receivedStETHAmount = balanceOfToken(ST_ETH);
        if (_receivedStETHAmount > 0) {
            address _lendingPoolAddress = aaveProvider.getLendingPool();
            IAaveLendingPool _aaveLendingPool = IAaveLendingPool(_lendingPoolAddress);
            IAavePriceOracle _aaveOracle = IAavePriceOracle(aaveProvider.getPriceOracle());
            uint256 _stETHPrice = _aaveOracle.getAssetPrice(ST_ETH);

            console.log(
                "currentVariableBorrowRate,currentStableBorrowRate",
                _aaveLendingPool.getReserveData(W_ETH).currentVariableBorrowRate,
                _aaveLendingPool.getReserveData(W_ETH).currentStableBorrowRate
            );

            uint256 _beforeBalanceOfAStETH = balanceOfToken(A_ST_ETH);
            IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, 0);
            IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, _receivedStETHAmount);
            _aaveLendingPool.deposit(ST_ETH, _receivedStETHAmount, address(this), 0);
            uint256 _astETHAmount = balanceOfToken(A_ST_ETH) - _beforeBalanceOfAStETH;
            uint256 _borrowCount = borrowCount;
            for (uint256 i = 0; i < _borrowCount; i++) {
                if (_astETHAmount > 10) {
                    console.log(i, _astETHAmount);
                    uint256 _increaseAstEthAmount = _borrowEthAndDepositStEth(
                        _astETHAmount,
                        _stETHPrice,
                        _lendingPoolAddress
                    );
                    _astETHAmount = _increaseAstEthAmount;
                } else {
                    break;
                }
            }
            console.log(
                "A_ST_ETH,DEBT_W_ETH=",
                balanceOfToken(A_ST_ETH),
                balanceOfToken(DEBT_W_ETH)
            );
        }
    }

    /// @notice redeem aToken ,then exchange to debt Token ,and finally repay the debt
    /// @param _astETHAmount The amount of aToken that will still be to redeem
    /// @param _stETHPrice the price of stETH in ETH
    /// @param _lendingPoolAddress The address of lendingPool
    /// @return _increaseAstEthAmount The amount of increase aToken
    function _borrowEthAndDepositStEth(
        uint256 _astETHAmount,
        uint256 _stETHPrice,
        address _lendingPoolAddress
    ) private returns (uint256 _increaseAstEthAmount) {
        IAaveLendingPool _aaveLendingPool = IAaveLendingPool(_lendingPoolAddress);
        uint256 _astETHValueInEth = (_astETHAmount * _stETHPrice) / 1e18;
        uint256 _borrowAmount = (_astETHValueInEth * borrowFactor) / BPS;
        _aaveLendingPool.borrow(W_ETH, _borrowAmount, 2, 0, address(this));
        IWeth(W_ETH).withdraw(balanceOfToken(W_ETH));
        uint256 _ethAmount = address(this).balance;
        curvePool.exchange{value: _ethAmount}(0, 1, _ethAmount, 0);
        uint256 _receivedStETHAmount = balanceOfToken(ST_ETH);

        console.log("_ethAmount,_receivedStETHAmount,_receivedStETHAmountInETH");
        console.log(_ethAmount, _receivedStETHAmount, (_receivedStETHAmount * _stETHPrice) / 1e18);
        IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, 0);
        IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, _receivedStETHAmount);
        uint256 _beforeBalanceOfAStETH = balanceOfToken(A_ST_ETH);
        _aaveLendingPool.deposit(ST_ETH, _receivedStETHAmount, address(this), 0);
        _increaseAstEthAmount = balanceOfToken(A_ST_ETH) - _beforeBalanceOfAStETH;
    }

    /// @notice redeem aToken ,then exchange to debt Token ,and finally repay the debt
    /// @param _astETHAmount The amount of aToken that will still be to redeem
    /// @param _wethDebtAmount The amount of debt token that will still be to repay
    /// @param _stETHPrice the price of stETH in ETH
    function _repay(
        uint256 _astETHAmount,
        uint256 _wethDebtAmount,
        uint256 _stETHPrice
    ) private {
        ICurveLiquidityFarmingPool _curvePool = curvePool;
        address _curvePoolAddress = address(_curvePool);
        address _lendingPoolAddress = aaveProvider.getLendingPool();
        IAaveLendingPool _aaveLendingPool = IAaveLendingPool(_lendingPoolAddress);
        uint256 _borrowFactorMax = borrowFactorMax;
        uint256 _repayCount = borrowCount * 2;
        for (uint256 i = 0; i < _repayCount; i++) {
            uint256 _allowWithdrawAmount = balanceOfToken(A_ST_ETH) -
                (balanceOfToken(DEBT_W_ETH) * 1e18 * BPS) /
                _borrowFactorMax /
                _stETHPrice;
            console.log("(i, _astETHAmount, _allowWithdrawAmount)=");
            console.log(i, _astETHAmount, _allowWithdrawAmount);
            if (_allowWithdrawAmount > 0 && _astETHAmount > 1) {
                uint256 _setupWithdraw = _allowWithdrawAmount;
                if (_allowWithdrawAmount >= _astETHAmount) {
                    _setupWithdraw = _astETHAmount;
                }
                console.log("(_setupWithdraw,_allowWithdrawAmount)=");
                console.log(_setupWithdraw, _allowWithdrawAmount);
                _aaveLendingPool.withdraw(ST_ETH, _setupWithdraw, address(this));
                _astETHAmount = _astETHAmount - _setupWithdraw;
                uint256 _receivedStETHAmount = balanceOfToken(ST_ETH);
                IERC20Upgradeable(ST_ETH).safeApprove(_curvePoolAddress, 0);
                IERC20Upgradeable(ST_ETH).safeApprove(_curvePoolAddress, _receivedStETHAmount);
                _curvePool.exchange(1, 0, _receivedStETHAmount, 0);
                if (_wethDebtAmount > 0) {
                    uint256 _ethAmount = balanceOfToken(NativeToken.NATIVE_TOKEN);
                    console.log("_ethAmount,_receivedStETHAmount,_receivedStETHAmountInETH");
                    console.log(
                        _ethAmount,
                        _receivedStETHAmount,
                        (_receivedStETHAmount * _stETHPrice) / 1e18
                    );
                    uint256 _setupRepay;
                    if (_ethAmount >= _wethDebtAmount) {
                        _setupRepay = _wethDebtAmount;
                    } else {
                        _setupRepay = _ethAmount;
                    }
                    IWeth(W_ETH).deposit{value: _setupRepay}();
                    IERC20Upgradeable(W_ETH).safeApprove(_lendingPoolAddress, 0);
                    IERC20Upgradeable(W_ETH).safeApprove(_lendingPoolAddress, _setupRepay);
                    _aaveLendingPool.repay(W_ETH, _setupRepay, 2, address(this));
                    console.log("_setupRepay", _setupRepay);
                    _wethDebtAmount = _wethDebtAmount - _setupRepay;
                }
            } else {
                break;
            }
        }
    }

    /// @inheritdoc ETHBaseStrategy
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        IAavePriceOracle _aaveOracle = IAavePriceOracle(aaveProvider.getPriceOracle());
        uint256 _stETHPrice = _aaveOracle.getAssetPrice(ST_ETH);
        uint256 _astETHAmount = (balanceOfToken(A_ST_ETH) * _withdrawShares) / _totalShares;
        uint256 _wethDebtAmount = (balanceOfToken(DEBT_W_ETH) * _withdrawShares) / _totalShares;
        console.log("(A_ST_ETH,DEBT_W_ETH,withdrawShares,totalShares)=");
        console.log(
            balanceOfToken(A_ST_ETH),
            balanceOfToken(DEBT_W_ETH),
            _withdrawShares,
            _totalShares
        );
        _repay(_astETHAmount, _wethDebtAmount, _stETHPrice);
        uint256 _wethAmount = balanceOfToken(W_ETH);
        if (_wethAmount > 0) {
            IWeth(W_ETH).withdraw(_wethAmount);
        }
        console.log("end withdraw:");
        console.log(
            balanceOfToken(ST_ETH),
            balanceOfToken(A_ST_ETH),
            balanceOfToken(W_ETH),
            balanceOfToken(NativeToken.NATIVE_TOKEN)
        );
        console.log(balanceOfToken(DEBT_W_ETH));
    }

    /// @notice Rebalance the collateral of this strategy
    /// Requirements: only keeper can call
    function rebalance() external isKeeper {
        address _lendingPoolAddress = aaveProvider.getLendingPool();
        IAaveLendingPool _aaveLendingPool = IAaveLendingPool(_lendingPoolAddress);
        IAavePriceOracle _aaveOracle = IAavePriceOracle(aaveProvider.getPriceOracle());
        uint256 _stETHPrice = _aaveOracle.getAssetPrice(ST_ETH);
        (
            uint256 _remainingAmount,
            uint256 _overflowAmount,
            uint256 _overflowDebtAmount
        ) = _borrowInfo(_stETHPrice);
        if (_remainingAmount > 10) {
            uint256 _borrowCount = borrowCount;
            for (uint256 i = 0; i < _borrowCount; i++) {
                if (_remainingAmount > 10) {
                    console.log(i, _remainingAmount);
                    uint256 _increaseAstEthAmount = _borrowEthAndDepositStEth(
                        _remainingAmount,
                        _stETHPrice,
                        _lendingPoolAddress
                    );
                    _remainingAmount = _increaseAstEthAmount;
                } else {
                    break;
                }
            }
        } else if (_overflowAmount > 0) {
            uint256 _astETHAmount = _overflowAmount;
            uint256 _wethDebtAmount = _overflowDebtAmount;
            _repay(_astETHAmount, _wethDebtAmount, _stETHPrice);
        }
    }

    /// @notice Returns the info of borrow.
    /// @param _stETHPrice the price of stETH in ETH
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow eth
    /// @return _overflowAmount The amount of debt token that exceeds the maximum allowable loan
    function _borrowInfo(uint256 _stETHPrice)
        private
        view
        returns (
            uint256 _remainingAmount,
            uint256 _overflowAmount,
            uint256 _overflowDebtAmount
        )
    {
        uint256 _stETHPriceCopy = _stETHPrice;
        uint256 _borrowFactor = borrowFactor;
        uint256 _borrowFactorMax = borrowFactorMax;
        uint256 _borrowFactorMin = borrowFactorMin;
        uint256 _leverage = BPS;
        uint256 _leverageMax = BPS;
        uint256 _leverageMin = BPS;
        {
            uint256 _currentBorrowFactor = BPS;
            uint256 _currentBorrowFactorMax = BPS;
            uint256 _currentBorrowFactorMin = BPS;
            uint256 _borrowCount = borrowCount;
            for (uint256 i = 0; i < _borrowCount; i++) {
                _currentBorrowFactor = (_currentBorrowFactor * _borrowFactor) / BPS;
                _leverage = _leverage + _currentBorrowFactor;
                _currentBorrowFactorMax = (_currentBorrowFactorMax * _borrowFactorMax) / BPS;
                _leverageMax = _leverageMax + _currentBorrowFactorMax;
                _currentBorrowFactorMin = (_currentBorrowFactorMin * _borrowFactorMin) / BPS;
                _leverageMin = _leverageMin + _currentBorrowFactorMin;
            }
        }

        uint256 _wethDebtAmount = balanceOfToken(DEBT_W_ETH);
        uint256 _needATokenAmount;
        uint256 _needATokenAmountMin;
        uint256 _needATokenAmountMax;
        {
            uint256 _wethDebtAmountInAToken = (_wethDebtAmount * 1e18) / _stETHPriceCopy;
            _needATokenAmount = (_wethDebtAmountInAToken * _leverage) / (_leverage - BPS);
            _needATokenAmountMin = (_wethDebtAmountInAToken * _leverageMax) / (_leverageMax - BPS);
            _needATokenAmountMax = (_wethDebtAmountInAToken * _leverageMin) / (_leverageMin - BPS);

            console.log(
                "_wethDebtAmount,_wethDebtAmountInAToken,_astETHAmount=",
                _wethDebtAmount,
                _wethDebtAmountInAToken,
                balanceOfToken(A_ST_ETH)
            );
            console.log(
                "_leverage,_leverageMax,_leverageMin=",
                _leverage,
                _leverageMax,
                _leverageMin
            );
            console.log(
                "(_needATokenAmount,_needATokenAmountMin,_needATokenAmountMax)=",
                _needATokenAmount,
                _needATokenAmountMin,
                _needATokenAmountMax
            );
        }
        {
            uint256 _astETHAmount = balanceOfToken(A_ST_ETH);
            if (_needATokenAmountMin > _astETHAmount) {
                _overflowAmount = _needATokenAmount - _astETHAmount;
                _overflowDebtAmount =
                    _wethDebtAmount -
                    ((2 * _astETHAmount - _needATokenAmount) *
                        _stETHPriceCopy *
                        (_leverage - BPS)) /
                    _leverage /
                    1e18;
            } else if (_needATokenAmountMax < _astETHAmount) {
                _remainingAmount = _astETHAmount - _needATokenAmount;
            }
        }

        //        console.log("_overflowDebtAmount,_overflowAmount,_remainingAmount=",_overflowDebtAmount, _overflowAmount,_remainingAmount);
    }

    /// @notice Returns the info of borrow.
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow eth
    /// @return _overflowAmount The amount of aToken that exceeds the maximum allowable loan
    /// @return _overflowDebtAmount The amount of debt token that exceeds the maximum allowable loan
    function borrowInfo()
        public
        view
        returns (
            uint256 _remainingAmount,
            uint256 _overflowAmount,
            uint256 _overflowDebtAmount
        )
    {
        IAavePriceOracle _aaveOracle = IAavePriceOracle(aaveProvider.getPriceOracle());
        uint256 _stETHPrice = _aaveOracle.getAssetPrice(ST_ETH);
        (_remainingAmount, _overflowAmount, _overflowDebtAmount) = _borrowInfo(_stETHPrice);
    }
}
