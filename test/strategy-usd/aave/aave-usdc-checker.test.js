const checker = require('../strategy-checker');
const {default: BigNumber} = require("bignumber.js");
const topUp = require('../../../utils/top-up-utils');
const MFC = require('../../../config/mainnet-fork-test-config');
const {ethers} = require("hardhat");
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const ILendingPool = hre.artifacts.require('ILendingPool');
const AaveWETHstETHStrategy = hre.artifacts.require('AaveWETHstETHStrategy');
const ILendingPoolAddressesProvider = hre.artifacts.require('ILendingPoolAddressesProvider');
const MockAavePriceOracleConsumer = hre.artifacts.require('MockAavePriceOracleConsumer');

describe('【AaveUSDCStrategy Strategy Checker】', function() {
    checker.check('AaveUSDCStrategy',async function (strategyAddress) {
        const aTokenContract = await ERC20.at('0x1982b2F5814301d4e9a8b0201555376e62F82428');
        const astETHAmount = new BigNumber(await aTokenContract.balanceOf(strategyAddress));
        const lidoApr = 531; //x/10000
        const growDay = 8;
        const increaseAstEthAmount = new BigNumber(astETHAmount.multipliedBy(growDay).multipliedBy(lidoApr).dividedBy(365).dividedBy(10000).toFixed(0,2));
        const accounts = await ethers.getSigners();
        const keeper = accounts[19].address;
        await topUp.topUpSTETHByAddress(increaseAstEthAmount,keeper);

        const _lendingPoolAddress = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
        const _aaveLendingPool =  await ILendingPool.at(_lendingPoolAddress);

        const tokenContract = await ERC20.at(MFC.stETH_ADDRESS);
        await tokenContract.approve(_lendingPoolAddress, increaseAstEthAmount,{from:keeper});
        await _aaveLendingPool.deposit(MFC.stETH_ADDRESS, increaseAstEthAmount.toFixed(), keeper, 0,{from: keeper});

        const receivedAstETHAmount = await aTokenContract.balanceOf(keeper);
        console.log("harvest astETH:",receivedAstETHAmount.toString());

        await aTokenContract.transfer(strategyAddress,receivedAstETHAmount.toString(),{from:keeper});
    },async function (strategyAddress,customAddressArray) {

        const mockPriceOracleAddress = customAddressArray[0];
        const mockPriceOracle = await MockAavePriceOracleConsumer.at(mockPriceOracleAddress);

        //set
        const addressProvider = await ILendingPoolAddressesProvider.at('0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5');
        const addressPrividerOwner = '0xEE56e2B3D491590B5b31738cC34d5232F378a8D5';
        await topUp.impersonates([addressPrividerOwner]);
        await topUp.topUpEthByAddress(new BigNumber(10).pow(18).multipliedBy(10),addressPrividerOwner);
        await addressProvider.setPriceOracle(mockPriceOracleAddress,{from:addressPrividerOwner});
        let stETHPrice = new BigNumber((await mockPriceOracle.getAssetPrice(MFC.stETH_ADDRESS)).toString());
        let usdcPrice = new BigNumber((await mockPriceOracle.getAssetPrice(MFC.USDC_ADDRESS)).toString());
        console.log('stETH price1:%s',stETHPrice.toFixed(0,2));
        console.log('USDC price1:%s',usdcPrice.toFixed(0,2));
        const lendingPoolAddress = await addressProvider.getLendingPool();
        const lendingPool  = await ILendingPool.at(lendingPoolAddress);

        let userAccountData = await lendingPool.getUserAccountData(strategyAddress);
        console.log(userAccountData.totalCollateralETH.toString(),
            userAccountData.totalDebtETH.toString(),
            userAccountData.availableBorrowsETH.toString(),
            userAccountData.currentLiquidationThreshold.toString(),
            userAccountData.ltv.toString(),
            userAccountData.healthFactor.toString());
        // await mockPriceOracle.setAssetPrice(MFC.stETH_ADDRESS,ethPrice.multipliedBy(110).dividedBy(100).toFixed(0,2));
        await mockPriceOracle.setAssetPrice(MFC.DAI_ADDRESS,usdcPrice.multipliedBy(50).dividedBy(100).toFixed(0,2));
        console.log('stETH price2:%s',await mockPriceOracle.getAssetPrice(MFC.stETH_ADDRESS));
        console.log('USDC price2:%s',await mockPriceOracle.getAssetPrice(MFC.USDC_ADDRESS));
        userAccountData = await lendingPool.getUserAccountData(strategyAddress);
        console.log(userAccountData.totalCollateralETH.toString(),
            userAccountData.totalDebtETH.toString(),
            userAccountData.availableBorrowsETH.toString(),
            userAccountData.currentLiquidationThreshold.toString(),
            userAccountData.ltv.toString(),
            userAccountData.healthFactor.toString());

        // const aTokenContract = await ERC20.at('0x1982b2F5814301d4e9a8b0201555376e62F82428');
        const strategy = await AaveWETHstETHStrategy.at(strategyAddress);
        const accounts = await ethers.getSigners();
        const keeper = accounts[19].address;

        let borrowInfo = await strategy.borrowInfo({from:keeper});
        console.log("before rebalance1 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
        await strategy.rebalance({from:keeper});
        borrowInfo = await strategy.borrowInfo({from:keeper});
        console.log("after rebalance1 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
        userAccountData = await lendingPool.getUserAccountData(strategyAddress);
        console.log(userAccountData.totalCollateralETH.toString(),
            userAccountData.totalDebtETH.toString(),
            userAccountData.availableBorrowsETH.toString(),
            userAccountData.currentLiquidationThreshold.toString(),
            userAccountData.ltv.toString(),
            userAccountData.healthFactor.toString());
        mockPriceOracle.setAssetPrice(MFC.stETH_ADDRESS,stETHPrice.multipliedBy(80).dividedBy(100).toFixed(0,2));
        console.log('stETH price3:%s',await mockPriceOracle.getAssetPrice(MFC.stETH_ADDRESS));
        userAccountData = await lendingPool.getUserAccountData(strategyAddress);
        console.log(userAccountData.totalCollateralETH.toString(),
            userAccountData.totalDebtETH.toString(),
            userAccountData.availableBorrowsETH.toString(),
            userAccountData.currentLiquidationThreshold.toString(),
            userAccountData.ltv.toString(),
            userAccountData.healthFactor.toString());
        borrowInfo = await strategy.borrowInfo({from:keeper});
        console.log("before rebalance2 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
        await strategy.rebalance({from:keeper});
        borrowInfo = await strategy.borrowInfo({from:keeper});
        console.log("after rebalance2 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
        userAccountData = await lendingPool.getUserAccountData(strategyAddress);
        console.log(userAccountData.totalCollateralETH.toString(),
            userAccountData.totalDebtETH.toString(),
            userAccountData.availableBorrowsETH.toString(),
            userAccountData.currentLiquidationThreshold.toString(),
            userAccountData.ltv.toString(),
            userAccountData.healthFactor.toString());
        mockPriceOracle.setAssetPrice(MFC.stETH_ADDRESS,stETHPrice.multipliedBy(100).dividedBy(100).toFixed(0,2));
        console.log('stETH price4:%s',await mockPriceOracle.getAssetPrice(MFC.stETH_ADDRESS));
        userAccountData = await lendingPool.getUserAccountData(strategyAddress);
        console.log(userAccountData.totalCollateralETH.toString(),
            userAccountData.totalDebtETH.toString(),
            userAccountData.availableBorrowsETH.toString(),
            userAccountData.currentLiquidationThreshold.toString(),
            userAccountData.ltv.toString(),
            userAccountData.healthFactor.toString());
        borrowInfo = await strategy.borrowInfo({from:keeper});
        console.log("before rebalance3 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
        await strategy.rebalance({from:keeper});
        borrowInfo = await strategy.borrowInfo({from:keeper});
        console.log("after rebalance3 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
        userAccountData = await lendingPool.getUserAccountData(strategyAddress);
        console.log(userAccountData.totalCollateralETH.toString(),
            userAccountData.totalDebtETH.toString(),
            userAccountData.availableBorrowsETH.toString(),
            userAccountData.currentLiquidationThreshold.toString(),
            userAccountData.ltv.toString(),
            userAccountData.healthFactor.toString());
    });
});