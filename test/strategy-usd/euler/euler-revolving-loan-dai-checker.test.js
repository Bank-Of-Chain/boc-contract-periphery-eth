const checker = require('../strategy-checker');
const {default: BigNumber} = require("bignumber.js");
const topUp = require('../../../utils/top-up-utils');
const MFC = require('../../../config/mainnet-fork-test-config');
const {ethers} = require("hardhat");
const EulerRevolvingLoanStrategy = hre.artifacts.require('EulerRevolvingLoanStrategy');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');

describe('【EulerRevolvingLoanDaiStrategy Strategy Checker】', function () {
  checker.check('EulerRevolvingLoanDaiStrategy',async function (strategyAddress) {},async function (strategyAddress,customAddressArray) {

    const strategy = await EulerRevolvingLoanStrategy.at(strategyAddress);
    const accounts = await ethers.getSigners();
    const keeper = accounts[19].address;

    let borrowInfo = await strategy.borrowInfo({from:keeper});
    console.log("init borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
    await strategy.setBorrowCount(0);
    let beforeTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
    console.log("before rebalance1 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
    let rebalanceTx =  await strategy.rebalance({from:keeper});
    console.log("rebalance gasUsed",rebalanceTx.receipt.gasUsed.toString());
    let afterTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
    console.log('rebalance1 beforeTotalAssets:%s,afterTotalAssets:%s', beforeTotalAssets.toFixed(), afterTotalAssets.toFixed());
    borrowInfo = await strategy.borrowInfo({from:keeper});
    console.log("after rebalance1 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
    await strategy.setBorrowCount(10);
    beforeTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
    console.log("before rebalance2 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());
    rebalanceTx =  await strategy.rebalance({from:keeper});
    console.log("rebalance gasUsed",rebalanceTx.receipt.gasUsed.toString());
    afterTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
    console.log('rebalance2 beforeTotalAssets:%s,afterTotalAssets:%s', beforeTotalAssets.toFixed(), afterTotalAssets.toFixed());
    borrowInfo = await strategy.borrowInfo({from:keeper});
    console.log("after rebalance2 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());

  });
});
