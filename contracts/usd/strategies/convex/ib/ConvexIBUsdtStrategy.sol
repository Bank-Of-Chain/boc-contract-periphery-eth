// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "hardhat/console.sol";
import "boc-contract-core/contracts/strategy/BaseStrategy.sol";
import "./../../../enums/ProtocolEnum.sol";

import "../../../../external/cream/CTokenInterface.sol";
import "../../../../external/cream/Comptroller.sol";
import "../../../../external/cream/IPriceOracle.sol";
import "../../../../external/convex/IConvex.sol";
import "../../../../external/convex/IConvexReward.sol";
import "../../../../external/curve/ICurveFi.sol";
import "../../../../external/synthetix/IAddressResolver.sol";
import "../../../../external/synthetix/IReadProxy.sol";
import "../../../../external/synthetix/ISynth.sol";
import "../../../../external/synthetix/ISynthetix.sol";
import "../../../../external/synthetix/IExchanger.sol";
import "../../../../external/synthetix/IExchangeState.sol";
import "../../../../external/synthetix/ISystemStatus.sol";
import "../../../../external/uniswap/IUniswapV2Router2.sol";

contract ConvexIBUsdtStrategy is Initializable, BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // minimum amount to be liquidation
    uint256 public constant SELL_FLOOR = 1e16;

    // IronBank
    Comptroller public constant comptroller =
        Comptroller(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    IPriceOracle public constant priceOracle =
        IPriceOracle(0x6B96c414ce762578c3E7930da9114CffC88704Cb);

    address public constant collateralToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    CTokenInterface public constant collateralCToken =
        CTokenInterface(0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a);

    CTokenInterface public borrowCToken;
    address public rewardPool;
    uint256 internal _pid;
    // borrow factor
    uint256 public borrowFactor;

    uint256 public constant BPS = 10000;
    address public constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant SETH = 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb;
    address public constant rewardCRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant rewardCVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // kp3r and rkp3r
    address internal constant rkpr = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;
    // address internal constant kpr = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;

    // use Curve to sell our CVX and CRV rewards to WETH
    address internal constant crvethPool = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511; // use curve's new CRV-ETH crypto pool to sell our CRV
    address internal constant cvxethPool = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4; // use curve's new CVX-ETH crypto pool to sell our CVX
    address internal constant sethethPool = 0xc5424B857f758E906013F3555Dad202e4bdB4567; // use curve's sETH-ETH crypto pool to swap our ETH to sETH

    // Synthetix
    IAddressResolver public constant addressResolver =
        IAddressResolver(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83);
    // this is how we check if our market is closed
    ISystemStatus internal constant systemStatus =
        ISystemStatus(0x1c86B3CDF2a60Ae3a574f7f71d44E2C50BDdB87E);
    bytes32 internal constant sethCurrencyKey = "sETH";
    bytes32 internal constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 internal constant CONTRACT_EXCHANGE_STATE = "ExchangeState";
    bytes32 public synthCurrencyKey;

    //sushi router
    address internal constant sushiRouterAddr =
        address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    //uni router
    address internal constant uniRouterAddr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    //uni v3
    address internal constant uniswapv3 = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    //reward swap path
    mapping(address => address[]) public rewardRoutes;

    function initialize(
        address _vault,
        address _harvester,
        string memory _strategyName,
        address _borrowCToken,
        address _rewardPool
    ) external initializer {
        borrowCToken = CTokenInterface(_borrowCToken);
        rewardPool = _rewardPool;
        _pid = IConvexReward(rewardPool).pid();
        address[] memory _wants = new address[](1);
        _wants[0] = collateralToken;

        _initialize(_vault, _harvester, _strategyName, uint16(ProtocolEnum.Convex), _wants);

        // init synth forex key
        address synthForexAddr = getIronBankForex();
        synthCurrencyKey = ISynth(IReadProxy(synthForexAddr).target()).currencyKey();
        console.logBytes32(synthCurrencyKey);

        borrowFactor = 8300;

        uint256 uintMax = type(uint256).max;
        // approve sell rewards
        IERC20Upgradeable(rewardCRV).safeApprove(address(crvethPool), uintMax);
        IERC20Upgradeable(rewardCVX).safeApprove(address(cvxethPool), uintMax);
        IERC20Upgradeable(SETH).safeApprove(
            addressResolver.getAddress(CONTRACT_SYNTHETIX),
            uintMax
        );

        // approve deposit
        address curveForexPool = getCurveLpToken();
        address borrowToken = borrowCToken.underlying();
        IERC20Upgradeable(borrowToken).safeApprove(curveForexPool, uintMax);
        IERC20Upgradeable(synthForexAddr).safeApprove(curveForexPool, uintMax);
        console.log("synthForexAddr:%s", synthForexAddr);

        IERC20Upgradeable(borrowToken).safeApprove(sushiRouterAddr, uintMax);
        IERC20Upgradeable(USDC).safeApprove(uniRouterAddr, uintMax);

        //init reward swap path
        address[] memory ib2usdc = new address[](2);
        ib2usdc[0] = borrowToken;
        ib2usdc[1] = USDC;
        rewardRoutes[borrowToken] = ib2usdc;
        address[] memory usdc2usdt = new address[](2);
        usdc2usdt[0] = USDC;
        usdc2usdt[1] = collateralToken;
        rewardRoutes[USDC] = usdc2usdt;
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    // ==== External === //
    // USD-1e18
    function get3rdPoolAssets() public view override returns (uint256 targetPoolTotalAssets) {
        address _curvePool = getCurveLpToken();
        uint256 virtualPrice = ICurveFi(_curvePool).get_virtual_price();
        uint256 totalSupply = IERC20Upgradeable(_curvePool).totalSupply();
        //30 = 18+12,div 1e12 for normalized,div 1e18 for virtualPrice
        targetPoolTotalAssets =
            (virtualPrice * totalSupply * _borrowTokenPrice()) /
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
        returns (OutputInfo[] memory outputsInfo)
    {
        outputsInfo = new OutputInfo[](1);
        OutputInfo memory info0 = outputsInfo[0];
        info0.outputCode = 0;
        info0.outputTokens = wants;
    }

    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool isUsd,
            uint256 usdValue
        )
    {
        isUsd = true;
        // The usdValue needs to be filled with precision
        usdValue = _estimatedTotalUsdValue();
        console.log("[%s] getPositionDetail: %s", this.name(), usdValue);
    }

    /**
     *  Total strategy valuation, in currency denominated units
     */
    function curvePoolAssets() public view returns (uint256 depositedAssets) {
        uint256 rewardBalance = balanceOfToken(rewardPool);
        if (rewardBalance > 0) {
            depositedAssets =
                (_borrowTokenPrice() *
                    ICurveFi(getCurveLpToken()).calc_withdraw_one_coin(rewardBalance, 0)) /
                1e12 /
                decimalUnitOfToken(getCurveLpToken());
        } else {
            depositedAssets = 0;
        }
        console.log(
            "[%s] rewardBalance:%s,curvePoolAssets:%s",
            this.name(),
            rewardBalance,
            depositedAssets
        );
    }

    /**
     *  debt rate
     */
    function debtRate() public view returns (uint256 vaule) {
        uint256 netAssets = _estimatedTotalUsdValue();
        if (netAssets == 0) {
            return 0;
        }
        uint256 debt = debts();
        return (debt * BPS) / netAssets;
    }

    //assets(USD) -18
    function assets() public view returns (uint256 value) {
        // estimatedDepositedAssets
        uint256 deposited = curvePoolAssets();
        value += deposited;
        // CToken value
        value += collateralAssets();
        address _collateralToken = collateralToken;
        // balance
        uint256 underlyingBalance = balanceOfToken(collateralToken);
        if (underlyingBalance > 0) {
            value +=
                ((underlyingBalance * _collateralTokenPrice()) /
                    decimalUnitOfToken(collateralToken)) /
                1e12;
        }
    }

    /**
     *  debts(USD-1e18)
     */
    function debts() public view returns (uint256 value) {
        CTokenInterface _borrowCToken = borrowCToken;
        //for saving gas
        uint256 borrowBalanceCurrent = _borrowCToken.borrowBalanceStored(address(this));
        address borrowToken = _borrowCToken.underlying();
        uint256 borrowTokenPrice = _borrowTokenPrice();
        value = (borrowBalanceCurrent * borrowTokenPrice) / decimalUnitOfToken(borrowToken) / 1e12; //div 1e12 for normalized
        console.log("debts:%s", value);
    }

    function checkWaitingPeriod() public view returns (bool freeToMove) {
        IExchanger exchanger = IExchanger(addressResolver.getAddress(CONTRACT_EXCHANGER));
        // check if it's been >5 mins since we traded our sETH for our synth
        return exchanger.maxSecsLeftInWaitingPeriod(address(this), synthCurrencyKey) == 0;
    }

    /**
     * SynthForex is used to re-inject into the Curve pool
     */
    function investWithSynthForex() public isKeeper returns (bool) {
        uint256 balanceOfSynthForex = balanceOfToken(getIronBankForex());
        if (balanceOfSynthForex > 0 && checkWaitingPeriod()) {
            _invest(0, balanceOfSynthForex);
            // Calculate APY && Report new valuation
            address[] memory _rewardTokens = new address[](0);

            uint256[] memory _claimAmounts = new uint256[](0);
            vault.report(_rewardTokens, _claimAmounts);
            return true;
        }
        return false;
    }

    function isMarketClosed() public view returns (bool) {
        // set up our arrays to use
        bool[] memory tradingSuspended;
        bytes32[] memory synthArray;

        // use our synth key
        synthArray = new bytes32[](1);
        synthArray[0] = synthCurrencyKey;

        // check if trading is open or not. true = market is closed
        (tradingSuspended, ) = systemStatus.getSynthExchangeSuspensions(synthArray);
        return tradingSuspended[0];
    }

    //collateral assets（USD-1e18)
    function collateralAssets() public view returns (uint256 value) {
        CTokenInterface collateralC = collateralCToken;
        address _collateralToken = collateralToken;
        //saving gas
        uint256 exchangeRateMantissa = collateralC.exchangeRateStored();
        uint256 collateralTokenAmount = ((balanceOfToken(address(collateralC)) *
            exchangeRateMantissa) * decimalUnitOfToken(_collateralToken)) /
            1e16 /
            decimalUnitOfToken(address(collateralC));
        uint256 collateralTokenPrice = _collateralTokenPrice();
        value =
            (collateralTokenAmount * collateralTokenPrice) /
            decimalUnitOfToken(_collateralToken) /
            1e12; //div 1e12 for normalized
    }

    // borrow info
    function borrowInfo() public view returns (uint256 space, uint256 overflow) {
        uint256 borrowAvaible = _currentBorrowAvaible();
        uint256 currentBorrow = borrowCToken.borrowBalanceStored(address(this));
        if (borrowAvaible > currentBorrow) {
            space = borrowAvaible - currentBorrow;
        } else {
            overflow = currentBorrow - borrowAvaible;
        }
        console.log(
            "borrowInfo space:%s,overflow:%s borrowAvaible:%s",
            space,
            overflow,
            borrowAvaible
        );
    }

    function getCurveLpToken() public view returns (address) {
        return IConvex(BOOSTER).poolInfo(_pid).lptoken;
    }

    function getIronBankForex() public view returns (address) {
        ICurveFi curveForexPool = ICurveFi(getCurveLpToken());
        return curveForexPool.coins(1);
    }

    // ==== Internal ==== //
    /**
     *  estimatedTotalUsdValue
     */
    function _estimatedTotalUsdValue() internal view returns (uint256) {
        uint256 assetsValue = assets();
        uint256 debtsValue = debts();
        console.log("[%s] assets:%s,debts:%s", this.name(), assetsValue, debtsValue);
        console.log(
            "[%s] rewardCRV:%s, rewardCVX:%s",
            this.name(),
            balanceOfToken(rewardCRV),
            balanceOfToken(rewardCVX)
        );
        //Net Assets
        return assetsValue - debtsValue;
    }

    /**
     *   Sell reward and reinvestment logic
     */
    function harvest()
        external
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        // uint256 rewardCRVAmount = IConvexReward(rewardPool).earned(address(this));
        IConvexReward(rewardPool).getReward();
        uint256 crvBalance = balanceOfToken(rewardCRV);
        uint256 cvxBalance = balanceOfToken(rewardCVX);
        console.log("[%s] claim reward:%s,%s", this.name(), crvBalance, cvxBalance);
        _sellCrvAndCvx(crvBalance, cvxBalance);
        //sell kpr
        uint256 rkprBalance = balanceOfToken(rkpr);
        if (rkprBalance > 0) {
            IERC20Upgradeable(rkpr).transfer(harvester, rkprBalance);
        }
        // ETH to sETH
        uint256 ethBalance = address(this).balance;
        ICurveFi(sethethPool).exchange{value: ethBalance}(0, 1, ethBalance, 0);

        uint256 balanceOfSETH = balanceOfToken(SETH);
        console.log("sETH balance:%s", balanceOfSETH);
        if (balanceOfSETH > 0 && !isMarketClosed()) {
            _sETH2Synth(balanceOfSETH);
        }
        // report empty array for profit
        vault.report(_rewardsTokens, _claimAmounts);
    }

    /**
     *  sell crv and cvx
     */
    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount) internal {
        if (_crvAmount > 0) {
            ICurveFi(crvethPool).exchange(1, 0, _crvAmount, 0, true);
        }
        if (_convexAmount > 0) {
            ICurveFi(cvxethPool).exchange(1, 0, _convexAmount, 0, true);
        }
        console.log("[%s] WETH:%s", this.name(), address(this).balance);
    }

    function _sETH2Synth(uint256 sETHBalance) internal {
        bytes32 _synthCurrencyKey = synthCurrencyKey;
        ISynthetix synthetix = ISynthetix(addressResolver.getAddress(CONTRACT_SYNTHETIX));
        console.log("[%s] synthetix address:%s", this.name(), address(synthetix));
        synthetix.exchange(sethCurrencyKey, sETHBalance, _synthCurrencyKey);
        IExchangeState exchangeState = IExchangeState(
            addressResolver.getAddress(CONTRACT_EXCHANGE_STATE)
        );
        if (
            exchangeState.maxEntriesInQueue() ==
            exchangeState.getLengthOfEntries(address(this), _synthCurrencyKey)
        ) {
            IExchanger exchanger = IExchanger(addressResolver.getAddress(CONTRACT_EXCHANGER));
            exchanger.settle(address(this), _synthCurrencyKey);
        }
    }

    // Collateral Token Price In USD ,decimals 1e30
    function _collateralTokenPrice() internal view returns (uint256) {
        uint256 collateralTokenPrice = priceOracle.getUnderlyingPrice(address(collateralCToken));
        console.log("[%s] collateralTokenPrice", this.name(), collateralTokenPrice);
        return collateralTokenPrice;
    }

    // Borrown Token Price In USD ，decimals 1e30
    function _borrowTokenPrice() internal view returns (uint256) {
        uint256 borrowTokenPrice = _getNormalizedBorrowToken();
        console.log("[%s] borrowTokenPrice", this.name(), borrowTokenPrice);
        return borrowTokenPrice;
    }

    function _getNormalizedBorrowToken() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(borrowCToken)) * 1e12;
    }

    // Maximum number of borrowings under the specified amount of collateral assets
    function _borrowAvaiable(uint256 liqudity) internal view returns (uint256 borrowAvaible) {
        address borrowToken = getIronBankForex();
        uint256 borrowTokenPrice = _borrowTokenPrice(); // decimals 1e30
        //Maximum number of loans available
        uint256 maxBorrowAmount = ((liqudity * decimalUnitOfToken(borrowToken))) /
            borrowTokenPrice;
        //Borrowable quantity under the current borrowFactor factor
        borrowAvaible = (maxBorrowAmount * borrowFactor) / BPS;
    }

    // Current total available borrowing amount
    function _currentBorrowAvaible() internal view returns (uint256 borrowAvaible) {
        // Pledge discount rate, base 1e18
        (, uint256 rate) = comptroller.markets(address(collateralCToken));
        uint256 liquidity = (collateralAssets() * 1e12 * rate) / 1e18; //multi 1e12 for liquidity convert to 1e30
        borrowAvaible = _borrowAvaiable(liquidity);
    }

    // Add collateral to IronBank
    function _mintCollateralCToken(uint256 mintAmount) internal {
        address collateralC = address(collateralCToken);
        //saving gas
        // mint Collateral
        IERC20Upgradeable(collateralToken).safeApprove(collateralC, 0);
        IERC20Upgradeable(collateralToken).safeApprove(collateralC, mintAmount);
        console.log("[%s] mint amount:%s", this.name(), mintAmount);
        collateralCToken.mint(mintAmount);
        // enter market
        address[] memory markets = new address[](1);
        markets[0] = collateralC;
        comptroller.enterMarkets(markets);
    }

    // Forex added to Curve pool
    function curveAddLiquidity(uint256 ibTokenAmount, uint256 sTokenAmount) internal {
        ICurveFi(getCurveLpToken()).add_liquidity([ibTokenAmount, sTokenAmount], 0);
    }

    // curve remove liquidity
    function curveRemoveLiquidity(uint256 shareAmount) internal {
        ICurveFi(getCurveLpToken()).remove_liquidity_one_coin(shareAmount, 0, 0);
    }

    function _invest(uint256 ibTokenAmount, uint256 synthTokenAmount) internal {
        curveAddLiquidity(ibTokenAmount, synthTokenAmount);

        address lpToken = getCurveLpToken();
        uint256 liquidity = balanceOfToken(lpToken);
        address booster = BOOSTER;
        //saving gas
        if (liquidity > 0) {
            console.log(
                "[%s] deposit to Convex,pid:%s,lp amount:%s",
                this.name(),
                _pid,
                balanceOfToken(lpToken)
            );
            IERC20Upgradeable(lpToken).safeApprove(booster, 0);
            IERC20Upgradeable(lpToken).safeApprove(booster, liquidity);
            IConvex(booster).deposit(_pid, liquidity, true);
        }
    }

    // borrow forex
    function _borrowForex(uint256 borrowAmount) internal returns (uint256 receiveAmount) {
        CTokenInterface borrowC = borrowCToken;
        //saving gas
        borrowC.borrow(borrowAmount);
        receiveAmount = balanceOfToken(borrowC.underlying());
        console.log(
            "[%s] borrow amount:%s,receive amount:%s",
            this.name(),
            borrowAmount,
            receiveAmount
        );
    }

    // repay forex
    function _repayForex(uint256 repayAmount) internal {
        CTokenInterface borrowC = borrowCToken;
        //saving gas
        address borrowToken = borrowC.underlying();
        IERC20Upgradeable(borrowToken).safeApprove(address(borrowC), 0);
        IERC20Upgradeable(borrowToken).safeApprove(address(borrowC), repayAmount);
        borrowC.repayBorrow(repayAmount);
        // console.log('repay :%s,borrowOverflow:%s,borrowBalanceCurrent:%s', repayAmount, borrowOverflow, borrowCToken.borrowBalanceCurrent(address(this)));
    }

    // increase borrow
    function increaseBorrow() public isKeeper {
        (uint256 space, ) = borrowInfo();
        if (space > 0) {
            //borrow forex
            uint256 receiveAmount = _borrowForex(space);
            _invest(receiveAmount, 0);
        }
    }

    // decrease borrow
    function decreaseBorrow() public isKeeper {
        //The number of borrowings that will be out of range after redemption
        (, uint256 overflow) = borrowInfo();
        if (overflow > 0) {
            uint256 totalStaking = balanceOfToken(rewardPool);
            uint256 currentBorrow = borrowCToken.borrowBalanceCurrent(address(this));
            uint256 cvxLpAmount = (totalStaking * overflow) / currentBorrow;
            _redeem(cvxLpAmount);
            uint256 borrowTokenBalance = balanceOfToken(borrowCToken.underlying());
            _repayForex(borrowTokenBalance);
        }
    }

    function _redeem(uint256 cvxLpAmount) internal {
        IConvexReward(rewardPool).withdraw(cvxLpAmount, false);
        IConvex(BOOSTER).withdraw(_pid, cvxLpAmount);
        //curve remove liquidity
        curveRemoveLiquidity(cvxLpAmount);
    }

    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        uint256 totalStaking = balanceOfToken(rewardPool);
        uint256 cvxLpAmount = (totalStaking * _withdrawShares) / _totalShares;
        console.log(
            "[%s] _withdrawSomeLpToken:%s, _totalShares:%s",
            this.name(),
            _withdrawShares,
            _totalShares
        );
        console.log("[%s] cvxLpAmount: %s", this.name(), cvxLpAmount);
        //saving gas
        CTokenInterface borrowC = borrowCToken;
        //saving gas
        CTokenInterface collateralC = collateralCToken;
        if (cvxLpAmount > 0) {
            _redeem(cvxLpAmount);
            // ib Token Amount
            address borrowToken = borrowC.underlying();
            uint256 borrowTokenBalance = balanceOfToken(borrowToken);
            uint256 currentBorrow = borrowC.borrowBalanceCurrent(address(this));
            uint256 repayAmount = (currentBorrow * _withdrawShares) / _totalShares;
            repayAmount = MathUpgradeable.min(repayAmount, borrowTokenBalance);
            _repayForex(repayAmount);
            uint256 burnAmount = (balanceOfToken(address(collateralC)) * repayAmount) /
                currentBorrow;
            console.log(
                "burnAmount:%s,repayAmount:%s,currentBorrow:%s",
                burnAmount,
                repayAmount,
                currentBorrow
            );
            collateralC.redeem(burnAmount);
            //The excess borrowToken is exchanged for U
            uint256 profit = balanceOfToken(borrowToken);
            if (profit > 0) {
                console.log(
                    "profit:%d,rewardRoutes[borrowToken]:%d",
                    profit,
                    rewardRoutes[borrowToken].length
                );
                IUniswapV2Router2(sushiRouterAddr).swapExactTokensForTokens(
                    profit,
                    0,
                    rewardRoutes[borrowToken],
                    address(this),
                    block.timestamp
                );
                uint256 usdcBalance = balanceOfToken(USDC);
                console.log("usdcBalance:%d", usdcBalance);
                IUniswapV2Router2(uniRouterAddr).swapExactTokensForTokens(
                    usdcBalance,
                    0,
                    rewardRoutes[USDC],
                    address(this),
                    block.timestamp
                );
            }
        }
    }

    // ==== Private ==== //

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        require(_assets[0] == address(collateralToken) && _amounts[0] > 0);
        uint256 collateralAmount = _amounts[0];
        _mintCollateralCToken(collateralAmount);
        console.log(
            "[%s] after _mintCollateralCToken = %s",
            this.name(),
            this.estimatedTotalAssets()
        );
        (uint256 space, ) = borrowInfo();
        console.log("[%s] borrow info:space = %s", this.name(), space);
        if (space > 0) {
            // borrow forex
            uint256 receiveAmount = _borrowForex(space);
            console.log("[%s] after _borrowForex = %s", this.name(), this.estimatedTotalAssets());
            _invest(receiveAmount, 0);
            console.log("[%s] after _invest = %s", this.name(), this.estimatedTotalAssets());
        }
        console.log("[%s] balanceOfToken(rewardPool):%s", this.name(), balanceOfToken(rewardPool));
    }

    // === fallback and receive === //
    fallback() external payable {}

    receive() external payable {}
}
