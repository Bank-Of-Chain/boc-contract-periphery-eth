// npx hardhat test ./test/strategy-eth/stakewise/stake-wise-reth2-seth2-500-strategy-checker.test.js
const checker = require('../strategy-checker');
const {ethers} = require('hardhat');
const {default: BigNumber} = require('bignumber.js');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const topUp = require('../../../utils/top-up-utils');
const {send} = require('@openzeppelin/test-helpers');
const MFC = require('../../../config/mainnet-fork-test-config');

const {advanceBlock} = require('../../../utils/block-utils');
const MockUniswapV3Router = hre.artifacts.require('contracts/eth/mock/MockUniswapV3Router.sol:MockUniswapV3Router');
const StakeWiseReth2Seth2500Strategy = hre.artifacts.require("StakeWiseReth2Seth2500Strategy");

describe('【StakeWiseReth2Seth2500Strategy Strategy Checker】', function () {
    checker.check('StakeWiseReth2Seth2500Strategy', async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const rETH2 = '0x20BC832ca081b91433ff6c17f85701B6e92486c5';
        let rETH2Token = await ERC20.at(rETH2);
        let rETH2TokenDecimals = await rETH2Token.decimals();
        await topUpWant(rETH2, new BigNumber(10), investor);
        let wantBalance = new BigNumber(await balanceOf(rETH2, investor));
        console.log('StakeWiseReth2Seth2500Strategy before callback rETH2Balance: %d', wantBalance);
        rETH2Token.approve(mockUniswapV3Router.address, new BigNumber(10).multipliedBy(new BigNumber(10).pow(rETH2TokenDecimals)), {"from": investor});
        await mockUniswapV3Router.swap('0xa9ffb27d36901F87f1D0F20773f7072e38C5bfbA', true, new BigNumber(10).multipliedBy(new BigNumber(10).pow(rETH2TokenDecimals)), {"from": investor});

        const sETH2 = '0xFe2e637202056d30016725477c5da089Ab0A043A';
        let sETH2Token = await ERC20.at(sETH2);
        let sETH2TokenDecimals = await sETH2Token.decimals();
        await topUpWant(sETH2, new BigNumber(10), investor);
        wantBalance = new BigNumber(await balanceOf(sETH2, investor));
        console.log('StakeWiseReth2Seth2500Strategy before callback sETH2Balance: %d', wantBalance);
        sETH2Token.approve(mockUniswapV3Router.address, new BigNumber(10).multipliedBy(new BigNumber(10).pow(sETH2TokenDecimals)), {"from": investor});
        await mockUniswapV3Router.swap('0xa9ffb27d36901F87f1D0F20773f7072e38C5bfbA', false, new BigNumber(10).multipliedBy(new BigNumber(10).pow(sETH2TokenDecimals)), {"from": investor});

    }, async function (strategy) {
    }, async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        keeper = accounts[19].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const stakeWiseReth2Seth2500Strategy = await StakeWiseReth2Seth2500Strategy.at(strategy);

        let twap = new BigNumber(await stakeWiseReth2Seth2500Strategy.getTwap());
        console.log('before swap twap: %s', twap.toFixed());

        const rETH2 = '0x20BC832ca081b91433ff6c17f85701B6e92486c5';
        let rETH2Token = await ERC20.at(rETH2);
        let rETH2TokenDecimals = await rETH2Token.decimals();
        await topUpWant(rETH2, new BigNumber(20), investor);
        let wantBalance = new BigNumber(await balanceOf(rETH2, investor));
        console.log('StakeWiseReth2Seth2500Strategy before callback rETH2Balance: %d', wantBalance);
        rETH2Token.approve(mockUniswapV3Router.address, new BigNumber(10).multipliedBy(new BigNumber(10).pow(rETH2TokenDecimals)), {"from": investor});
        await mockUniswapV3Router.swap('0xa9ffb27d36901F87f1D0F20773f7072e38C5bfbA', true, new BigNumber(10).multipliedBy(new BigNumber(10).pow(rETH2TokenDecimals)), {"from": investor});

        await advanceBlock(1);
        twap = new BigNumber(await stakeWiseReth2Seth2500Strategy.getTwap());
        console.log('after swap twap: %s', twap.toFixed());

        const beforeBaseMintInfo = await stakeWiseReth2Seth2500Strategy.baseMintInfo();
        console.log('before rebalance beforeBaseMintInfo.tokenId: ', beforeBaseMintInfo.tokenId);
        await stakeWiseReth2Seth2500Strategy.rebalanceByKeeper({"from": keeper});
        const afterBaseMintInfo = await stakeWiseReth2Seth2500Strategy.baseMintInfo();
        console.log('after rebalance afterBaseMintInfo.tokenId: ', afterBaseMintInfo.tokenId);
        assert(beforeBaseMintInfo.tokenId !== afterBaseMintInfo.tokenId, 'rebalance fail');
        wantBalance = new BigNumber(await balanceOf(rETH2, investor));
        console.log('StakeWiseReth2Seth2500Strategy uniswapV3RebalanceCallback 2 rETH2Balance: %d', wantBalance);
        rETH2Token.approve(mockUniswapV3Router.address, new BigNumber(10).multipliedBy(new BigNumber(10).pow(rETH2TokenDecimals)), {from: investor});
        await mockUniswapV3Router.swap("0xa9ffb27d36901F87f1D0F20773f7072e38C5bfbA", true, new BigNumber(10).multipliedBy(new BigNumber(10).pow(rETH2TokenDecimals)), {"from": investor});

        await advanceBlock(1);

        twap = new BigNumber(await stakeWiseReth2Seth2500Strategy.getTwap());
        console.log('after rebalance swap twap: %s', twap.toFixed());

        pendingRewards = await stakeWiseReth2Seth2500Strategy.harvest.call({
            from: keeper,
        });
        await stakeWiseReth2Seth2500Strategy.harvest({from: keeper});
    });
});

async function topUpWant(want, amount, investor) {
    console.log('want:', want);
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
    // sETH2
    if (want === MFC.sETH2_ADDRESS) {
        console.log('top up sETH2');
        await topUp.topUpSEth2ByAddress(amount.multipliedBy(1e18), investor);
    }
    // rETH2
    if (want === MFC.rETH2_ADDRESS) {
        console.log('top up rETH2');
        await topUp.topUpREth2ByAddress(amount.multipliedBy(1e18), investor);
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
