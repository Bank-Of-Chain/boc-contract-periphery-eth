const checker = require('../strategy-checker');
const { ethers } = require('hardhat');
const { default: BigNumber } = require('bignumber.js');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const topUp = require('../../../utils/top-up-utils');
const MFC = require('../../../config/mainnet-fork-test-config');

const { advanceBlock } = require('../../../utils/block-utils');
const MockUniswapV3Router = hre.artifacts.require('contracts/eth/mock/MockUniswapV3Router.sol:MockUniswapV3Router');
const UniswapV3RethEth3000Strategy = hre.artifacts.require("ETHUniswapV3Strategy");

describe('【UniswapV3RethEth3000Strategy Strategy Checker】', function () {
    checker.check('UniswapV3RethEth3000Strategy', async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const uniswapV3RethEth3000Strategy = await UniswapV3RethEth3000Strategy.at(strategy.address);
        const wantsInfo = await uniswapV3RethEth3000Strategy.getWantsInfo();
        const wants = wantsInfo._assets;
        for (let i = 0; i < wants.length; i++) {
            let wantToken = await ERC20.at(wants[i]);
            let wantTokenDecimals = await wantToken.decimals();
            // await topUpWant(wants[i], investor);
            let wantBalance = new BigNumber(await balanceOf(wants[i], investor));
            console.log('UniswapV3RethEth3000Strategy before callback wantBalance: %d', wantBalance);
            wantToken.approve(mockUniswapV3Router.address, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});
            await mockUniswapV3Router.swap('0xf0E02Cf61b31260fd5AE527d58Be16312BDA59b1', i === 0 ? true : false, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});
        }
    }, async function(strategy){}, async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        keeper = accounts[19].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const uniswapV3RethEth3000Strategy = await UniswapV3RethEth3000Strategy.at(strategy);

        let twap = new BigNumber(await uniswapV3RethEth3000Strategy.getTwap());
        console.log('before swap twap: %s', twap.toFixed());

        const wantsInfo = await uniswapV3RethEth3000Strategy.getWantsInfo();
        const wants = wantsInfo._assets;

        let wantToken = await ERC20.at(wants[0]);
        let wantTokenDecimals = await wantToken.decimals();
        // await topUpWant(wants[1], investor);
        let wantBalance = new BigNumber(await balanceOf(wants[0], investor));
        console.log('UniswapV3RethEth3000Strategy uniswapV3RebalanceCallback wantBalance: %d', wantBalance);
        wantToken.approve(mockUniswapV3Router.address, new BigNumber(50).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), { from: investor });
        await mockUniswapV3Router.swap("0xf0E02Cf61b31260fd5AE527d58Be16312BDA59b1", true, new BigNumber(50).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});

        await advanceBlock(1);
        twap = new BigNumber(await uniswapV3RethEth3000Strategy.getTwap());
        console.log('after swap twap: %s', twap.toFixed());

        await topUp.topUpRocketPoolEthByAddress(new BigNumber(10).pow(4), strategy);

        const beforeBaseMintInfo = await uniswapV3RethEth3000Strategy.baseMintInfo();
        console.log('before rebalance beforeBaseMintInfo.tokenId: ', beforeBaseMintInfo.tokenId);
        await uniswapV3RethEth3000Strategy.rebalanceByKeeper({"from": keeper});
        const afterBaseMintInfo = await uniswapV3RethEth3000Strategy.baseMintInfo();
        console.log('after rebalance afterBaseMintInfo.tokenId: ', afterBaseMintInfo.tokenId);
        assert(beforeBaseMintInfo.tokenId !== afterBaseMintInfo.tokenId, 'rebalance fail');
        wantBalance = new BigNumber(await balanceOf(wants[0], investor));
        console.log('UniswapV3RethEth3000Strategy uniswapV3RebalanceCallback 2 wantBalance: %d', wantBalance);
        wantToken.approve(mockUniswapV3Router.address, new BigNumber(50).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), { from: investor });
        await mockUniswapV3Router.swap("0xf0E02Cf61b31260fd5AE527d58Be16312BDA59b1", true, new BigNumber(50).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});

        await advanceBlock(1);

        twap = new BigNumber(await uniswapV3RethEth3000Strategy.getTwap());
        console.log('after rebalance swap twap: %s', twap.toFixed());

        pendingRewards = await uniswapV3RethEth3000Strategy.harvest.call({
            from: keeper,
        });
        await uniswapV3RethEth3000Strategy.harvest({ from: keeper });
    });
});

async function topUpWant(want, investor) {
    console.log('want:', want);
    const amount = new BigNumber(10).pow(6);
    // ETH
    if (want === MFC.ETH_ADDRESS) {
        console.log('top up ETH');
        await topUp.impersonates([MFC.ETH_WHALE_ADDRESS]);
        await send.ether(MFC.ETH_WHALE_ADDRESS, investor, '200000000000000000000');
    }
    // wETH
    if (want === MFC.WETH_ADDRESS) {
        console.log('top up wETH');
        await topUp.topUpWETHByAddress(amount.multipliedBy(1e18), investor);
    }
    // stETH
    if (want === MFC.stETH_ADDRESS) {
        console.log('top up stETH');
        await topUp.topUpStEthByAddress(amount.multipliedBy(1e18), investor);
    }
    // wstETH
    if (want === MFC.wstETH_ADDRESS) {
        console.log('top up wstETH');
        await topUp.topUpWstEthByAddress(amount.multipliedBy(1e18), investor);
    }
    // rocketPoolETH
    if (want === MFC.rocketPoolETH_ADDRESS) {
        console.log('top up rocketPoolETH');
        await topUp.topUpRocketPoolEthByAddress(amount.multipliedBy(1e18), investor);
    }
}

async function balanceOf(asset, address) {
    if (asset === MFC.ETH_ADDRESS) {
        const provider = ethers.provider;
        console.log('balance=', (await provider.getBalance(address)).toString());
        return (await provider.getBalance(address)).toString();
    } else {
        const tokenContract = await ERC20.at(asset);
        return await tokenContract.balanceOf(address);
    }
}
