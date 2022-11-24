const checker = require('../strategy-checker');
const {default: BigNumber} = require("bignumber.js");
const topUp = require('../../../utils/top-up-utils');
const MFC = require('../../../config/mainnet-fork-test-config');
const {ethers} = require("hardhat");
const EulerRevolvingLoanStrategy = hre.artifacts.require('ETHEulerRevolvingLoanStrategy');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const merkleTree = require('../../../utils/merkle-tree');
const eulerUtils = require('../../../utils/euler-utils');
const {balance, send} = require("@openzeppelin/test-helpers");
const {assert} = require("chai");

describe('【EulerRevolvingLoanWETHStrategy Strategy Checker】', function () {
    checker.check('EulerRevolvingLoanWETHStrategy', async function (strategy) {
    }, async function (strategy) {

        const eulClaimAccount = '0xf2E12342bf778cF57d44418F949c876c2e5DaeBA';
        const eulContract = await ERC20.at('0xd9fcd98c322942075a5c3860693e9f4f03aae07b');
        console.log("before claim",(await eulContract.balanceOf(eulClaimAccount)).toString());

        const distFile = './test/merkle-dist.json.gz';
        let distribution = eulerUtils.loadMerkleDistFile(distFile);

        let items = distribution.values.map(v => { return {
            account: v[0],
            token: v[1],
            claimable: ethers.BigNumber.from(v[2]),
        }});

        let proof = merkleTree.proof(items, eulClaimAccount, eulerUtils.EulTokenAddr);

        await strategy.claim(eulClaimAccount,eulerUtils.EulTokenAddr,proof.item.claimable.toString(),proof.witnesses,'0x0000000000000000000000000000000000000000');
        const claimAmount = await eulContract.balanceOf(eulClaimAccount);
        console.log("after claim",claimAmount.toString());

        // mock owner
        await ethers.getImpersonatedSigner(eulClaimAccount);
        const accounts = await ethers.getSigners();
        await send.ether(accounts[0].address, eulClaimAccount, 10 * 10 ** 18);
        await eulContract.transfer(strategy.address, claimAmount.toString(), {
            from: eulClaimAccount,
        });

    },async function (strategyAddress,customAddressArray) {
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
        rebalanceTx = await strategy.rebalance({from:keeper});
        console.log("rebalance gasUsed",rebalanceTx.receipt.gasUsed.toString());
        afterTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
        console.log('rebalance2 beforeTotalAssets:%s,afterTotalAssets:%s', beforeTotalAssets.toFixed(), afterTotalAssets.toFixed());
        borrowInfo = await strategy.borrowInfo({from:keeper});
        console.log("after rebalance2 borrowInfo(remainingAmount,overflowAmount)=",borrowInfo._remainingAmount.toString(),borrowInfo._overflowAmount.toString());

    },0,async function (strategy,customAddressArray) {

        const accounts = await ethers.getSigners();
        const eulHolder = '0xe837c2203883132b11ecb6ed8c246fd98c87fbd3';
        // mock eulHolder
        await ethers.getImpersonatedSigner(eulHolder);
        await send.ether(accounts[0].address, eulHolder, 10 * 10 ** 18);

        const eulContract = await ERC20.at('0xd9fcd98c322942075a5c3860693e9f4f03aae07b');
        const transferAmount =  new BigNumber(100 * 10 ** 18);
        console.log("before transfer",(await eulContract.balanceOf(eulHolder)).toString());
        console.log("before transfer strategy",(await eulContract.balanceOf(strategy.address)).toString());
        await eulContract.transfer(strategy.address, transferAmount.toString(), {
            from: eulHolder,
        });
        console.log("after transfer",(await eulContract.balanceOf(eulHolder)).toString());
        console.log("after transfer strategy",(await eulContract.balanceOf(strategy.address)).toString());

        const mockVaultAddress = customAddressArray[0];
        const wethTokenContract = await ERC20.at(MFC.WETH_ADDRESS);
        const beforeBalanceOfWeth = new BigNumber(await wethTokenContract.balanceOf(mockVaultAddress));

        const eulClaimAccount = '0x8c97Da9740d23F9b126620c5EAd7F1c7E16340Ab';
        console.log("before claim",(await eulContract.balanceOf(eulClaimAccount)).toString());

        const distFile = './test/merkle-dist.json.gz';
        let distribution = eulerUtils.loadMerkleDistFile(distFile);

        let items = distribution.values.map(v => { return {
            account: v[0],
            token: v[1],
            claimable: ethers.BigNumber.from(v[2]),
        }});

        let proof = merkleTree.proof(items, eulClaimAccount, eulerUtils.EulTokenAddr);

        await strategy.claim(eulClaimAccount,eulerUtils.EulTokenAddr,proof.item.claimable.toString(),proof.witnesses,'0x0000000000000000000000000000000000000000');

        console.log("after claim",(await eulContract.balanceOf(eulClaimAccount)).toString());
        const afterBalanceOfWeth  = new BigNumber(await wethTokenContract.balanceOf(mockVaultAddress));
        console.log("beforeBalanceOfWeth,afterBalanceOfWeth=",beforeBalanceOfWeth.toString(),afterBalanceOfWeth.toString());
        assert(afterBalanceOfWeth.isGreaterThan(beforeBalanceOfWeth), 'there is no reward to sell');
    });
});