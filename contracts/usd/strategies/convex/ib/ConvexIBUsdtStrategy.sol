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
import "../../../../external/weth/IWeth.sol";

import "../../../../external/uniswap/IUniswapV2Router2.sol";

interface ICurveMini {
    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external payable returns (uint256);
}

contract ConvexIBUsdtStrategy is Initializable, BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event UpdateBorrowFactor(uint256 _borrowFactor);

    // IronBank
    Comptroller public constant comptroller =
        Comptroller(0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB);
    IPriceOracle public priceOracle;

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
    address public constant rewardCRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant rewardCVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // rkp3r
    address internal constant rkpr = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;

    // use Curve to sell our CVX and CRV rewards to WETH
    address internal constant crvethPool = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511; // use curve's new CRV-ETH crypto pool to sell our CRV
    address internal constant cvxethPool = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4; // use curve's new CVX-ETH crypto pool to sell our CVX

    //sushi router
    address internal constant sushiRouterAddr = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    //uni router
    address internal constant uniRouterAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    //uni v3
    address internal constant uniswapv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    //reward swap path
    mapping(address => address[]) public rewardRoutes;

    address public curve_usdc_ibforex_pool;

    function setBorrowFactor(uint256 _borrowFactor) external isVaultManager {
        require(_borrowFactor >= 0 && _borrowFactor < BPS, "setting output the range");
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
        _pid = IConvexReward(rewardPool).pid();
        curve_usdc_ibforex_pool = _curve_usdc_ibforex_pool;
        address[] memory _wants = new address[](1);
        _wants[0] = collateralToken;

        priceOracle = IPriceOracle(comptroller.oracle());

        _initialize(_vault, _harvester, _strategyName, uint16(ProtocolEnum.Convex), _wants);

        borrowFactor = 8300;

        uint256 uintMax = type(uint256).max;
        // approve sell rewards
        IERC20Upgradeable(rewardCRV).safeApprove(address(crvethPool), uintMax);
        IERC20Upgradeable(rewardCVX).safeApprove(address(cvxethPool), uintMax);

        // approve deposit
        address curveForexPool = getCurveLpToken();
        address borrowToken = borrowCToken.underlying();
        IERC20Upgradeable(borrowToken).safeApprove(curveForexPool, uintMax);

        IERC20Upgradeable(borrowToken).safeApprove(sushiRouterAddr, uintMax);
        IERC20Upgradeable(USDC).safeApprove(uniRouterAddr, uintMax);
        IERC20Upgradeable(WETH).safeApprove(sushiRouterAddr, uintMax);

        //init reward swap path
        address[] memory ib2usdc = new address[](2);
        ib2usdc[0] = borrowToken;
        ib2usdc[1] = USDC;
        rewardRoutes[borrowToken] = ib2usdc;
        address[] memory weth2usdc = new address[](2);
        weth2usdc[0] = WETH;
        weth2usdc[1] = USDC;
        rewardRoutes[WETH] = weth2usdc;
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
        uint256 assetsValue = assets();
        uint256 debtsValue = debts();
        // The usdValue needs to be filled with precision
        usdValue = assetsValue - debtsValue;
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

    //assets(USD) -18
    function assets() public view returns (uint256 value) {
        // estimatedDepositedAssets
        uint256 deposited = curvePoolAssets();
        value += deposited;
        // CToken value
        value += collateralAssets();
        address _collateralToken = collateralToken;
        // balance
        uint256 underlyingBalance = balanceOfToken(_collateralToken);
        if (underlyingBalance > 0) {
            value +=
                ((underlyingBalance * _collateralTokenPrice()) /
                    decimalUnitOfToken(_collateralToken)) /
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
    }

    function getCurveLpToken() public view returns (address) {
        return IConvex(BOOSTER).poolInfo(_pid).lptoken;
    }

    function getIronBankForex() public view returns (address) {
        ICurveFi curveForexPool = ICurveFi(getCurveLpToken());
        return curveForexPool.coins(0);
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
        IConvexReward(rewardPool).getReward();
        uint256 crvBalance = balanceOfToken(rewardCRV);
        uint256 cvxBalance = balanceOfToken(rewardCVX);
        console.log("[%s] claim reward:%s,%s", this.name(), crvBalance, cvxBalance);
        _sellCrvAndCvx(crvBalance, cvxBalance);
        uint256 ibForexAmount = balanceOfToken(getIronBankForex());
        if (ibForexAmount > 0) {
            console.log("harvest ibForexAmount:", ibForexAmount);
            _invest(ibForexAmount);
        }
        //sell kpr
        uint256 rkprBalance = balanceOfToken(rkpr);
        if (rkprBalance > 0) {
            IERC20Upgradeable(rkpr).transfer(harvester, rkprBalance);
        }
        _rewardsTokens = new address[](3);
        _rewardsTokens[0] = rewardCRV;
        _rewardsTokens[1] = rewardCVX;
        _rewardsTokens[2] = rkpr;
        _claimAmounts = new uint256[](3);
        _claimAmounts[0] = crvBalance;
        _claimAmounts[1] = cvxBalance;
        _claimAmounts[2] = rkprBalance;
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

        if (address(this).balance > 0) {
            //ETH wrap to WETH
            IWeth(WETH).deposit{value: address(this).balance}();
            console.log("[%s] WETH:%s", this.name(), balanceOfToken(WETH));

            //crv swap to USDC
            IUniswapV2Router2(sushiRouterAddr).swapExactTokensForTokens(
                balanceOfToken(WETH),
                0,
                rewardRoutes[WETH],
                address(this),
                block.timestamp
            );
            uint256 usdcBalance = balanceOfToken(USDC);
            console.log("[%s] USDC:%s", this.name(), usdcBalance);
            IERC20Upgradeable(USDC).safeApprove(curve_usdc_ibforex_pool, 0);
            IERC20Upgradeable(USDC).safeApprove(curve_usdc_ibforex_pool, usdcBalance);
            ICurveMini(curve_usdc_ibforex_pool).exchange(1, 0, usdcBalance, 0);
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
    function curveAddLiquidity(uint256 ibTokenAmount) internal {
        ICurveFi(getCurveLpToken()).add_liquidity([ibTokenAmount, 0], 0);
    }

    // curve remove liquidity
    function curveRemoveLiquidity(uint256 shareAmount) internal {
        ICurveFi(getCurveLpToken()).remove_liquidity_one_coin(shareAmount, 0, 0);
    }

    function _invest(uint256 ibTokenAmount) internal {
        curveAddLiquidity(ibTokenAmount);

        address lpToken = getCurveLpToken();
        uint256 liquidity = balanceOfToken(lpToken);
        address booster = BOOSTER;
        //saving gas
        if (liquidity > 0) {
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
    }

    // repay forex
    function _repayForex(uint256 repayAmount) internal {
        CTokenInterface borrowC = borrowCToken;
        //saving gas
        address borrowToken = borrowC.underlying();
        IERC20Upgradeable(borrowToken).safeApprove(address(borrowC), 0);
        IERC20Upgradeable(borrowToken).safeApprove(address(borrowC), repayAmount);
        borrowC.repayBorrow(repayAmount);
    }

    // increase borrow
    function increaseBorrow() public isKeeper {
        (uint256 space, ) = borrowInfo();
        if (space > 0) {
            //borrow forex
            uint256 receiveAmount = _borrowForex(space);
            _invest(receiveAmount);
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

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        require(_assets[0] == address(collateralToken) && _amounts[0] > 0);
        uint256 collateralAmount = _amounts[0];
        _mintCollateralCToken(collateralAmount);
        (uint256 space, ) = borrowInfo();
        console.log("[%s] borrow info:space = %s", this.name(), space);
        if (space > 0) {
            // borrow forex
            uint256 receiveAmount = _borrowForex(space);
            _invest(receiveAmount);
        }
    }

    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        // if withdraw all,force claim reward.
        if (_withdrawShares == _totalShares) {
            harvest();
        }
        uint256 totalStaking = balanceOfToken(rewardPool);
        uint256 cvxLpAmount = (totalStaking * _withdrawShares) / _totalShares;
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
            collateralC.redeem(burnAmount);
            //The excess borrowToken is exchanged for U
            uint256 profit = balanceOfToken(borrowToken);
            if (profit > 0) {
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

    // === fallback and receive === //
    fallback() external payable {}

    receive() external payable {}
}
