const checker = require('../strategy-checker');
const {default: BigNumber} = require("bignumber.js");
const topUp = require('../../../utils/top-up-utils');
const MFC = require('../../../config/mainnet-fork-test-config');
const {ethers} = require("hardhat");
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const IAaveLendingPool = hre.artifacts.require('IAaveLendingPool');
const AaveWETHstETHStrategy = hre.artifacts.require('AaveWETHstETHStrategy');

describe('【AaveWETHstETHStrategy Strategy Checker】', function() {
    checker.check('AaveWETHstETHStrategy',async function (strategy) {

    },async function (strategy) {
        const aTokenContract = await ERC20.at('0x1982b2F5814301d4e9a8b0201555376e62F82428');
        const astETHAmount = new BigNumber(await aTokenContract.balanceOf(strategy.address));
        const lidoApr = 531; //x/10000
        const growDay = 7;
        const increaseAstEthAmount = new BigNumber(astETHAmount.multipliedBy(growDay).multipliedBy(lidoApr).dividedBy(365).dividedBy(10000).toFixed(0,2));
        const accounts = await ethers.getSigners();
        const keeper = accounts[19].address;
        await topUp.topUpSTETHByAddress(increaseAstEthAmount,keeper);

        const _lendingPoolAddress = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
        const _aaveLendingPool =  await IAaveLendingPool.at(_lendingPoolAddress);

        const tokenContract = await ERC20.at(MFC.stETH_ADDRESS);
        await tokenContract.approve(_lendingPoolAddress, increaseAstEthAmount,{from:keeper});
        await _aaveLendingPool.deposit(MFC.stETH_ADDRESS, increaseAstEthAmount.toFixed(), keeper, 0,{from: keeper});

        const receivedAstETHAmount = await aTokenContract.balanceOf(keeper);
        console.log("harvest astETH:",receivedAstETHAmount.toString());

        await aTokenContract.transfer(strategy.address,receivedAstETHAmount.toString(),{from:keeper});
    },async function (strategyAddress) {

        const aTokenContract = await ERC20.at('0x1982b2F5814301d4e9a8b0201555376e62F82428');
        const strategy = await AaveWETHstETHStrategy.at(strategyAddress);
        const accounts = await ethers.getSigners();
        const keeper = accounts[19].address;
        const astETHAmount = new BigNumber(await aTokenContract.balanceOf(strategy.address));
        const increaseAstEthAmount = new BigNumber(astETHAmount.multipliedBy(1001).div(1000).toFixed(0,2));
        await topUp.topUpSTETHByAddress(increaseAstEthAmount,keeper); const _lendingPoolAddress = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
        const _aaveLendingPool =  await IAaveLendingPool.at(_lendingPoolAddress);

        const tokenContract = await ERC20.at(MFC.stETH_ADDRESS);
        await tokenContract.approve(_lendingPoolAddress, increaseAstEthAmount,{from:keeper});
        await _aaveLendingPool.deposit(MFC.stETH_ADDRESS, increaseAstEthAmount.toFixed(), keeper, 0,{from: keeper});

        const receivedAstETHAmount = await aTokenContract.balanceOf(keeper);
        console.log("increase astETH:",receivedAstETHAmount.toString());

        await aTokenContract.transfer(strategy.address,receivedAstETHAmount.toString(),{from:keeper});

        const borrowInfo = await strategy.borrowInfo({from:keeper});
        console.log("before rebalance borrowInfo(remainingAmount,overflowAmount,_overflowDebtAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString(),borrowInfo._overflowDebtAmount.toString());
        await strategy.rebalance({from:keeper});
        const borrowInfo2 = await strategy.borrowInfo({from:keeper});
        console.log("after rebalance borrowInfo(remainingAmount,overflowAmount,_overflowDebtAmount)=",borrowInfo2._remainingAmount.toString(),borrowInfo2._overflowAmount.toString(),borrowInfo2._overflowDebtAmount.toString());
    });
});