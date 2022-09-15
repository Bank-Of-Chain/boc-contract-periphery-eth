// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "boc-contract-core/contracts/strategy/BaseStrategy.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "./../../../enums/ProtocolEnum.sol";

import "../../../../external/cream/CTokenInterface.sol";
import "../../../../external/cream/Comptroller.sol";
import "../../../../external/cream/IPriceOracle.sol";
import "../../../../external/convex/IConvex.sol";
import "../../../../external/convex/IConvexReward.sol";
import "../../../../external/curve/ICurveFi.sol";

import "../../../../external/uniswap/IUniswapV2Router2.sol";
import "../../../../external/curve/ICurveMini.sol";

import "../../../../external/synthetix/IAddressResolver.sol";
import "../../../../external/synthetix/IReadProxy.sol";
import "../../../../external/synthetix/ISynth.sol";
import "../../../../external/synthetix/ISynthetix.sol";
import "../../../../external/synthetix/IExchanger.sol";
import "../../../../external/synthetix/IExchangeState.sol";
import "../../../../external/synthetix/ISystemStatus.sol";


contract ConvexIBUsdtStrategy is Initializable, BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // IronBank
    Comptroller public constant COMPTROLLER =
        Comptroller(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    IPriceOracle public priceOracle;

    address public constant COLLATERAL_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    CTokenInterface public constant COLLATERAL_CTOKEN =
        CTokenInterface(0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a);

    CTokenInterface public borrowCToken;
    address public rewardPool;
    uint256 internal pId;
    // borrow factor
    uint256 public borrowFactor;

    // minimum amount to be liquidation
    uint256 public constant SELL_FLOOR = 1e16;
    uint256 public constant BPS = 10000;
    address public constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant REWARD_CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant REWARD_CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant SETH = 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb;
    // rkp3r
    address internal constant RKPR = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;

    // use Curve to sell our CVX and CRV rewards to ETH
    address internal constant CRV_ETH_POOL = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511; // use curve's new CRV-ETH crypto pool to sell our CRV
    address internal constant CVX_ETH_POOL = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4; // use curve's new CVX-ETH crypto pool to sell our CVX
    address internal constant SETH_ETH_Pool = 0xc5424B857f758E906013F3555Dad202e4bdB4567; // use curve's sETH-ETH crypto pool to swap our ETH to sETH
    //sushi router
    address internal constant SUSHI_ROUTER_ADDR = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    //uni router
    address internal constant UNI_ROUTER_ADDR = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Synthetix
    IAddressResolver internal constant ADDRESS_RESOLVER =
        IAddressResolver(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83);
    // this is how we check if our market is closed
    ISystemStatus internal constant SYSTEM_STATUS =
        ISystemStatus(0x1c86B3CDF2a60Ae3a574f7f71d44E2C50BDdB87E);
    bytes32 internal constant SETH_CURRENCY_KEY = "sETH";
    bytes32 internal constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 internal constant CONTRACT_EXCHANGE_STATE = "ExchangeState";
    bytes32 internal synthCurrencyKey;

    //reward swap path
    mapping(address => address[]) public rewardRoutes;

    address public curveUsdcIbforexPool;

    /// Events
    event UpdateBorrowFactor(uint256 _borrowFactor);
    event SwapRewardsToWants(
        address _strategy,
        address[] _rewards,
        uint256[] _rewardAmounts,
        address[] _wants,
        uint256[] _wantAmounts
    );

    // === fallback and receive === //
    receive() external payable {}

    fallback() external payable {}

    function setBorrowFactor(uint256 _borrowFactor) external isVaultManager {
        require(_borrowFactor < BPS, "setting output the range");
        borrowFactor = _borrowFactor;

        emit UpdateBorrowFactor(_borrowFactor);
    }

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

        // init synth forex key
        address _synthForexAddr = getSynthForex();
        synthCurrencyKey = ISynth(IReadProxy(_synthForexAddr).target()).currencyKey();

        borrowFactor = 8300;

        uint256 _uintMax = type(uint256).max;
        // approve sell rewards
        IERC20Upgradeable(REWARD_CRV).safeApprove(address(CRV_ETH_POOL), _uintMax);
        IERC20Upgradeable(REWARD_CVX).safeApprove(address(CVX_ETH_POOL), _uintMax);
        IERC20Upgradeable(SETH).safeApprove(
            ADDRESS_RESOLVER.getAddress(CONTRACT_SYNTHETIX),
            _uintMax
        );
        // approve deposit
        address _curveForexPool = getCurveLpToken();
        address _borrowToken = borrowCToken.underlying();
        IERC20Upgradeable(_borrowToken).safeApprove(_curveForexPool, _uintMax);
        IERC20Upgradeable(_synthForexAddr).safeApprove(_curveForexPool, _uintMax);

        IERC20Upgradeable(_borrowToken).safeApprove(SUSHI_ROUTER_ADDR, _uintMax);
        IERC20Upgradeable(USDC).safeApprove(UNI_ROUTER_ADDR, _uintMax);

        //init reward swap path
        address[] memory _ib2usdc = new address[](2);
        _ib2usdc[0] = _borrowToken;
        _ib2usdc[1] = USDC;
        rewardRoutes[_borrowToken] = _ib2usdc;
        address[] memory _usdc2usdt = new address[](2);
        _usdc2usdt[0] = USDC;
        _usdc2usdt[1] = COLLATERAL_TOKEN;
        rewardRoutes[USDC] = _usdc2usdt;
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    // ==== External === //
    // USD-1e18
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

    // ==== Public ==== //

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

    /**
     *  Total strategy valuation, in currency denominated units
     */
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

    /**
     *  _debt Rate
     */
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

    //assets(USD) -18
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

    /**
     *  debts(USD-1e18)
     */
    function debts() public view returns (uint256 _value) {
        //for saving gas
        CTokenInterface _borrowCToken = borrowCToken;
        uint256 _borrowBalanceCurrent = _borrowCToken.borrowBalanceStored(address(this));
        address _borrowToken = _borrowCToken.underlying();
        _value =
            (_borrowBalanceCurrent * _borrowTokenPrice()) /
            decimalUnitOfToken(_borrowToken) /
            1e12; //div 1e12 for normalized
    }

    //_collateral assets（USD-1e18)
    function collateralAssets() public view returns (uint256 _value) {
        //saving gas
        CTokenInterface _collateralC = COLLATERAL_CTOKEN;
        address _collateralToken = COLLATERAL_TOKEN;
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

    // borrow info
    function borrowInfo() public view returns (uint256 _space, uint256 _overflow) {
        uint256 _borrowAvaible = _currentBorrowAvaible();
        uint256 _currentBorrow = borrowCToken.borrowBalanceStored(address(this));
        if (_borrowAvaible > _currentBorrow) {
            _space = _borrowAvaible - _currentBorrow;
        } else {
            _overflow = _currentBorrow - _borrowAvaible;
        }
    }

    function getCurveLpToken() public view returns (address) {
        return IConvex(BOOSTER).poolInfo(pId).lptoken;
    }

    function getIronBankForex() public view returns (address) {
        ICurveFi _curveForexPool = ICurveFi(getCurveLpToken());
        return _curveForexPool.coins(0);
    }

    function getSynthForex() public view returns (address) {
        ICurveFi _curveForexPool = ICurveFi(getCurveLpToken());
        return _curveForexPool.coins(1);
    }

    function checkWaitingPeriod() public view returns (bool) {
        IExchanger _exchanger = IExchanger(ADDRESS_RESOLVER.getAddress(CONTRACT_EXCHANGER));
        // check if it's been >5 mins since we traded our sETH for our synth
        return _exchanger.maxSecsLeftInWaitingPeriod(address(this), synthCurrencyKey) == 0;
    }

    /**
     * 采用SynthForex复投进Curve池
     */
    function investWithSynthForex() public isKeeper returns (bool) {
        uint256 _balanceOfSForex = balanceOfToken(getSynthForex());
        if (_balanceOfSForex > 0 && checkWaitingPeriod()) {
            _invest(0, _balanceOfSForex);
            vault.report(new address[](0), new uint256[](0));
            return true;
        }
        return false;
    }

    function isMarketClosed() public view returns (bool) {
        // use our synth key
        bytes32[] memory _synthArray = new bytes32[](1);
        _synthArray[0] = synthCurrencyKey;

        // check if trading is open or not. true = market is closed
        (bool[] memory _tradingSuspended, ) = SYSTEM_STATUS.getSynthExchangeSuspensions(_synthArray);
        return _tradingSuspended[0];
    }

    /**
     *   Sell reward and reinvestment logic
     */
    function harvest()
        public
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        // for event
        address[] memory _wantTokens;
        uint256[] memory _wantAmounts;
        IConvexReward _convexReward = IConvexReward(rewardPool);
        if (_convexReward.earned(address(this)) > SELL_FLOOR) {
            _convexReward.getReward();
            uint256 _crvBalance = balanceOfToken(REWARD_CRV);
            uint256 _cvxBalance = balanceOfToken(REWARD_CVX);
            _rewardsTokens = new address[](2);
            _rewardsTokens[0] = REWARD_CRV;
            _rewardsTokens[1] = REWARD_CVX;
            _claimAmounts = new uint256[](2);
            _claimAmounts[0] = _crvBalance;
            _claimAmounts[1] = _cvxBalance;
            // sell crv、cvx to seth
            (_wantTokens, _wantAmounts) = _sellCrvAndCvx(_crvBalance, _cvxBalance);

            //sell kpr
            uint256 _rkprBalance = balanceOfToken(RKPR);
            if (_rkprBalance > 0) {
                IERC20Upgradeable(RKPR).safeTransfer(harvester, _rkprBalance);
            }
        }

        // seth swap to sForex
        uint256 _balanceOfSETH = balanceOfToken(SETH);
        if (_balanceOfSETH > 0 && !isMarketClosed()) {
            _sETH2Synth(_balanceOfSETH);
        }

        // report empty array for _profit
        vault.report(_rewardsTokens, _claimAmounts);

        // emit 'SwapRewardsToWants' event after vault report
        emit SwapRewardsToWants(
            address(this),
            _rewardsTokens,
            _claimAmounts,
            _wantTokens,
            _wantAmounts
        );
    }

    /**
     *  sell crv and cvx
     */
    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount)
        internal
        returns (address[] memory _wantTokens, uint256[] memory _wantAmounts)
    {
        // fulfill 'SwapRewardsToWants' event data
        _wantTokens = new address[](2);
        _wantAmounts = new uint256[](2);

        _wantTokens[0] = NativeToken.NATIVE_TOKEN;
        _wantTokens[1] = NativeToken.NATIVE_TOKEN;

        if (_crvAmount > 0) {
            ICurveFi(CRV_ETH_POOL).exchange(1, 0, _crvAmount, 0, true);
            _wantAmounts[0] = address(this).balance;
        }

        if (_convexAmount > 0) {
            ICurveFi(CVX_ETH_POOL).exchange(1, 0, _convexAmount, 0, true);
            _wantAmounts[1] = address(this).balance - _wantAmounts[0];
        }

        // ETH to sETH
        uint256 _ethBalance = address(this).balance;
        if (_ethBalance > 0) {
            ICurveFi(SETH_ETH_Pool).exchange{value: _ethBalance}(0, 1, _ethBalance, 0);
        }
    }

    function _sETH2Synth(uint256 _sETHBalance) internal {
        bytes32 _synthCurrencyKey = synthCurrencyKey;
        IAddressResolver _addressResolver = ADDRESS_RESOLVER;
        ISynthetix _synthetix = ISynthetix(_addressResolver.getAddress(CONTRACT_SYNTHETIX));
        _synthetix.exchange(SETH_CURRENCY_KEY, _sETHBalance, _synthCurrencyKey);
        IExchangeState _exchangeState = IExchangeState(
            _addressResolver.getAddress(CONTRACT_EXCHANGE_STATE)
        );
        if (
            _exchangeState.maxEntriesInQueue() ==
            _exchangeState.getLengthOfEntries(address(this), _synthCurrencyKey)
        ) {
            IExchanger _exchanger = IExchanger(_addressResolver.getAddress(CONTRACT_EXCHANGER));
            _exchanger.settle(address(this), _synthCurrencyKey);
        }
    }

    // Collateral Token Price In USD ,decimals 1e30
    function _collateralTokenPrice() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(COLLATERAL_CTOKEN));
    }

    // Borrown Token Price In USD ，decimals 1e30
    function _borrowTokenPrice() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(borrowCToken)) * 1e12;
    }

    // Maximum number of borrowings under the specified amount of _collateral assets
    function _borrowAvaiable(uint256 liqudity) internal view returns (uint256 _borrowAvaible) {
        address _borrowToken = getIronBankForex();
        //Maximum number of loans available
        uint256 _maxBorrowAmount = (liqudity * decimalUnitOfToken(_borrowToken)) /
            _borrowTokenPrice();
        //Borrowable quantity under the current borrowFactor factor
        _borrowAvaible = (_maxBorrowAmount * borrowFactor) / BPS;
    }

    // Current total available borrowing amount
    function _currentBorrowAvaible() internal view returns (uint256 _borrowAvaible) {
        // Pledge discount _rate, base 1e18
        (, uint256 _rate) = COMPTROLLER.markets(address(COLLATERAL_CTOKEN));
        uint256 _liquidity = (collateralAssets() * 1e12 * _rate) / 1e18; //multi 1e12 for liquidity convert to 1e30
        _borrowAvaible = _borrowAvaiable(_liquidity);
    }

    // Add _collateral to IronBank
    function _mintCollateralCToken(uint256 mintAmount) internal {
        //saving gas
        address _collateralC = address(COLLATERAL_CTOKEN);
        // mint Collateral
        IERC20Upgradeable(COLLATERAL_TOKEN).safeApprove(_collateralC, 0);
        IERC20Upgradeable(COLLATERAL_TOKEN).safeApprove(_collateralC, mintAmount);
        COLLATERAL_CTOKEN.mint(mintAmount);
        // enter market
        address[] memory _markets = new address[](1);
        _markets[0] = _collateralC;
        COMPTROLLER.enterMarkets(_markets);
    }

    // Forex added to Curve pool
    function curveAddLiquidity(uint256 _ibTokenAmount, uint256 _sTokenAmount) internal {
        ICurveFi(getCurveLpToken()).add_liquidity([_ibTokenAmount, _sTokenAmount], 0);
    }

    // curve remove liquidity
    function curveRemoveLiquidity(uint256 shareAmount) internal {
        ICurveFi(getCurveLpToken()).remove_liquidity_one_coin(shareAmount, 0, 0);
    }

    function _invest(uint256 _ibTokenAmount, uint256 _sTokenAmount) internal {
        curveAddLiquidity(_ibTokenAmount, _sTokenAmount);

        address lpToken = getCurveLpToken();
        uint256 _liquidity = balanceOfToken(lpToken);
        //saving gas
        address _booster = BOOSTER;
        if (_liquidity > 0) {
            IERC20Upgradeable(lpToken).safeApprove(_booster, 0);
            IERC20Upgradeable(lpToken).safeApprove(_booster, _liquidity);
            IConvex(_booster).deposit(pId, _liquidity, true);
        }
    }

    // borrow forex
    function _borrowForex(uint256 _borrowAmount) internal returns (uint256 _receiveAmount) {
        //saving gas
        CTokenInterface _borrowC = borrowCToken;
        _borrowC.borrow(_borrowAmount);
        _receiveAmount = balanceOfToken(_borrowC.underlying());
    }

    // repay forex
    function _repayForex(uint256 _repayAmount) internal {
        //saving gas
        CTokenInterface _borrowC = borrowCToken;
        address _borrowToken = _borrowC.underlying();
        IERC20Upgradeable(_borrowToken).safeApprove(address(_borrowC), 0);
        IERC20Upgradeable(_borrowToken).safeApprove(address(_borrowC), _repayAmount);
        _borrowC.repayBorrow(_repayAmount);
    }

    // increase borrow
    function increaseBorrow() public isKeeper {
        (uint256 _space, ) = borrowInfo();
        if (_space > 0) {
            //borrow forex
            uint256 _receiveAmount = _borrowForex(_space);
            _invest(_receiveAmount, 0);
        }
    }

    // decrease borrow
    function decreaseBorrow() public isKeeper {
        //The number of borrowings that will be out of range after redemption
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

    function _redeem(uint256 _cvxLpAmount) internal {
        IConvexReward(rewardPool).withdraw(_cvxLpAmount, false);
        IConvex(BOOSTER).withdraw(pId, _cvxLpAmount);
        //curve remove liquidity
        curveRemoveLiquidity(_cvxLpAmount);
    }

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
            _invest(_receiveAmount, 0);
        }
    }

    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        // Wraning:reinvest need to time interval, this strategy does not forced claim when withdraw all.
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
                IUniswapV2Router2(SUSHI_ROUTER_ADDR).swapExactTokensForTokens(
                    _profit,
                    0,
                    rewardRoutes[_borrowToken],
                    address(this),
                    block.timestamp
                );
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
