// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "boc-contract-core/contracts/strategy/BaseStrategy.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "../../enums/ProtocolEnum.sol";
import "../../../external/aave/ILendingPool.sol";
import "../../../external/aave/ReserveConfiguration.sol";
import "../../../external/aave/DataTypes.sol";
import "../../../external/aave/ILendingPoolAddressesProvider.sol";
import "../../../external/aave/IPriceOracleGetter.sol";
import "../../../external/curve/ICurveLiquidityFarmingPool.sol";
import "../../../external/weth/IWeth.sol";
import "../../../external/uniswap/IUniswapV3.sol";

import "hardhat/console.sol";

contract AaveStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 internal constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    address internal constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant DEBT_W_ETH = 0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;
    address public constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant A_ST_ETH = 0x1982b2F5814301d4e9a8b0201555376e62F82428;
    address public constant A_WETH = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    uint256 public constant BPS = 10000;
    address private aToken;
    /**
     * @dev Aave Lending Pool Provider
     */
    ILendingPoolAddressesProvider internal constant aaveProvider =
    ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    ICurveLiquidityFarmingPool private curvePool;
    uint256 public stETHBorrowFactor;
    uint256 public borrowFactor;
    uint256 public borrowFactorMax;
    uint256 public borrowFactorMin;
    uint256 public borrowCount;
    address public uniswapV3Pool;

    /// Events

    /// @param _stETHBorrowFactor The new stETH borrow factor
    event UpdateStETHBorrowFactor(uint256 _stETHBorrowFactor);
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

    receive() external payable {}

    fallback() external payable {}

    function initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address _wantToken,
        address _wantAToken,
        address _uniswapV3Pool
    ) external initializer {
        curvePool = ICurveLiquidityFarmingPool(
            address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022)
        );
        address[] memory _wants = new address[](1);
        _wants[0] = _wantToken;
        aToken = _wantAToken;
        uniswapV3Pool = _uniswapV3Pool;
        stETHBorrowFactor = 6700;
        borrowFactor = 6700;
        borrowFactorMin = 6500;
        borrowFactorMax = 6900;
        borrowCount = 3;
        super._initialize(_vault, _harvester, _name, uint16(ProtocolEnum.Aave), _wants);
    }

    /// @notice Sets `_stETHBorrowFactor` to `stETHBorrowFactor`
    /// @param _stETHBorrowFactor The new value of `stETHBorrowFactor`
    /// Requirements: only vault manager can call
    function setStETHBorrowFactor(uint256 _stETHBorrowFactor) external isVaultManager {
        require(_stETHBorrowFactor < BPS, "setting output the range");
        stETHBorrowFactor = _stETHBorrowFactor;

        emit UpdateStETHBorrowFactor(_stETHBorrowFactor);
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

    /// @inheritdoc BaseStrategy
    function getVersion() external pure virtual override returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc BaseStrategy
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

    /// @inheritdoc BaseStrategy
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

    /// @inheritdoc BaseStrategy
    function getPositionDetail()
    public
    view
    virtual
    override
    returns (
        address[] memory _tokens,
        uint256[] memory _amounts,
        bool _isUsd,
        uint256 _usdValue
    )
    {
        _tokens = wants;
        _amounts = new uint256[](1);
        address _aToken = aToken;
        address _token = _tokens[0];

        uint256 _wethDebtAmount = balanceOfToken(DEBT_W_ETH);
        uint256 _tokenAmount = balanceOfToken(_token) + balanceOfToken(aToken);
        uint256 _wethAmount = balanceOfToken(W_ETH) + address(this).balance;
        uint256 _stEthAmount = balanceOfToken(A_ST_ETH) + balanceOfToken(ST_ETH);
        _isUsd = true;
        if (_wethAmount > _wethDebtAmount) {
            _usdValue =
            queryTokenValue(_token, _tokenAmount) +
            queryTokenValue(ST_ETH, _stEthAmount) +
            queryTokenValue(W_ETH, _wethAmount - _wethDebtAmount);
        } else if (_wethAmount < _wethDebtAmount) {
            _usdValue =
            queryTokenValue(_token, _tokenAmount) +
            queryTokenValue(ST_ETH, _stEthAmount) -
            queryTokenValue(W_ETH, _wethDebtAmount - _wethAmount);
        } else {
            _usdValue =
            queryTokenValue(_token, _tokenAmount) +
            queryTokenValue(ST_ETH, _stEthAmount);
        }
    }

    /// @inheritdoc BaseStrategy
    function get3rdPoolAssets() external view override returns (uint256) {
        return queryTokenValue(wants[0], IERC20Upgradeable(aToken).totalSupply());
    }

    /// @inheritdoc BaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
    internal
    override
    {
        address _lendingPoolAddress = aaveProvider.getLendingPool();
        uint256 _stETHPrice;
        uint256 _tokenPrice;
        {
            address _aToken = aToken;
            address _asset = _assets[0];
            uint256 _beforeBalanceOfAToken = balanceOfToken(_aToken);
            {
                uint256 _amount = _amounts[0];
                IERC20Upgradeable(_asset).safeApprove(_lendingPoolAddress, 0);
                IERC20Upgradeable(_asset).safeApprove(_lendingPoolAddress, _amount);
                ILendingPool(_lendingPoolAddress).deposit(_asset, _amount, address(this), 0);
            }
            {
                address[] memory _assets = new address[](2);
                _assets[0] = ST_ETH;
                _assets[1] = _asset;
                IPriceOracleGetter _aaveOracle = IPriceOracleGetter(aaveProvider.getPriceOracle());
                uint256[] memory _prices = _aaveOracle.getAssetsPrices(_assets);
                _stETHPrice = _prices[0];
                _tokenPrice = _prices[1];
            }
            {
                uint256 _aTokenAmount = balanceOfToken(_aToken) - _beforeBalanceOfAToken;
                uint256 _borrowAmount = (((_aTokenAmount * _tokenPrice) /
                decimalUnitOfToken(_asset)) * borrowFactor) / BPS;
                ILendingPool(_lendingPoolAddress).borrow(
                    W_ETH,
                    _borrowAmount,
                    2,
                    0,
                    address(this)
                );
                IWeth(W_ETH).withdraw(balanceOfToken(W_ETH));
                uint256 _ethAmount = address(this).balance;
                curvePool.exchange{value: _ethAmount}(0, 1, _ethAmount, 0);
            }
        }
        uint256 _receivedStETHAmount = balanceOfToken(ST_ETH);

        if (_receivedStETHAmount > 0) {
            uint256 _beforeBalanceOfAStETH = balanceOfToken(A_ST_ETH);
            IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, 0);
            IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, _receivedStETHAmount);
            ILendingPool(_lendingPoolAddress).deposit(
                ST_ETH,
                _receivedStETHAmount,
                address(this),
                0
            );
            uint256 _astETHAmount = balanceOfToken(A_ST_ETH) - _beforeBalanceOfAStETH;
            uint256 _borrowCount = borrowCount;
            uint256 _borrowFactor = stETHBorrowFactor;
            for (uint256 i = 0; i < _borrowCount; i++) {
                if (_astETHAmount > 10) {
                    uint256 _increaseAstEthAmount = _borrowEthAndDepositStEth(
                        _astETHAmount,
                        _borrowFactor,
                        _stETHPrice,
                        _lendingPoolAddress
                    );
                    _astETHAmount = _increaseAstEthAmount;
                } else {
                    break;
                }
            }
        }
    }

    /// @notice redeem aToken ,then exchange to debt Token ,and finally repay the debt
    /// @param _astETHAmount The amount of aToken that will still be to redeem
    /// @param _stETHPrice the price of stETH in ETH
    /// @param _lendingPoolAddress The address of lendingPool
    /// @return _increaseAstEthAmount The amount of increase aToken
    function _borrowEthAndDepositStEth(
        uint256 _astETHAmount,
        uint256 _borrowFactor,
        uint256 _stETHPrice,
        address _lendingPoolAddress
    ) private returns (uint256 _increaseAstEthAmount) {
        ILendingPool _aaveLendingPool = ILendingPool(_lendingPoolAddress);
        uint256 _astETHValueInEth = (_astETHAmount * _stETHPrice) / 1e18;
        uint256 _borrowAmount = (_astETHValueInEth * _borrowFactor) / BPS;
        _aaveLendingPool.borrow(W_ETH, _borrowAmount, 2, 0, address(this));
        IWeth(W_ETH).withdraw(balanceOfToken(W_ETH));
        uint256 _ethAmount = address(this).balance;
        curvePool.exchange{value: _ethAmount}(0, 1, _ethAmount, 0);
        uint256 _receivedStETHAmount = balanceOfToken(ST_ETH);

        IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, 0);
        IERC20Upgradeable(ST_ETH).safeApprove(_lendingPoolAddress, _receivedStETHAmount);
        uint256 _beforeBalanceOfAStETH = balanceOfToken(A_ST_ETH);
        _aaveLendingPool.deposit(ST_ETH, _receivedStETHAmount, address(this), 0);
        _increaseAstEthAmount = balanceOfToken(A_ST_ETH) - _beforeBalanceOfAStETH;
    }

    /// @notice get allow withdraw amount
    /// @param _aaveLendingPool The aave lending pool
    /// @param _tokenPrice the price of token(DAI/USDC/stETH) in ETH
    /// @param _configurationData the data of reserve configuration
    /// @return _allowWithdrawAmount The amount of can withdraw
    function _getAllowWithdrawAmount(
        ILendingPool _aaveLendingPool,
        uint256 _tokenPrice,
uint256 _configurationData
    ) private view returns (uint256 _allowWithdrawAmount) {
        uint256 _idleDebtETH;
        {
            (
            uint256 _totalCollateralETH,
            uint256 _totalDebtETH,
            uint256 _availableBorrowsETH,
            ,
            ,

            ) = _aaveLendingPool.getUserAccountData(address(this));

            if (_totalDebtETH < 1) {
                _idleDebtETH = _totalCollateralETH;
            } else {
                _idleDebtETH = _availableBorrowsETH;
            }
        }
        if (_idleDebtETH > 0) {
            uint256 _tokenLiquidationThreshold = ReserveConfiguration.getLiquidationThreshold(_configurationData);
            uint256 _tokenDecimal = ReserveConfiguration.getDecimals(_configurationData);
            _allowWithdrawAmount =
            (_idleDebtETH * BPS * (10**_tokenDecimal)) /
            (_tokenLiquidationThreshold * _tokenPrice);
        }

        console.log("_allowWithdrawAmount=", _allowWithdrawAmount);
    }

    /// @notice redeem aToken and astETH,then exchange to debt Token ,and finally repay the debt
    /// @param _astETHAmount The amount of astETHToken that will still be to redeem
    /// @param _aTokenAmount The amount of aToken(ausdc/adai) that will still be to redeem
    /// @param _wethDebtAmount The amount of debt token that will still be to repay
    /// @param _stETHPrice the price of stETH in ETH
    /// @param _tokenPrice the price of token(usdc/dai) in ETH
    /// @param _tokenAddress the address of token(usdc/dai)
    function _repay(
        uint256 _astETHAmount,
        uint256 _aTokenAmount,
        uint256 _wethDebtAmount,
        uint256 _stETHPrice,
        uint256 _tokenPrice,
        address _tokenAddress
    ) private {
        uint256 _wethDebtAmountCopy = _wethDebtAmount;
        ICurveLiquidityFarmingPool _curvePool = curvePool;
        ILendingPool _aaveLendingPool = ILendingPool(aaveProvider.getLendingPool());
        uint256 _stETHConfigurationData = _aaveLendingPool.getReserveData(
            ST_ETH
        ).configuration.data;
        uint256 _tokenConfigurationData = _aaveLendingPool.getReserveData(
            _tokenAddress
        ).configuration.data;
        uint256 _repayCount = borrowCount * 2;
        for (uint256 i = 0; i < _repayCount; i++) {
            console.log("_astETHAmount,_aTokenAmount=", _astETHAmount, _aTokenAmount);
            if (_astETHAmount > 1 || _aTokenAmount > 0) {
                if (_astETHAmount > 1) {
                    uint256 _setupWithdraw;
                    {
                        _setupWithdraw = _getAllowWithdrawAmount(
                            _aaveLendingPool,
                            _stETHPrice,
                            _stETHConfigurationData
                        );
                        if (_setupWithdraw >= _astETHAmount) {
                            _setupWithdraw = _astETHAmount;
                        }
                        console.log("asteth,i,_allowWithdrawETHAmount,_setupWithdraw");
                        console.log(i, _setupWithdraw);
                    }
                    if (_setupWithdraw > 1) {
                        _aaveLendingPool.withdraw(ST_ETH, _setupWithdraw, address(this));
                        _astETHAmount = _astETHAmount - _setupWithdraw;
                        {
                            uint256 _receivedStETHAmount = balanceOfToken(ST_ETH);
                            IERC20Upgradeable(ST_ETH).safeApprove(address(_curvePool), 0);
                            IERC20Upgradeable(ST_ETH).safeApprove(
                                address(_curvePool),
                                _receivedStETHAmount
                            );
                            _curvePool.exchange(1, 0, _receivedStETHAmount, 0);
                        }
                        if (_wethDebtAmountCopy > 0) {
                            uint256 _setupRepay;
                            {
                                uint256 _ethAmount = address(this).balance;
                                if (_ethAmount >= _wethDebtAmountCopy) {
                                    _setupRepay = _wethDebtAmountCopy;
                                } else {
                                    _setupRepay = _ethAmount;
                                }
                            }
                            IWeth(W_ETH).deposit{value: _setupRepay}();
                            IERC20Upgradeable(W_ETH).safeApprove(address(_aaveLendingPool), 0);
                            IERC20Upgradeable(W_ETH).safeApprove(
                                address(_aaveLendingPool),
                                _setupRepay
                            );
                            _aaveLendingPool.repay(W_ETH, _setupRepay, 2, address(this));
                            _wethDebtAmountCopy = _wethDebtAmountCopy - _setupRepay;
                        }
                    }
                }
                if (_aTokenAmount > 0) {

                    uint256 _setupWithdraw;
                    {
                        _setupWithdraw = _getAllowWithdrawAmount(
                            _aaveLendingPool,
                            _tokenPrice,
                            _tokenConfigurationData
                        );
                        if (_setupWithdraw >= _aTokenAmount) {
                            _setupWithdraw = _aTokenAmount;
                        }
                        console.log("atoken,i,_allowWithdrawETHAmount,_setupWithdraw");
                        console.log(i, _setupWithdraw);
                    }
                    if (_setupWithdraw > 0) {
                        _aaveLendingPool.withdraw(_tokenAddress, _setupWithdraw, address(this));
                        _aTokenAmount = _aTokenAmount - _setupWithdraw;
                        if (_wethDebtAmountCopy > 0) {
                            {
                                uint256 _receivedTokenAmount = balanceOfToken(_tokenAddress);
                                (, int24 _tick, , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();

                                uint256 _quoteAmount = _getQuoteAtTick(
                                    _tick,
                                    uint128(_receivedTokenAmount),
                                    _tokenAddress,
                                    W_ETH
                                );
                                IERC20Upgradeable(_tokenAddress).safeApprove(UNISWAP_V3_ROUTER, 0);
                                IERC20Upgradeable(_tokenAddress).safeApprove(
                                    UNISWAP_V3_ROUTER,
                                    _receivedTokenAmount
                                );
                                console.log(
                                    "_receivedTokenAmount,_quoteAmount,_wethDebtAmountCopy=",
                                    _receivedTokenAmount,
                                    _quoteAmount,
                                    _wethDebtAmountCopy
                                );
                                if (_quoteAmount >= _wethDebtAmountCopy) {
                                    IUniswapV3(UNISWAP_V3_ROUTER).exactOutputSingle(
                                        IUniswapV3.ExactOutputSingleParams(
                                            _tokenAddress,
                                            W_ETH,
                                            500,
                                            address(this),
                                            block.timestamp,
                                            _wethDebtAmountCopy,
                                            _receivedTokenAmount,
                                            0
                                        )
                                    );
                                } else {
                                    IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(
                                        IUniswapV3.ExactInputSingleParams(
                                            _tokenAddress,
                                            W_ETH,
                                            500,
                                            address(this),
                                            block.timestamp,
                                            _receivedTokenAmount,
                                            0,
                                            0
                                        )
                                    );
                                }
                            }

                            uint256 _setupRepay;
                            {
                                uint256 _wethAmount = balanceOfToken(W_ETH);
                                if (_wethAmount >= _wethDebtAmountCopy) {
                                    _setupRepay = _wethDebtAmountCopy;
                                } else {
                                    _setupRepay = _wethAmount;
                                }
                            }
                            IERC20Upgradeable(W_ETH).safeApprove(address(_aaveLendingPool), 0);
                            IERC20Upgradeable(W_ETH).safeApprove(
                                address(_aaveLendingPool),
                                _setupRepay
                            );
                            _aaveLendingPool.repay(W_ETH, _setupRepay, 2, address(this));
                            _wethDebtAmountCopy = _wethDebtAmountCopy - _setupRepay;
                        }
                    }
                }
                console.log("_astETHAmount,_aTokenAmount=", _astETHAmount, _aTokenAmount);
            } else {
                break;
            }
        }

        uint256 _ethAmount = address(this).balance;
        if (_ethAmount > 0) {
            IWeth(W_ETH).deposit{value: _ethAmount}();
        }

        uint256 _wethAmount = balanceOfToken(W_ETH);
        if (_wethAmount > 0) {
            IERC20Upgradeable(W_ETH).safeApprove(UNISWAP_V3_ROUTER, 0);
            IERC20Upgradeable(W_ETH).safeApprove(UNISWAP_V3_ROUTER, _wethAmount);

            IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(
                IUniswapV3.ExactInputSingleParams(
                    W_ETH,
                    _tokenAddress,
                    500,
                    address(this),
                    block.timestamp,
                    _wethAmount,
                    0,
                    0
                )
            );
        }
    }

    /// @inheritdoc BaseStrategy
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        IPriceOracleGetter _aaveOracle = IPriceOracleGetter(aaveProvider.getPriceOracle());
        address _token = wants[0];
        uint256 _stETHPrice = _aaveOracle.getAssetPrice(ST_ETH);
        uint256 _tokenPrice = _aaveOracle.getAssetPrice(_token);
        uint256 _astETHAmount = (balanceOfToken(A_ST_ETH) * _withdrawShares) / _totalShares;
        uint256 _aTokenAmount = (balanceOfToken(aToken) * _withdrawShares) / _totalShares;
        uint256 _wethDebtAmount = (balanceOfToken(DEBT_W_ETH) * _withdrawShares) / _totalShares;
        console.log("balanceOfToken(A_ST_ETH),balanceOfToken(aToken),balanceOfToken(DEBT_W_ETH)");
        console.log(balanceOfToken(A_ST_ETH), balanceOfToken(aToken), balanceOfToken(DEBT_W_ETH));
        console.log(_astETHAmount, _aTokenAmount, _wethDebtAmount);
        _repay(
            _astETHAmount,
            _aTokenAmount,
            _wethDebtAmount,
            _stETHPrice,
            _tokenPrice,
            _token
        );
    }

    /// @notice Rebalance the collateral of this strategy
    /// Requirements: only keeper can call
    function rebalance() external isKeeper {
        //        address _lendingPoolAddress = aaveProvider.getLendingPool();
        //        ILendingPool _aaveLendingPool = ILendingPool(_lendingPoolAddress);
        //        IPriceOracleGetter _aaveOracle = IPriceOracleGetter(aaveProvider.getPriceOracle());
        //        uint256 _stETHPrice = _aaveOracle.getAssetPrice(ST_ETH);
        //        (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowInfo(_stETHPrice);
        //        if (_remainingAmount > 10) {
        //            uint256 _borrowCount = borrowCount;
        //            uint256 _borrowFactor = stETHBorrowFactor;
        //            for (uint256 i = 0; i < _borrowCount; i++) {
        //                if (_remainingAmount > 10) {
        //                    uint256 _increaseAstEthAmount = _borrowEthAndDepositStEth(
        //                        _remainingAmount,
        //                        _stETHPrice,
        //                        _lendingPoolAddress
        //                    );
        //                    _remainingAmount = _increaseAstEthAmount;
        //                } else {
        //                    break;
        //                }
        //            }
        //        } else if (_overflowAmount > 0) {
        //            uint256 _astETHAmount = _overflowAmount;
        //            uint256 _wethDebtAmount = _overflowAmount * 3;
        //            _repay(_astETHAmount, _wethDebtAmount, _stETHPrice);
        //        }
        //        if (_remainingAmount + _overflowAmount > 0) {
        //            emit Rebalance(_remainingAmount, _overflowAmount);
        //        }
    }

    /// @notice Returns the info of borrow.
    /// @param _stETHPrice the price of stETH in ETH
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow eth
    /// @return _overflowAmount The amount of debt token that exceeds the maximum allowable loan
    function _borrowInfo(uint256 _stETHPrice)
    private
    view
    returns (uint256 _remainingAmount, uint256 _overflowAmount)
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
        }
        {
            uint256 _astETHAmount = balanceOfToken(A_ST_ETH);
            if (_needATokenAmountMin > _astETHAmount) {
                _overflowAmount =
                (_leverage *
                _wethDebtAmount *
                1e18 -
                _astETHAmount *
                (_leverage - BPS) *
                _stETHPriceCopy) /
                (_leverage *
                curvePool.get_dy(1, 0, 1e18) -
                (_leverage - BPS) *
                _stETHPriceCopy);
            } else if (_needATokenAmountMax < _astETHAmount) {
                _remainingAmount = _astETHAmount - _needATokenAmount;
            }
        }
    }

    /// @notice Returns the info of borrow.
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow eth
    /// @return _overflowAmount The amount of aToken that exceeds the maximum allowable loan
    function borrowInfo() public view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        IPriceOracleGetter _aaveOracle = IPriceOracleGetter(aaveProvider.getPriceOracle());
        uint256 _stETHPrice = _aaveOracle.getAssetPrice(ST_ETH);
        (_remainingAmount, _overflowAmount) = _borrowInfo(_stETHPrice);
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param _tick Tick value used to calculate the quote
    /// @param _baseAmount Amount of token to be converted
    /// @param _baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param _quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return _quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function _getQuoteAtTick(
        int24 _tick,
        uint128 _baseAmount,
        address _baseToken,
        address _quoteToken
    ) internal pure returns (uint256 _quoteAmount) {
        uint160 _sqrtRatioX96 = TickMath.getSqrtRatioAtTick(_tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (_sqrtRatioX96 <= type(uint128).max) {
            uint256 _ratioX192 = uint256(_sqrtRatioX96) * _sqrtRatioX96;
            _quoteAmount = _baseToken < _quoteToken
            ? FullMath.mulDiv(_ratioX192, _baseAmount, 1 << 192)
            : FullMath.mulDiv(1 << 192, _baseAmount, _ratioX192);
        } else {
            uint256 _ratioX128 = FullMath.mulDiv(_sqrtRatioX96, _sqrtRatioX96, 1 << 64);
            _quoteAmount = _baseToken < _quoteToken
            ? FullMath.mulDiv(_ratioX128, _baseAmount, 1 << 128)
            : FullMath.mulDiv(1 << 128, _baseAmount, _ratioX128);
        }
    }

}
