// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../ETHBaseClaimableStrategy.sol";

import "./../../enums/ProtocolEnum.sol";
import "../../../external/aave/ILendingPool.sol";
import "../../../external/dforce/DFiToken.sol";
import "../../../external/dforce/IDForceController.sol";
import "../../../external/dforce/IDForcePriceOracle.sol";
import "../../../external/dforce/IRewardDistributorV3.sol";
import "../../../external/uniswap/IUniswapV2Router2.sol";

import "hardhat/console.sol";

/// @title ETHDForceRevolvingLoanStrategy
/// @notice Investment strategy of investing in eth/wsteth and revolving lending through post-staking via DForceRevolvingLoan
/// @author Bank of Chain Protocol Inc
contract ETHDForceRevolvingLoanStrategy is ETHBaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address internal constant DF = 0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    IUniswapV2Router2 public constant UNIROUTER2 =
    IUniswapV2Router2(0x232818620877fd9232e9ADe0c91EF5518EB11788);

    address public iToken;
    address public iController;
    address public rewardDistributorV3;
    address public priceOracle;
    uint256 public borrowCount;
    mapping(address => address[]) public swapRewardRoutes;
    mapping(address => bytes32) public swapRewardPoolId;

    /// @param _borrowCount The new count Of borrow
    event UpdateBorrowCount(uint256 _borrowCount);

    event ExecuteOperation(
        address[] assets,
        uint256[] amounts,
        uint256[] premiums,
        address initiator,
        bytes params
    );

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
        //set up sell reward path
        address[] memory _dfSellPath = new address[](2);
        _dfSellPath[0] = DF;
        _dfSellPath[1] = WETH;
        swapRewardRoutes[DF] = _dfSellPath;


        borrowCount = 10;
        address[] memory _wants = new address[](1);
        _wants[0] = _underlyingToken;
        iToken = _iToken;
        iController = _iController;
        priceOracle = _priceOracle;
        rewardDistributorV3 = _rewardDistributorV3;
        super._initialize(_vault, uint16(ProtocolEnum.DForce), _name, _wants);
        if (_underlyingToken != NativeToken.NATIVE_TOKEN) {
            IERC20Upgradeable(_underlyingToken).safeApprove(_iToken, type(uint256).max);
        }
    }
    /// @notice Sets the path of swap from reward token
    /// @param _token The reward token
    /// @param _uniswapRouteToToken The token address list contains reward token and toToken
    /// Requirements: only vault manager can call
    function setRewardSwapPath(address _token, address[] memory _uniswapRouteToToken)
    external
    isVaultManager
    {
        swapRewardRoutes[_token] = _uniswapRouteToToken;
    }

    /// @notice Sets the pool Id of swap from reward token
    /// @param _token The reward token
    /// @param _poolId The pool Id
    /// Requirements: only vault manager can call
    function setRewardSwapPoolId(address _token, bytes32 _poolId)
    external
    isVaultManager
    {
        swapRewardPoolId[_token] = _poolId;
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

    /// @inheritdoc ETHBaseClaimableStrategy
    function claimRewards()
    internal
    override
    returns (bool _claimIsWorth, address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        _claimIsWorth = true;
        address[] memory _holders = new address[](1);
        _holders[0] = address(this);
        address[] memory _iTokens = new address[](1);
        _iTokens[0] = iToken;
        IRewardDistributorV3(rewardDistributorV3).claimReward(_holders, _iTokens);
        _rewardTokens = new address[](1);
        _rewardTokens[0] = DF;
        _claimAmounts = new uint256[](1);
        _claimAmounts[0] = balanceOfToken(_rewardTokens[0]);
    }

    /// @inheritdoc ETHBaseClaimableStrategy
    function swapRewardsToWants() internal override returns(address[] memory _wantTokens,uint256[] memory _wantAmounts){

        uint256 _balanceOfDF = balanceOfToken(DF);
        if (_balanceOfDF > 0) {
            IERC20Upgradeable(DF).safeApprove(address(UNIROUTER2), 0);
            IERC20Upgradeable(DF).safeApprove(address(UNIROUTER2), _balanceOfDF);
            UNIROUTER2.swapExactTokensForTokens(
                _balanceOfDF,
                0,
                swapRewardRoutes[DF],
                address(this),
                block.timestamp
            );
        }
    }

    /// @inheritdoc ETHBaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
    internal
    override
    {
        uint256 _amount = _amounts[0];
        if (_amount > 0) {
            address _want = _assets[0];
            address _iTokenTmp = iToken;
            DFiToken _dFiToken = DFiToken(_iTokenTmp);
            address _asset = _assets[0];
            if (_want == NativeToken.NATIVE_TOKEN) {
                _dFiToken.mint{value: _amount}(address(this));
            } else {
                _dFiToken.mint(address(this), _amount);
            }
            IDForceController _iController = IDForceController(iController);
            if (!_iController.hasEnteredMarket(address(this), _iTokenTmp)) {
                address[] memory _iTokens = new address[](1);
                _iTokens[0] = _iTokenTmp;
                _iController.enterMarkets(_iTokens);
            }
            uint256 _borrowFactorMantissa = _iController.markets(_iTokenTmp).borrowFactorMantissa;
            uint256 _underlyingPrice = IDForcePriceOracle(priceOracle).getUnderlyingPrice(
                _iTokenTmp
            );
            console.log("deposit _underlyingPrice", _underlyingPrice);
            uint256 _borrowCount = borrowCount;
            for (uint256 i = 0; i < _borrowCount; i++) {
                uint256 _equity = 0;
                {
                    (
                    uint256 _equityTemp,
                    uint256 _shortfall,
                    uint256 _collateralValue,
                    uint256 _borrowedValue
                    ) = _iController.calcAccountEquity(address(this));
                    console.log("deposit=", i);
                    _equity = _equityTemp;
                    console.log(_equity, _shortfall, _collateralValue, _borrowedValue);
                }

                if (_equity > 0) {
                    uint256 _allowBorrowAmount = (_equity * _borrowFactorMantissa) /
                    (_underlyingPrice * 1e18);

                    if (_allowBorrowAmount > 0) {
                        _dFiToken.borrow(_allowBorrowAmount);
                        _amount = balanceOfToken(_want);
                        console.log(_equity, _allowBorrowAmount, _amount);
                        if (_amount > 0) {
                            if (_want == NativeToken.NATIVE_TOKEN) {
                                _dFiToken.mint{value: _amount}(address(this));
                            } else {
                                _dFiToken.mint(address(this), _amount);
                            }
                        } else {
                            break;
                        }
                    }
                } else {
                    break;
                }
            }
            {
                (
                uint256 _equity,
                uint256 _shortfall,
                uint256 _collateralValue,
                uint256 _borrowedValue
                ) = IDForceController(iController).calcAccountEquity(address(this));
                console.log("deposit end");
                console.log(_equity, _shortfall, _collateralValue, _borrowedValue);
            }
        }
    }

    /// @inheritdoc ETHBaseStrategy
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        address _iTokenTmp = iToken;
        DFiToken _dFiToken = DFiToken(_iTokenTmp);

        uint256 _redeemAmount = (balanceOfToken(_iTokenTmp) * _withdrawShares) / _totalShares;
        uint256 _repayAmount = (_dFiToken.borrowBalanceCurrent(address(this)) * _withdrawShares) /
        _totalShares;
        if (_redeemAmount > 0) {
            IDForceController _iController = IDForceController(iController);
            {
                address[] memory _borrowedAssets = _iController.getBorrowedAssets(address(this));
                //                console.log("_borrowedAssets.length",_borrowedAssets.length);
                for (uint256 i = 0; i < _borrowedAssets.length; i++) {
                    //                    console.log("_borrowedAssets[i]", i, _borrowedAssets[i]);
                    (uint256 _underlyingPrice, bool _isPriceValid) = IDForcePriceOracle(
                        priceOracle
                    ).getUnderlyingPriceAndStatus(_borrowedAssets[i]);
                    //                    console.log("_borrowedAsset underlyingPrice = ", _underlyingPrice,_isPriceValid);
                }
                address[] memory _accountCollaterals = _iController.getEnteredMarkets(
                    address(this)
                );
                //                console.log("_accountCollaterals.length",_accountCollaterals.length);
                for (uint256 i = 0; i < _accountCollaterals.length; i++) {
                    //                    console.log("_accountCollaterals[i]", i, _accountCollaterals[i]);
                    (uint256 _underlyingPrice, bool _isPriceValid) = IDForcePriceOracle(
                        priceOracle
                    ).getUnderlyingPriceAndStatus(_accountCollaterals[i]);
                    //                    console.log("_accountCollateral asset underlyingPrice = ", _underlyingPrice,_isPriceValid);
                }
            }

            uint256 _collateralFactorMantissa = _iController
            .markets(_iTokenTmp)
            .collateralFactorMantissa;
            uint256 _underlyingPrice = IDForcePriceOracle(priceOracle).getUnderlyingPrice(
                _iTokenTmp
            );
            uint256 _repayCount = borrowCount + 2;
            address _want = wants[0];
            for (uint256 i = 0; i < _repayCount; i++) {
                uint256 _equity = 0;
                {
                    console.log("withdraw =", i);
                    (
                    uint256 _equityTemp,
                    uint256 _shortfall,
                    uint256 _collateralValue,
                    uint256 _borrowedValue
                    ) = _iController.calcAccountEquity(address(this));
                    _equity = _equityTemp;
                    console.log(_equityTemp, _shortfall, _collateralValue, _borrowedValue);
                }

                if (_equity > 0) {
                    uint256 _exchangeRateStored = _dFiToken.exchangeRateStored();
                    uint256 _allowRedeemAmount = ((_equity * 1e18) / _collateralFactorMantissa) /
                    ((_underlyingPrice * _exchangeRateStored) / 1e18);
                    if (_allowRedeemAmount > 0 && _redeemAmount > 0) {
                        {
                            uint256 _setupRedeemAmount = _allowRedeemAmount;
                            if (_setupRedeemAmount > _redeemAmount) {
                                _setupRedeemAmount = _redeemAmount;
                            }
                            console.log("_setupRedeemAmount = ", _setupRedeemAmount);
                            console.log(
                                "_oldCollateralValue = ",
                                ((((balanceOfToken(iToken)) *
                                _underlyingPrice *
                                _exchangeRateStored) / 1e18) * _collateralFactorMantissa) /
                                1e18
                            );
                            console.log(
                                "_subCollateralValue = ",
                                ((((_setupRedeemAmount) * _underlyingPrice * _exchangeRateStored) /
                                1e18) * _collateralFactorMantissa) / 1e18
                            );
                            console.log(
                                "_newCollateralValue = ",
                                ((((balanceOfToken(iToken) - _setupRedeemAmount) *
                                _underlyingPrice *
                                _exchangeRateStored) / 1e18) * _collateralFactorMantissa) /
                                1e18
                            );
                            _dFiToken.redeem(address(this), _setupRedeemAmount);
                            _redeemAmount = _redeemAmount - _setupRedeemAmount;
                            console.log(_equity, _allowRedeemAmount, _redeemAmount);
                        }
                        if (_repayAmount > 0) {
                            uint256 _setupRepayAmount = balanceOfToken(_want);
                            console.log("_amount=", _setupRepayAmount);

                            if (_setupRepayAmount > _repayAmount) {
                                _setupRepayAmount = _repayAmount;
                            }
                            if (_want == NativeToken.NATIVE_TOKEN) {
                                _dFiToken.repayBorrow{value: _setupRepayAmount}();
                            } else {
                                _dFiToken.repayBorrow(_setupRepayAmount);
                            }

                            _dFiToken.repayBorrow(_setupRepayAmount);
                            _repayAmount = _repayAmount - _setupRepayAmount;
                        }
                    } else {
                        break;
                    }
                } else {
                    break;
                }
            }

            {
                (
                uint256 _equity,
                uint256 _shortfall,
                uint256 _collateralValue,
                uint256 _borrowedValue
                ) = IDForceController(iController).calcAccountEquity(address(this));
                console.log("withdraw end");
                console.log(_equity, _shortfall, _collateralValue, _borrowedValue);
            }
        }
    }

    //    /// @inheritdoc ETHBaseStrategy
    //    function withdrawFrom3rdPool(
    //        uint256 _withdrawShares,
    //        uint256 _totalShares,
    //        uint256 _outputCode
    //    ) internal override {
    //        address _iTokenTmp = iToken;
    //        uint256 _redeemAmount = (balanceOfToken(_iTokenTmp) * _withdrawShares) / _totalShares;
    //        uint256 _repayAmount = (DFiToken(_iTokenTmp).borrowBalanceCurrent(address(this)) *
    //            _withdrawShares) / _totalShares;
    //        if (_redeemAmount > 0) {
    //            {
    //                address[] memory _assets = new address[](1);
    //                _assets[0] = wants[0];
    //                uint256[] memory _amounts = new uint256[](1);
    //                _amounts[0] = _repayAmount;
    //                uint256[] memory _modes = new uint256[](1);
    //                _modes[0] = 0;
    //                //                address _onBehalfOf =  address(this);
    //                bytes memory _params = abi.encodePacked(_redeemAmount, _repayAmount);
    //                //                uint16 _referralCode = 0;
    //                console.log("before flashLoan", balanceOfToken(wants[0]));
    //                ILendingPool(LENDING_POOL).flashLoan(
    //                    address(this),
    //                    _assets,
    //                    _amounts,
    //                    _modes,
    //                    address(this),
    //                    _params,
    //                    0
    //                );
    //                console.log("after flashLoan", balanceOfToken(wants[0]));
    //            }
    //        }
    //    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        address _lendingPoolAddress = LENDING_POOL;
        if (msg.sender != _lendingPoolAddress) {
            return false;
        }

        {
            emit ExecuteOperation(assets, amounts, premiums, initiator, params);
            console.log("before executeOperation", balanceOfToken(wants[0]));
            (uint256 _redeemAmount, uint256 _repayAmount) = abi.decode(params, (uint256, uint256));
            console.log("before repayBorrow", balanceOfToken(wants[0]));

            DFiToken _dFiToken = DFiToken(iToken);
            if (wants[0] == NativeToken.NATIVE_TOKEN) {
                _dFiToken.repayBorrow{value: _repayAmount}();
            } else {
                _dFiToken.repayBorrow(_repayAmount);
            }
            console.log("after repayBorrow", balanceOfToken(wants[0]));
            _dFiToken.redeem(address(this), _redeemAmount);
            console.log("after redeem", balanceOfToken(wants[0]));
        }
        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i] + premiums[i];
            console.log(
                "amountOwing,amounts[i],premiums[i] = ",
                amountOwing,
                amounts[i],
                premiums[i]
            );
            address _asset = assets[i];
            IERC20Upgradeable(_asset).safeApprove(_lendingPoolAddress, 0);
            IERC20Upgradeable(_asset).safeApprove(_lendingPoolAddress, amountOwing);
        }
        console.log("after executeOperation", balanceOfToken(wants[0]));

        return true;
    }
}
