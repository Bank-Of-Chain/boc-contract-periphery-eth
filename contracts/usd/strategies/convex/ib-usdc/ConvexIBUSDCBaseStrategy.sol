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

import "../../../../external/uniswap/IUniswapV2Router2.sol";
import "../../../../external/weth/IWeth.sol";

interface ICurveMini {
    function balances(uint256) external view returns (uint256);

    function coins(uint256) external view returns (address);

    function get_dy(
        uint256 from,
        uint256 to,
        uint256 _from_amount
    ) external view returns (uint256);

    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external payable returns (uint256);

    // CRV-ETH and CVX-ETH
    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth
    ) external;

    function calc_withdraw_one_coin(uint256 amount, uint256 i) external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;
}

abstract contract ConvexIBUSDCBaseStrategy is Initializable, BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event UpdateBorrowFactor(uint256 _borrowFactor);
    event UpdateMaxCollateralRate(uint256 _maxCollateralRate);
    event UpdateUnderlyingPartRatio(uint256 _underlyingPartRatio);
    event UpdateForexReduceStep(uint256 _forexReduceStep);

    // minimum amount to be liquidation
    uint256 public constant SELL_FLOOR = 1e16;

    // IronBank
    Comptroller public constant comptroller =
        Comptroller(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    IPriceOracle public constant priceOracle =
        IPriceOracle(0x6B96c414ce762578c3E7930da9114CffC88704Cb);

    // borrow factor
    uint256 public borrowFactor;
    // max collateral rate
    uint256 public maxCollateralRate;
    // USDC Part Ratio
    uint256 public underlyingPartRatio;
    // Percentage of single reduction in foreign exchange holdings
    uint256 public forexReduceStep;

    uint256 public constant BPS = 10000;
    address public constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
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

    //sushi router
    address internal constant sushiRouterAddr =
        address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    //uni router
    // address internal constant uniRouterAddr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    //reward swap path
    mapping(address => address[]) public rewardRoutes;

    function setBorrowFactor(uint256 _borrowFactor) external isVaultManager {
        require(_borrowFactor >= 0 && _borrowFactor < BPS, "setting output the range");
        borrowFactor = _borrowFactor;

        emit UpdateBorrowFactor(_borrowFactor);
    }

    function setMaxCollateralRate(uint256 _maxCollateralRate) external isVaultManager {
        require(_maxCollateralRate > 0 && _maxCollateralRate < BPS, "setting output the range");
        maxCollateralRate = _maxCollateralRate;

        emit UpdateMaxCollateralRate(_maxCollateralRate);
    }

    function setUnderlyingPartRatio(uint256 _underlyingPartRatio) external isVaultManager {
        require(
            _underlyingPartRatio > 0 && _underlyingPartRatio < BPS,
            "setting output the range"
        );
        underlyingPartRatio = _underlyingPartRatio;

        emit UpdateUnderlyingPartRatio(_underlyingPartRatio);
    }

    function setForexReduceStep(uint256 _forexReduceStep) external isVaultManager {
        require(_forexReduceStep > 0 && _forexReduceStep <= BPS, "setting output the range");
        forexReduceStep = _forexReduceStep;

        emit UpdateForexReduceStep(_forexReduceStep);
    }

    function _initialize(address _vault, address _harvester) internal {
        address collateralToken = getCollateralToken();
        address[] memory _wants = new address[](1);
        _wants[0] = collateralToken;

        _initialize(_vault, _harvester, uint16(ProtocolEnum.Convex), _wants);

        borrowFactor = 8300;
        maxCollateralRate = 7500;
        underlyingPartRatio = 4000;
        forexReduceStep = 500;

        uint256 uintMax = type(uint256).max;
        // approve sell rewards
        IERC20Upgradeable(rewardCRV).safeApprove(address(crvethPool), uintMax);
        IERC20Upgradeable(rewardCVX).safeApprove(address(cvxethPool), uintMax);

        // approve deposit
        address borrowToken = getIronBankForex();
        address curvePool = getCurvePool();
        IERC20Upgradeable(borrowToken).safeApprove(curvePool, uintMax);
        IERC20Upgradeable(collateralToken).safeApprove(curvePool, uintMax);

        IERC20Upgradeable(borrowToken).safeApprove(sushiRouterAddr, uintMax);
        IERC20Upgradeable(WETH).safeApprove(sushiRouterAddr, uintMax);
        // IERC20Upgradeable(USDC).safeApprove(uniRouterAddr, uintMax);

        //init reward swap path
        address[] memory ib2usdc = new address[](2);
        ib2usdc[0] = borrowToken;
        ib2usdc[1] = USDC;
        rewardRoutes[borrowToken] = ib2usdc;

        address[] memory weth2usdc = new address[](2);
        ib2usdc[0] = WETH;
        ib2usdc[1] = USDC;
        rewardRoutes[WETH] = ib2usdc;

        isWantRatioIgnorable = true;
    }

    function getCollateralCToken() public pure virtual returns (CTokenInterface);

    function getCollateralToken() public pure virtual returns (address);

    function getBorrowCToken() public pure virtual returns (CTokenInterface);

    function getCurvePool() public pure virtual returns (address);

    function getRewardPool() public pure virtual returns (address);

    function getPId() public pure virtual returns (uint256);

    // ==== External === //
    // USD-1e18
    function get3rdPoolAssets() public view override returns (uint256 targetPoolTotalAssets) {
        address curvePool = getCurvePool();
        uint256 forexValue = (ICurveMini(curvePool).balances(0) * _borrowTokenPrice()) /
            decimalUnitOfToken(getIronBankForex());
        uint256 underlyingValue = (ICurveMini(curvePool).balances(1) * _collateralTokenPrice()) /
            decimalUnitOfToken(getCollateralToken());

        targetPoolTotalAssets = (forexValue + underlyingValue) / 1e12; //div 1e12 for normalized
    }

    // ==== Public ==== //

    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = new address[](1);
        _assets[0] = wants[0];

        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
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
        uint256 assetsValue = assets();
        uint256 debtsValue = debts();
        (uint256 positive, uint256 negative) = assetDelta();
        //Net Assets
        usdValue = assetsValue - debtsValue + positive - negative;
        console.log("positive:%s,negative:%s", positive, negative);
        console.log("PositionDetail: %s,assets:%s,debts:%s", usdValue, assetsValue, debtsValue);
    }

    /**
     *   curve Pool Assets，USD-1e18
     */
    function curvePoolAssets() public view returns (uint256 depositedAssets) {
        uint256 rewardBalance = balanceOfToken(getRewardPool());
        uint256 totalLp = IERC20Upgradeable(getCurveLpToken()).totalSupply();
        if (rewardBalance > 0) {
            depositedAssets = (rewardBalance * get3rdPoolAssets()) / totalLp;
        } else {
            depositedAssets = 0;
        }
    }

    /**
     *  debt Rate
     */
    function debtRate() public view returns (uint256) {
        //collateral Assets
        uint256 collateral = collateralAssets();
        //debts
        uint256 debt = debts();
        if (collateral == 0) {
            return 0;
        }
        return (debt * BPS) / collateral;
    }

    //collateral rate
    function collateralRate() public view returns (uint256) {
        //net Assets
        (, , , uint256 netAssets) = getPositionDetail();
        if (netAssets == 0) {
            return 0;
        }
        //collateral assets
        uint256 collateral = collateralAssets();
        return (collateral * BPS) / netAssets;
    }

    function assetDelta() public view returns (uint256 positive, uint256 negative) {
        uint256 rewardBalance = balanceOfToken(getRewardPool());
        if (rewardBalance == 0) {
            return (0, 0);
        }
        CTokenInterface borrowCToken = getBorrowCToken();
        address curvePool = getCurvePool();
        address collateralToken = getCollateralToken();
        uint256 totalLp = IERC20Upgradeable(getCurveLpToken()).totalSupply();
        uint256 forexHoldOn = (ICurveMini(curvePool).balances(0) * rewardBalance) / totalLp;
        uint256 forexDebts = borrowCToken.borrowBalanceStored(address(this));
        if (forexHoldOn > forexDebts) {
            //need swap forex to underlying
            uint256 addUnderlying = ICurveMini(curvePool).get_dy(0, 1, forexHoldOn - forexDebts);
            uint256 forexValue = ((forexHoldOn - forexDebts) * _borrowTokenPrice()) /
                decimalUnitOfToken(borrowCToken.underlying());
            uint256 addUnderlyingValue = (addUnderlying * _collateralTokenPrice()) /
                decimalUnitOfToken(collateralToken);

            if (forexValue > addUnderlyingValue) {
                negative = (forexValue - addUnderlyingValue) / 1e12;
            } else {
                positive = (addUnderlyingValue - forexValue) / 1e12;
            }
        } else {
            //need swap underlying to forex
            uint256 needUnderlying = ICurveMini(curvePool).get_dy(0, 1, forexDebts - forexHoldOn);
            uint256 forexValue = ((forexDebts - forexHoldOn) * _borrowTokenPrice()) /
                decimalUnitOfToken(getIronBankForex());
            uint256 needUnderlyingValue = (needUnderlying * _collateralTokenPrice()) /
                decimalUnitOfToken(collateralToken);
            if (forexValue > needUnderlyingValue) {
                positive = (forexValue - needUnderlyingValue) / 1e12;
            } else {
                negative = (needUnderlyingValue - forexValue) / 1e12;
            }
        }
    }

    //assets(USD)
    function assets() public view returns (uint256 value) {
        // estimatedDepositedAssets
        uint256 deposited = curvePoolAssets();
        value += deposited;
        // CToken value
        value += collateralAssets();
        address collateralToken = getCollateralToken();
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
        CTokenInterface _borrowCToken = getBorrowCToken();
        //for saving gas
        uint256 borrowBalanceCurrent = _borrowCToken.borrowBalanceStored(address(this));
        address borrowToken = _borrowCToken.underlying();
        uint256 borrowTokenPrice = _borrowTokenPrice();
        value = (borrowBalanceCurrent * borrowTokenPrice) / decimalUnitOfToken(borrowToken) / 1e12; //div 1e12 for normalized
        console.log("debts:%s", value);
    }

    //collateral assets（USD-1e18)
    function collateralAssets() public view returns (uint256 value) {
        CTokenInterface collateralC = getCollateralCToken();
        address collateralToken = getCollateralToken();
        //saving gas
        uint256 exchangeRateMantissa = collateralC.exchangeRateStored();
        uint256 collateralTokenAmount = ((balanceOfToken(address(collateralC)) *
            exchangeRateMantissa) * decimalUnitOfToken(collateralToken)) /
            1e16 /
            decimalUnitOfToken(address(collateralC));
        uint256 collateralTokenPrice = _collateralTokenPrice();
        value =
            (collateralTokenAmount * collateralTokenPrice) /
            decimalUnitOfToken(collateralToken) /
            1e12; //div 1e12 for normalized
    }

    // borrow Info
    function borrowInfo() public view returns (uint256 space, uint256 overflow) {
        uint256 borrowAvaible = _currentBorrowAvaible();
        uint256 currentBorrow = getBorrowCToken().borrowBalanceStored(address(this));
        if (borrowAvaible > currentBorrow) {
            space = borrowAvaible - currentBorrow;
        } else {
            overflow = currentBorrow - borrowAvaible;
        }
        console.log("borrowInfo space:%s,overflow:%s ", space, overflow);
    }

    function getCurveLpToken() public view returns (address) {
        return IConvex(BOOSTER).poolInfo(getPId()).lptoken;
    }

    function getIronBankForex() public view returns (address) {
        ICurveMini curveForexPool = ICurveMini(getCurvePool());
        return curveForexPool.coins(0);
    }

    /**
     *  Sell reward and reinvestment logic
     */
    function harvest()
        external
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        _claimAndInvest();
        vault.report(_rewardsTokens, _claimAmounts);
    }

    function _claimAndInvest() internal {
        address rewardPool = getRewardPool();
        uint256 rewardCRVAmount = IConvexReward(rewardPool).earned(address(this));
        if (rewardCRVAmount > SELL_FLOOR) {
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
            //reinvest
            _invest(0, balanceOfToken(getCollateralToken()));
        }
    }

    /**
     *  sell Crv And Cvx
     */
    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _convexAmount) internal {
        if (_crvAmount > 0) {
            ICurveMini(crvethPool).exchange(1, 0, _crvAmount, 0, true);
        }
        if (_convexAmount > 0) {
            ICurveMini(cvxethPool).exchange(1, 0, _convexAmount, 0, true);
        }

        //ETH wrap to WETH
        IWeth(WETH).deposit{value: address(this).balance}();

        //crv swap to USDC
        IUniswapV2Router2(sushiRouterAddr).swapExactTokensForTokens(
            balanceOfToken(WETH),
            0,
            rewardRoutes[WETH],
            address(this),
            block.timestamp
        );
        // console.log(
        //     "[%s] after sell reward USDC balance:%s",
        //     this.name(),
        //     balanceOfToken(collateralToken)
        // );
    }

    // Collateral Token Price In USD ,decimals 1e30
    function _collateralTokenPrice() internal view returns (uint256) {
        uint256 collateralTokenPrice = priceOracle.getUnderlyingPrice(
            address(getCollateralCToken())
        );
        console.log("[%s] collateralTokenPrice", this.name(), collateralTokenPrice);
        return collateralTokenPrice;
    }

    // Borrown Token Price In USD ，decimals 1e30
    function _borrowTokenPrice() internal view returns (uint256) {
        uint256 borrowTokenPrice = _getNormalizedBorrowToken();
        console.log("[%s] borrowTokenPrice", this.name(), borrowTokenPrice);
        require(borrowTokenPrice > 0);
        return borrowTokenPrice;
    }

    function _getNormalizedBorrowToken() internal view returns (uint256) {
        return priceOracle.getUnderlyingPrice(address(getBorrowCToken())) * 1e12;
    }

    // Maximum number of borrowings under the specified amount of collateral assets
    function _borrowAvaiable(uint256 liqudity) internal view returns (uint256 borrowAvaible) {
        address borrowToken = getIronBankForex();
        // uint256 maxBorrrowAmount = calcCanonicalAssetValue(collateralToken, collateralValue, borrowToken);
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
        (, uint256 rate) = comptroller.markets(address(getCollateralCToken()));
        uint256 liquidity = (collateralAssets() * 1e12 * rate) / 1e18; //multi 1e12 for liquidity convert to 1e30
        borrowAvaible = _borrowAvaiable(liquidity);
    }

    // Add collateral to IronBank
    function _mintCollateralCToken(uint256 mintAmount) internal {
        address collateralC = address(getCollateralCToken());
        //saving gas
        // mint Collateral
        address collateralToken = getCollateralToken();
        IERC20Upgradeable(collateralToken).safeApprove(collateralC, 0);
        IERC20Upgradeable(collateralToken).safeApprove(collateralC, mintAmount);
        CTokenInterface(collateralC).mint(mintAmount);
        // enter market
        address[] memory markets = new address[](1);
        markets[0] = collateralC;
        comptroller.enterMarkets(markets);
    }

    function _distributeUnderlying(uint256 underlyingTokenAmount)
        internal
        view
        virtual
        returns (uint256 underlyingPart, uint256 forexPart)
    {
        //----by fixed ratio
        underlyingPart = (underlyingPartRatio * underlyingTokenAmount) / BPS;
        forexPart = underlyingTokenAmount - underlyingPart;
        console.log("underlyingPart:%s,forexPart:%s", underlyingPart, forexPart);
        //----by token amount ratio
        // ICurveMini curvePool = ICurveMini(curvePool);
        // uint256 forexPooledAmount = curvePool.balances(0);
        // uint256 underlyingPooledAmount = curvePool.balances(1) * 1e12; //multi 1e12 for normalized decimals
        // console.log("curve ratio forex:%s,usdc:%s", forexPooledAmount, underlyingPooledAmount);

        // (, uint256 rate) = comptroller.markets(address(collateralCToken));
        // uint256 rebate = (1e18 * _collateralTokenPrice() * rate * borrowFactor) /
        //     BPS /
        //     1e18 /
        //     _borrowTokenPrice();
        // underlyingPart =
        //     ((underlyingTokenAmount * underlyingPooledAmount)) /
        //     ((forexPooledAmount * rebate) / 1e18 + underlyingPooledAmount);
        // forexPart = underlyingTokenAmount - underlyingPart;

        // console.log("rebate:%s,underlyingPart:%s,forexPart:%s", rebate, underlyingPart, forexPart);

        //----by token value ratio
        // ICurveMini curvePool = ICurveMini(curvePool);
        // uint256 forexPooledValue = (curvePool.balances(0) * _borrowTokenPrice()) /
        //     decimalUnitOfToken(borrowCToken.underlying());
        // uint256 underlyingPooledValue = (curvePool.balances(1) * _collateralTokenPrice()) /
        //     decimalUnitOfToken(collateralToken);
        // console.log("curve ratio forex:%s,usdc:%s", forexPooledValue, underlyingPooledValue);

        // (, uint256 rate) = comptroller.markets(address(collateralCToken));
        // uint256 rebate = (1e18 * _collateralTokenPrice() * rate * borrowFactor) /
        //     BPS /
        //     1e18 /
        //     _borrowTokenPrice();
        // underlyingPart =
        //     ((underlyingTokenAmount * underlyingPooledValue)) /
        //     ((forexPooledValue * rebate) / 1e18 + underlyingPooledValue);
        // forexPart = underlyingTokenAmount - underlyingPart;
    }

    function _invest(uint256 ibTokenAmount, uint256 underlyingTokenAmount) internal {
        ICurveMini(getCurvePool()).add_liquidity([ibTokenAmount, underlyingTokenAmount], 0);

        address lpToken = getCurveLpToken();
        uint256 liquidity = balanceOfToken(lpToken);
        console.log("receive liquidity:%s", liquidity);
        address booster = BOOSTER;
        //saving gas
        if (liquidity > 0) {
            IERC20Upgradeable(lpToken).safeApprove(booster, 0);
            IERC20Upgradeable(lpToken).safeApprove(booster, liquidity);
            IConvex(booster).deposit(getPId(), liquidity, true);
        }
    }

    // borrow Forex
    function _borrowForex(uint256 borrowAmount) internal returns (uint256 receiveAmount) {
        CTokenInterface borrowC = getBorrowCToken();
        //saving gas
        borrowC.borrow(borrowAmount);
        receiveAmount = balanceOfToken(borrowC.underlying());
    }

    // repay Forex
    function _repayForex(uint256 repayAmount) internal {
        CTokenInterface borrowC = getBorrowCToken();
        //saving gas
        address borrowToken = borrowC.underlying();
        IERC20Upgradeable(borrowToken).safeApprove(address(borrowC), 0);
        IERC20Upgradeable(borrowToken).safeApprove(address(borrowC), repayAmount);
        borrowC.repayBorrow(repayAmount);
        // console.log('repay :%s,borrowOverflow:%s,borrowBalanceCurrent:%s', repayAmount, borrowOverflow, borrowCToken.borrowBalanceCurrent(address(this)));
    }

    // exit collateral ,invest to curve pool directly
    function exitCollateralInvestToCurvePool(uint256 space) internal {
        //Calculate how much collateral can be drawn
        uint256 borrowTokenDecimals = decimalUnitOfToken(getIronBankForex());
        // space value in usd(1e30)
        uint256 spaceValue = (space * _borrowTokenPrice()) / borrowTokenDecimals;
        address collaterCTokenAddr = address(getCollateralCToken());
        (, uint256 rate) = comptroller.markets(collaterCTokenAddr);
        uint256 totalLp = balanceOfToken(getRewardPool());
        address collateralToken = getCollateralToken();
        //exit add collateral
        uint256 exitCollateral = (((spaceValue * 1e18) / rate) *
            decimalUnitOfToken(collateralToken)) / _collateralTokenPrice();
        uint256 exchangeRateMantissa = CTokenInterface(collaterCTokenAddr).exchangeRateStored();
        uint256 exitCollateralC = (exitCollateral *
            1e16 *
            decimalUnitOfToken(collaterCTokenAddr)) /
            exchangeRateMantissa /
            decimalUnitOfToken(collateralToken);
        console.log("exitCollateralC:%s", exitCollateralC);
        CTokenInterface(collaterCTokenAddr).redeem(
            MathUpgradeable.min(exitCollateralC, balanceOfToken(collaterCTokenAddr))
        );
        uint256 balanceOfCollateral = balanceOfToken(collateralToken);
        console.log("exitCollateral:%s,actual receive:%s", exitCollateral, balanceOfCollateral);
        _invest(0, balanceOfCollateral);
    }

    // increase Collateral
    function increaseCollateral(uint256 overflow) internal {
        uint256 borrowTokenDecimals = decimalUnitOfToken(getIronBankForex());
        // overflow value in usd(1e30)
        uint256 overflowValue = (overflow * _borrowTokenPrice()) / borrowTokenDecimals;
        (, uint256 rate) = comptroller.markets(address(getCollateralCToken()));
        uint256 totalLp = balanceOfToken(getRewardPool());
        //need add collateral
        address collateralToken = getCollateralToken();
        uint256 needCollateral = (((overflowValue * 1e18) / rate) *
            decimalUnitOfToken(collateralToken)) / _collateralTokenPrice();
        address curvePool = getCurvePool();
        uint256 allUnderlying = ICurveMini(curvePool).calc_withdraw_one_coin(totalLp, 1);
        uint256 removeLp = (totalLp * needCollateral) / allUnderlying;
        IConvexReward(getRewardPool()).withdraw(removeLp, false);
        IConvex(BOOSTER).withdraw(getPId(), removeLp);
        ICurveMini(curvePool).remove_liquidity_one_coin(removeLp, 1, 0);
        uint256 underlyingBalance = balanceOfToken(collateralToken);
        console.log("add collateral:", underlyingBalance);
        // add collateral
        _mintCollateralCToken(underlyingBalance);
    }

    function rebalance() external isKeeper {
        (uint256 space, uint256 overflow) = borrowInfo();

        // //========temp code========
        // uint256 borrowAvaible = _currentBorrowAvaible();
        // uint256 currentBorrow = borrowCToken.borrowBalanceStored(address(this));
        // overflow = currentBorrow / 2;
        // //========temp code========
        console.log("rebalance space:%s,overflow:%s", space, overflow);
        if (space > 0) {
            exitCollateralInvestToCurvePool(space);
        } else if (overflow > 0) {
            //If collateral already exceeds the limit as a percentage of total assets, it is necessary to start reducing foreign exchange debt
            if (collateralRate() < maxCollateralRate) {
                increaseCollateral(overflow);
            } else {
                address rewardPool = getRewardPool();
                uint256 totalLp = balanceOfToken(rewardPool);
                uint256 removeLp = (totalLp * forexReduceStep) / BPS;
                IConvexReward(rewardPool).withdraw(removeLp, false);
                IConvex(BOOSTER).withdraw(getPId(), removeLp);
                ICurveMini(getCurvePool()).remove_liquidity_one_coin(removeLp, 0, 0);
                uint256 exitForex = balanceOfToken(getIronBankForex());
                if (exitForex > 0) {
                    _repayForex(exitForex);
                    console.log("exitForex:", exitForex);
                }
            }
        }
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        require(_assets[0] == getCollateralToken() && _amounts[0] > 0);
        uint256 underlyingAmount = _amounts[0];
        (uint256 underlyingPart, uint256 forexPart) = _distributeUnderlying(underlyingAmount);
        _mintCollateralCToken(forexPart);
        (uint256 space, ) = borrowInfo();
        if (space > 0) {
            //borrow forex
            uint256 receiveAmount = _borrowForex(space);
            _invest(receiveAmount, underlyingPart);
        }
    }

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares) internal override {
        // claim when withdraw all.
        if (_withdrawShares == _totalShares) _claimAndInvest();
        uint256 totalStaking = balanceOfToken(getRewardPool());
        uint256 cvxLpAmount = (totalStaking * _withdrawShares) / _totalShares;
        console.log("[%s] cvxLpAmount: %s", this.name(), cvxLpAmount);
        //saving gas
        CTokenInterface borrowC = getBorrowCToken();
        //saving gas
        CTokenInterface collateralC = getCollateralCToken();
        if (cvxLpAmount > 0) {
            _redeem(cvxLpAmount);
            // ib Token Amount
            address borrowToken = borrowC.underlying();
            uint256 borrowTokenBalance = balanceOfToken(borrowToken);
            uint256 currentBorrow = borrowC.borrowBalanceCurrent(address(this));
            uint256 repayAmount = (currentBorrow * _withdrawShares) / _totalShares;
            // repayAmount = MathUpgradeable.min(repayAmount, borrowTokenBalance);
            console.log("Current Debts:%s", currentBorrow);
            address curvePool = getCurvePool();
            //资不抵债时，将USDC换成债务token
            if (borrowTokenBalance < repayAmount) {
                uint256 underlyingBalance = balanceOfToken(getCollateralToken());
                uint256 reserve = ICurveMini(curvePool).get_dy(1, 0, underlyingBalance);
                uint256 forSwap = (underlyingBalance * (repayAmount - borrowTokenBalance)) /
                    reserve;
                uint256 swapUse = MathUpgradeable.min(forSwap, underlyingBalance);
                console.log("swapUse:%s,underlying:%s", swapUse, underlyingBalance);
                uint256 extra = ICurveMini(curvePool).exchange(1, 0, swapUse, 0);
                console.log("exchange extra:", extra);
            }
            repayAmount = MathUpgradeable.min(repayAmount, balanceOfToken(borrowToken));
            _repayForex(repayAmount);
            uint256 burnAmount = (balanceOfToken(address(collateralC)) * repayAmount) /
                currentBorrow;
            collateralC.redeem(burnAmount);
            //The excess borrowToken is exchanged for U
            uint256 profit = balanceOfToken(borrowToken);
            if (profit > 0) {
                ICurveMini(curvePool).exchange(0, 1, profit, 0);
            }
        }
    }

    function _redeem(uint256 cvxLpAmount) internal {
        IConvexReward(getRewardPool()).withdraw(cvxLpAmount, false);
        IConvex(BOOSTER).withdraw(getPId(), cvxLpAmount);
        //remove liquidity
        ICurveMini(getCurvePool()).remove_liquidity(cvxLpAmount, [uint256(0), uint256(0)]);
    }

    // === fallback and receive === //
    fallback() external payable {}

    receive() external payable {}
}
