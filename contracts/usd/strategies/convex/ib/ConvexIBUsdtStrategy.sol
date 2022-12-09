// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "boc-contract-core/contracts/strategy/BaseStrategy.sol";
import "./../../../enums/ProtocolEnum.sol";

import "../../../../external/cream/CTokenInterface.sol";
import "../../../../external/cream/Comptroller.sol";
import "../../../../external/cream/IPriceOracle.sol";
import "../../../../external/convex/IConvex.sol";
import "../../../../external/convex/IConvexReward.sol";
import "../../../../external/curve/ICurveFi.sol";
import "../../../../external/weth/IWeth.sol";

import "../../../../external/uniswap/IUniswapV2Router2.sol";

import "../../../../external/curve/ICurveMini.sol";

/// @title ConvexIBUsdtStrategy
/// @notice Investment strategy for investing stablecoins to IronBank-Usdt pool via Convex 
/// @author Bank of Chain Protocol Inc
contract ConvexIBUsdtStrategy is Initializable, BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // IronBank
    Comptroller public constant COMPTROLLER =
        Comptroller(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    
    /// @notice The priceOracle interface
    IPriceOracle public priceOracle;

    address public constant COLLATERAL_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    CTokenInterface public constant COLLATERAL_CTOKEN =
        CTokenInterface(0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a);

    /// @notice The CToken interface
    CTokenInterface public borrowCToken;

    /// @notice The address of the reward pool
    address public rewardPool;

    uint256 internal pId;

    /// @notice The borrow factor
    uint256 public borrowFactor;

    // minimum amount to be liquidation
    uint256 public constant SELL_FLOOR = 1e17;
    uint256 public constant BPS = 10000;
    address public constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant REWARD_CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant REWARD_CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // rkp3r
    address internal constant RKPR = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;

    // use Curve to sell our CVX and CRV rewards to WETH
    address internal constant CRV_ETH_POOL = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511; // use curve's new CRV-ETH crypto pool to sell our CRV
    address internal constant CVX_ETH_POOL = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4; // use curve's new CVX-ETH crypto pool to sell our CVX

    //sushi router
    address internal constant SUSHI_ROUTER_ADDR = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    //uni router
    address internal constant UNI_ROUTER_ADDR = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //uni v3
    address internal constant UNISWAP_V3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    //reward swap path
    mapping(address => address[]) public rewardRoutes;

    address public curveUsdcIbforexPool;

    /// @param _borrowFactor The new borrow factor
    event UpdateBorrowFactor(uint256 _borrowFactor);

    /// @param _strategy The specified strategy emitted this event
    /// @param _rewards The address list of reward tokens
    /// @param _rewardAmounts The amount list of of reward tokens
    /// @param _wants The address list of wantted tokens
    /// @param _wantAmounts The amount list of wantted tokens
    event SwapRewardsToWants(
        address _strategy,
        address[] _rewards,
        uint256[] _rewardAmounts,
        address[] _wants,
        uint256[] _wantAmounts
    );

    ////// fallback and receive //////
    receive() external payable {}

    fallback() external payable {}

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _strategyName The name of strategy
    /// @param _borrowCToken The borrow asset of this strategy
    /// @param _curve_usdc_ibforex_pool The curve usdc-ibforex pool invested 
    /// @param _rewardPool The address of the base reward pool which issue reward linearly
    function initialize(
        address _vault,
        address _harvester,
        string memory _strategyName,
        address _borrowCToken,
        address _rewardPool,
        address _curve_usdc_ibforex_pool
    ) external initializer {
        borrowCToken = CTokenInterface(_borrowCToken);
        rewardPool = _rewardPool;
        pId = IConvexReward(rewardPool).pid();
        curveUsdcIbforexPool = _curve_usdc_ibforex_pool;
        address[] memory _wants = new address[](1);
        _wants[0] = COLLATERAL_TOKEN;

        priceOracle = IPriceOracle(COMPTROLLER.oracle());

        _initialize(_vault, _harvester, _strategyName, uint16(ProtocolEnum.Convex), _wants);

        borrowFactor = 8300;

        uint256 _uintMax = type(uint256).max;
        // approve sell rewards
        IERC20Upgradeable(REWARD_CRV).safeApprove(address(CRV_ETH_POOL), _uintMax);
        IERC20Upgradeable(REWARD_CVX).safeApprove(address(CVX_ETH_POOL), _uintMax);

        // approve deposit
        address _curveForexPool = getCurveLpToken();
        address _borrowToken = borrowCToken.underlying();
        IERC20Upgradeable(_borrowToken).safeApprove(_curveForexPool, _uintMax);

        IERC20Upgradeable(_borrowToken).safeApprove(SUSHI_ROUTER_ADDR, _uintMax);
        IERC20Upgradeable(USDC).safeApprove(UNI_ROUTER_ADDR, _uintMax);
        IERC20Upgradeable(WETH).safeApprove(SUSHI_ROUTER_ADDR, _uintMax);

        //init reward swap path
        address[] memory _ib2usdc = new address[](2);
        _ib2usdc[0] = _borrowToken;
        _ib2usdc[1] = USDC;
        rewardRoutes[_borrowToken] = _ib2usdc;
        address[] memory _weth2usdc = new address[](2);
        _weth2usdc[0] = WETH;
        _weth2usdc[1] = USDC;
        rewardRoutes[WETH] = _weth2usdc;
        address[] memory _usdc2usdt = new address[](2);
        _usdc2usdt[0] = USDC;
        _usdc2usdt[1] = COLLATERAL_TOKEN;
        rewardRoutes[USDC] = _usdc2usdt;
    }

    /// @notice Return the version of strategy
    function getVersion() external pure override returns (string memory) {
        return "1.0.1";
    }

    // ==== External === //
    /// @notice Return the third party protocol's pool total assets in USD(1e18).
    function get3rdPoolAssets() public view override returns (uint256 targetPoolTotalAssets) {
        address _curvePool = getCurveLpToken();
        uint256 _virtualPrice = ICurveFi(_curvePool).get_virtual_price();
        uint256 _totalSupply = IERC20Upgradeable(_curvePool).totalSupply();
        //30 = 18+12,div 1e12 for normalized,div 1e18 for _virtualPrice
        targetPoolTotalAssets =
            (_virtualPrice * _totalSupply * _borrowTokenPrice()) /
            decimalUnitOfToken(getIronBankForex()) /
            1e30;
    }

    /// @notice Return the underlying token list and ratio list needed by the strategy
    /// @return _assets the address list of token to deposit
    /// @return _ratios the ratios list of `_assets`. 
    ///     The ratio is the proportion of each asset to total assets
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

    /// @notice Return the output path list of the strategy when withdraw.
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

    /// @notice Returns the position details of the strategy.
    /// @return _tokens The list of the position token
    /// @return _amounts The list of the position amount
    /// @return _isUsd Whether to count in USD
    /// @return _usdValue The USD value of positions held
    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        )
    {
        _isUsd = true;
        uint256 _assetsValue = assets();
        uint256 _debtsValue = debts();
        // The usdValue needs to be filled with precision
        _usdValue = _assetsValue - _debtsValue;
    }

    
    /// @notice Return the total valuation of this strategy, in currency denominated units
    function curvePoolAssets() public view returns (uint256 _depositedAssets) {
        uint256 _rewardBalance = balanceOfToken(rewardPool);
        if (_rewardBalance > 0) {
            _depositedAssets =
                (_borrowTokenPrice() *
                    ICurveFi(getCurveLpToken()).calc_withdraw_one_coin(_rewardBalance, 0)) /
                1e12 /
                decimalUnitOfToken(getCurveLpToken());
        } else {
            _depositedAssets = 0;
        }
    }

    
    /// @notice Gets the current debt Rate    
    function debtRate() public view returns (uint256) {
        //_collateral Assets
        uint256 _collateral = collateralAssets();
        //debts
        uint256 _debt = debts();
        if (_collateral == 0) {
            return 0;
        }
        return (_debt * BPS) / _collateral;
    }

    /// @notice Gets the total value of all assets in USD (1e18) 
    function assets() public view returns (uint256 _value) {
        // estimatedDepositedAssets
        uint256 deposited = curvePoolAssets();
        _value += deposited;
        // CToken _value
        _value += collateralAssets();
        address _collateralToken = COLLATERAL_TOKEN;
        // balance
        uint256 _underlyingBalance = balanceOfToken(_collateralToken);
        if (_underlyingBalance > 0) {
            _value +=
                ((_underlyingBalance * _collateralTokenPrice()) /
                    decimalUnitOfToken(_collateralToken)) /
                1e12;
        }
    }

    /// @notice Gets the value of debts in USD (1e18) 
    function debts() public view returns (uint256 _value) {
        CTokenInterface _borrowCToken = borrowCToken;
        //for saving gas
        uint256 _borrowBalanceCurrent = _borrowCToken.borrowBalanceStored(address(this));
        address _borrowToken = _borrowCToken.underlying();
        uint256 _borrowTokenPrice = _borrowTokenPrice();
        _value =
            (_borrowBalanceCurrent * _borrowTokenPrice) /
            decimalUnitOfToken(_borrowToken) /
            1e12; //div 1e12 for normalized
    }

    /// @notice Gets the value of collateral assets in USD (1e18) 
    function collateralAssets() public view returns (uint256 _value) {
        CTokenInterface _collateralC = COLLATERAL_CTOKEN;
        address _collateralToken = COLLATERAL_TOKEN;
        //saving gas
        uint256 _exchangeRateMantissa = _collateralC.exchangeRateStored();
        uint256 _collaterTokenPrecision = decimalUnitOfToken(_collateralToken);
        //Multiply by 18e to prevent loss of precision
        uint256 _collateralTokenAmount = (balanceOfToken(address(_collateralC)) *
            _exchangeRateMantissa *
            _collaterTokenPrecision *
            1e18) /
            1e16 /
            decimalUnitOfToken(address(_collateralC));

        _value =
            (_collateralTokenAmount * _collateralTokenPrice()) /
            _collaterTokenPrecision /
            1e18 /
            1e12; //div 1e12 for normalized
    }

    /// @notice Gets the info of current borrow in USD (1e18) 
    /// @return _space The absolute value of the difference 
    ///     between `_borrowAvaible` and `_currentBorrow`
    /// @return _overflow The absolute value of the difference 
    ///     between `_borrowAvaible` and `_currentBorrow`
    function borrowInfo() public view returns (uint256 _space, uint256 _overflow) {
        uint256 _borrowAvaible = _currentBorrowAvaible();
        uint256 _currentBorrow = borrowCToken.borrowBalanceStored(address(this));
        if (_borrowAvaible > _currentBorrow) {
            _space = _borrowAvaible - _currentBorrow;
        } else {
            _overflow = _currentBorrow - _borrowAvaible;
        }
    }

    /// @notice Gets the curve LP token invested by this strategy
    function getCurveLpToken() public view returns (address) {
        return IConvex(BOOSTER).poolInfo(pId).lptoken;
    }

    /// @notice Gets the IronBankForex token of the curve LP token
    function getIronBankForex() public view returns (address) {
        ICurveFi _curveForexPool = ICurveFi(getCurveLpToken());
        return _curveForexPool.coins(0);
    }

    
    
    /// @notice Harvests by the Strategy, 
    ///     recognizing any profits or losses and adjusting the Strategy's position.
    /// @dev Sell reward and reinvestment logic
    /// @return _rewardsTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function harvest()
        public
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        // for report
        _rewardsTokens = new address[](3);
        _rewardsTokens[0] = REWARD_CRV;
        _rewardsTokens[1] = REWARD_CVX;
        _rewardsTokens[2] = RKPR;
        _claimAmounts = new uint256[](3);
        // for event
        address[] memory _rewardTokens;
        uint256[] memory _rewardAmounts;
        address[] memory _wantTokens;
        uint256[] memory _wantAmounts;
        IConvexReward _convexReward = IConvexReward(rewardPool);
        if (_convexReward.earned(address(this)) > SELL_FLOOR) {
            _convexReward.getReward();
            uint256 _crvBalance = balanceOfToken(REWARD_CRV);
            uint256 _cvxBalance = balanceOfToken(REWARD_CVX);
            (_rewardTokens, _rewardAmounts, _wantTokens, _wantAmounts) = _sellCrvAndCvx(
                _crvBalance,
                _cvxBalance
            );

            uint256 _ibForexAmount = balanceOfToken(getIronBankForex());
            if (_ibForexAmount > 0) {
                _invest(_ibForexAmount);
            }
            //sell kpr
            uint256 _rkprBalance = balanceOfToken(RKPR);
            if (_rkprBalance > 0) {
                IERC20Upgradeable(RKPR).safeTransfer(harvester, _rkprBalance);
            }

            _claimAmounts[0] = _crvBalance;
            _claimAmounts[1] = _cvxBalance;
            _claimAmounts[2] = _rkprBalance;
        }
        // report empty array for _profit
        vault.report(_rewardsTokens, _claimAmounts);

        // emit 'SwapRewardsToWants' event after vault report
        emit SwapRewardsToWants(
            address(this),
            _rewardTokens,
            _rewardAmounts,
            _wantTokens,
            _wantAmounts
        );
    }

    
    /// @dev sell crv and cvx
    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount)
        internal
        returns (
            address[] memory _rewardTokens,
            uint256[] memory _rewardAmounts,
            address[] memory _wantTokens,
            uint256[] memory _wantAmounts
        )
    {
        uint256 _ethBalanceInit = address(this).balance;

        if (_crvAmount > 0) {
            ICurveFi(CRV_ETH_POOL).exchange(1, 0, _crvAmount, 0, true);
        }
        uint256 _ethBalanceAfterSellCrv = address(this).balance;

        if (_convexAmount > 0) {
            ICurveFi(CVX_ETH_POOL).exchange(1, 0, _convexAmount, 0, true);
        }

        // fulfill 'SwapRewardsToWants' event data
        _rewardTokens = new address[](2);
        _rewardAmounts = new uint256[](2);
        _wantTokens = new address[](2);
        _wantAmounts = new uint256[](2);

        _rewardTokens[0] = REWARD_CRV;
        _rewardTokens[1] = REWARD_CVX;
        _rewardAmounts[0] = _crvAmount;
        _rewardAmounts[1] = _convexAmount;
        _wantTokens[0] = USDC;
        _wantTokens[1] = USDC;

        uint256 _ethBalanceAfterSellTotal = address(this).balance;
        uint256 _usdcBalanceInit = balanceOfToken(USDC);
        uint256 _usdcBalanceAfterSellWeth;
        uint256 _usdcAmountSell;

        if (_ethBalanceAfterSellTotal > 0) {
            //ETH wrap to WETH
            IWeth(WETH).deposit{value: _ethBalanceAfterSellTotal}();
            //swap from WETH to USDC
            IUniswapV2Router2(SUSHI_ROUTER_ADDR).swapExactTokensForTokens(
                balanceOfToken(WETH),
                0,
                rewardRoutes[WETH],
                address(this),
                block.timestamp
            );
            _usdcBalanceAfterSellWeth = balanceOfToken(USDC);
            _usdcAmountSell = _usdcBalanceAfterSellWeth - _usdcBalanceInit;

            // fulfill 'SwapRewardsToWants' event data
            if (_ethBalanceAfterSellTotal - _ethBalanceInit > 0) {
                _wantAmounts[0] =
                    (_usdcAmountSell * (_ethBalanceAfterSellCrv - _ethBalanceInit)) /
                    (_ethBalanceAfterSellTotal - _ethBalanceInit);
                _wantAmounts[1] = _usdcAmountSell - _wantAmounts[0];
            }

            IERC20Upgradeable(USDC).safeApprove(curveUsdcIbforexPool, 0);
            IERC20Upgradeable(USDC).safeApprove(curveUsdcIbforexPool, _usdcBalanceAfterSellWeth);
            ICurveMini(curveUsdcIbforexPool).exchange(1, 0, _usdcBalanceAfterSellWeth, 0);
        }
    }

    /// @dev Return the price in USD (1e30) of collateral token
    function _collateralTokenPrice() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(COLLATERAL_CTOKEN));
    }

    /// @dev Return the price in USD (1e30) of borrow token
    function _borrowTokenPrice() internal view returns (uint256) {
        return _getNormalizedBorrowToken();
    }

    function _getNormalizedBorrowToken() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(borrowCToken)) * 1e12;
    }

    /// @dev Return the maximum number of borrowing under the specified amount of _collateral assets
    function _borrowAvaiable(uint256 liqudity) internal view returns (uint256 _borrowAvaible) {
        address _borrowToken = getIronBankForex();
        uint256 _borrowTokenPrice = _borrowTokenPrice(); // decimals 1e30
        //Maximum number of loans available
        uint256 _maxBorrowAmount = (liqudity * decimalUnitOfToken(_borrowToken)) /
            _borrowTokenPrice;
        //Borrowable quantity under the current borrowFactor factor
        _borrowAvaible = (_maxBorrowAmount * borrowFactor) / BPS;
    }

    /// @dev Return the amount of current total available borrow
    function _currentBorrowAvaible() internal view returns (uint256 _borrowAvaible) {
        // Pledge discount _rate, base 1e18
        (, uint256 _rate) = COMPTROLLER.markets(address(COLLATERAL_CTOKEN));
        uint256 _liquidity = (collateralAssets() * 1e12 * _rate) / 1e18; //multi 1e12 for liquidity convert to 1e30
        _borrowAvaible = _borrowAvaiable(_liquidity);
    }

    /// @dev Add _collateral to IronBank
    function _mintCollateralCToken(uint256 mintAmount) internal {
        address _collateralC = address(COLLATERAL_CTOKEN);
        //saving gas
        // mint Collateral
        IERC20Upgradeable(COLLATERAL_TOKEN).safeApprove(_collateralC, 0);
        IERC20Upgradeable(COLLATERAL_TOKEN).safeApprove(_collateralC, mintAmount);
        COLLATERAL_CTOKEN.mint(mintAmount);
        // enter market
        address[] memory _markets = new address[](1);
        _markets[0] = _collateralC;
        COMPTROLLER.enterMarkets(_markets);
    }

    /// @dev Added Forex to Curve pool
    function curveAddLiquidity(uint256 _ibTokenAmount) internal {
        ICurveFi(getCurveLpToken()).add_liquidity([_ibTokenAmount, 0], 0);
    }

    /// @dev Curve remove liquidity
    function curveRemoveLiquidity(uint256 shareAmount) internal {
        ICurveFi(getCurveLpToken()).remove_liquidity_one_coin(shareAmount, 0, 0);
    }

    /// @dev Invest IronBank token to Curve pool by Convex
    function _invest(uint256 _ibTokenAmount) internal {
        curveAddLiquidity(_ibTokenAmount);

        address lpToken = getCurveLpToken();
        uint256 _liquidity = balanceOfToken(lpToken);
        address _booster = BOOSTER;
        //saving gas
        if (_liquidity > 0) {
            IERC20Upgradeable(lpToken).safeApprove(_booster, 0);
            IERC20Upgradeable(lpToken).safeApprove(_booster, _liquidity);
            IConvex(_booster).deposit(pId, _liquidity, true);
        }
    }

    /// @dev Borrow forex
    function _borrowForex(uint256 _borrowAmount) internal returns (uint256 _receiveAmount) {
        CTokenInterface _borrowC = borrowCToken;
        //saving gas
        _borrowC.borrow(_borrowAmount);
        _receiveAmount = balanceOfToken(_borrowC.underlying());
    }

    /// @dev Repay forex
    function _repayForex(uint256 _repayAmount) internal {
        CTokenInterface _borrowC = borrowCToken;
        //saving gas
        address _borrowToken = _borrowC.underlying();
        IERC20Upgradeable(_borrowToken).safeApprove(address(_borrowC), 0);
        IERC20Upgradeable(_borrowToken).safeApprove(address(_borrowC), _repayAmount);
        _borrowC.repayBorrow(_repayAmount);
    }

    /// @dev Increase the amount of borrow
    function increaseBorrow() public isKeeperOrVaultOrGovOrDelegate {
        (uint256 _space, ) = borrowInfo();
        if (_space > 0) {
            //borrow forex
            uint256 _receiveAmount = _borrowForex(_space);
            _invest(_receiveAmount);
        }
    }

    /// @dev  decrease borrow
    function decreaseBorrow() public isKeeperOrVaultOrGovOrDelegate {
        //The number of borrowing that will be out of range after redemption
        (, uint256 _overflow) = borrowInfo();
        if (_overflow > 0) {
            uint256 _totalStaking = balanceOfToken(rewardPool);
            uint256 _currentBorrow = borrowCToken.borrowBalanceCurrent(address(this));
            uint256 _cvxLpAmount = (_totalStaking * _overflow) / _currentBorrow;
            _redeem(_cvxLpAmount);
            uint256 _borrowTokenBalance = balanceOfToken(borrowCToken.underlying());
            _repayForex(_borrowTokenBalance);
        }
    }

    /// @notice Sets `_borrowFactor` to `borrowFactor`
    /// @param _borrowFactor The new value of `borrowFactor`
    /// Requirements: only vault manager can call
    function setBorrowFactor(uint256 _borrowFactor) external isVaultManager {
        require(_borrowFactor < BPS, "setting output the range");
        borrowFactor = _borrowFactor;

        emit UpdateBorrowFactor(_borrowFactor);
    }

    /// @dev Redeem assets invested by this strategy
    function _redeem(uint256 _cvxLpAmount) internal {
        IConvexReward(rewardPool).withdraw(_cvxLpAmount, false);
        IConvex(BOOSTER).withdraw(pId, _cvxLpAmount);
        //curve remove liquidity
        curveRemoveLiquidity(_cvxLpAmount);
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        require(_assets[0] == address(COLLATERAL_TOKEN) && _amounts[0] > 0);
        uint256 _collateralAmount = _amounts[0];
        _mintCollateralCToken(_collateralAmount);
        (uint256 _space, ) = borrowInfo();
        if (_space > 0) {
            // borrow forex
            uint256 _receiveAmount = _borrowForex(_space);
            _invest(_receiveAmount);
        }
    }

    /// @notice Strategy withdraw the funds from third party pool
    /// @param _withdrawShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @param _outputCode The code of output
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        // if withdraw all,force claim reward.
        if (_withdrawShares == _totalShares) {
            harvest();
        }
        uint256 _totalStaking = balanceOfToken(rewardPool);
        uint256 _cvxLpAmount = (_totalStaking * _withdrawShares) / _totalShares;
        //saving gas
        CTokenInterface _borrowC = borrowCToken;
        //saving gas
        CTokenInterface _collateralC = COLLATERAL_CTOKEN;
        if (_cvxLpAmount > 0) {
            _redeem(_cvxLpAmount);
            // ib Token Amount
            address _borrowToken = _borrowC.underlying();
            uint256 _borrowTokenBalance = balanceOfToken(_borrowToken);
            uint256 _currentBorrow = _borrowC.borrowBalanceCurrent(address(this));
            uint256 _repayAmount = (_currentBorrow * _withdrawShares) / _totalShares;
            _repayAmount = MathUpgradeable.min(_repayAmount, _borrowTokenBalance);
            _repayForex(_repayAmount);
            uint256 _burnAmount = (balanceOfToken(address(_collateralC)) * _repayAmount) /
                _currentBorrow;
            _collateralC.redeem(_burnAmount);
            //The excess _borrowToken is exchanged for U
            uint256 _profit = balanceOfToken(_borrowToken);
            if (_profit > 0) {
                IERC20Upgradeable(_borrowToken).safeApprove(curveUsdcIbforexPool, 0);
                IERC20Upgradeable(_borrowToken).safeApprove(curveUsdcIbforexPool, _profit);
                // swap ibToken to USDC
                ICurveMini(curveUsdcIbforexPool).exchange(0, 1, _profit, 0);
                uint256 _usdcBalance = balanceOfToken(USDC);
                IUniswapV2Router2(UNI_ROUTER_ADDR).swapExactTokensForTokens(
                    _usdcBalance,
                    0,
                    rewardRoutes[USDC],
                    address(this),
                    block.timestamp
                );
            }
        }
    }
}
