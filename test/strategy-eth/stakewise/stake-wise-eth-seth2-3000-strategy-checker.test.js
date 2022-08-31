// npx hardhat test ./test/strategy-eth/stakewise/stake-wise-eth-seth2-3000-strategy-checker.test.js
const checker = require('../strategy-checker');
const {ethers} = require('hardhat');
const {default: BigNumber} = require('bignumber.js');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const topUp = require('../../../utils/top-up-utils');
const {send} = require('@openzeppelin/test-helpers');
const MFC = require('../../../config/mainnet-fork-test-config');

const {advanceBlock} = require('../../../utils/block-utils');
const MockUniswapV3Router = hre.artifacts.require('MockUniswapV3Router');
const StakeWiseEthSeth23000Strategy = hre.artifacts.require("StakeWiseEthSeth23000Strategy");

describe('【StakeWiseEthSeth23000Strategy Strategy Checker】', function () {
    checker.check('StakeWiseEthSeth23000Strategy', async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const stakeWiseEthSeth23000Strategy = await StakeWiseEthSeth23000Strategy.at(strategy.address);
        const wantsInfo = await stakeWiseEthSeth23000Strategy.getWantsInfo();
        const wants = wantsInfo._assets;
        for (let i = 0; i < wants.length; i++) {
            let wantToken = await ERC20.at(wants[i]);
            let wantTokenDecimals = await wantToken.decimals();
            // await topUpWant(wants[i], investor);
            let wantBalance = new BigNumber(await balanceOf(wants[i], investor));
            console.log('StakeWiseEthSeth23000Strategy before callback wantBalance: %d', wantBalance);
            wantToken.approve(mockUniswapV3Router.address, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});
            await mockUniswapV3Router.swap('0x7379e81228514a1D2a6Cf7559203998E20598346', i === 0 ? true : false, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});
        }
        await topUpWant(MFC.ETH_ADDRESS, strategy.address);
    }, async function (strategy) {}, async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        keeper = accounts[19].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const stakeWiseEthSeth23000Strategy = await StakeWiseEthSeth23000Strategy.at(strategy);

        let twap = new BigNumber(await stakeWiseEthSeth23000Strategy.getTwap());
        console.log('before swap twap: %s', twap.toFixed());

        const wantsInfo = await stakeWiseEthSeth23000Strategy.getWantsInfo();
        const wants = wantsInfo._assets;

        let wantToken = await ERC20.at(wants[0]);
        let wantTokenDecimals = await wantToken.decimals();
        // await topUpWant(wants[1], investor);
        let wantBalance = new BigNumber(await balanceOf(wants[0], investor));
        console.log('StakeWiseEthSeth23000Strategy uniswapV3RebalanceCallback wantBalance: %d', wantBalance);
        wantToken.approve(mockUniswapV3Router.address, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {from: investor});
        await mockUniswapV3Router.swap("0x7379e81228514a1D2a6Cf7559203998E20598346", true, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});

        await advanceBlock(1);
        twap = new BigNumber(await stakeWiseEthSeth23000Strategy.getTwap());
        console.log('after swap twap: %s', twap.toFixed());

        const beforeBaseMintInfo = await stakeWiseEthSeth23000Strategy.getMintInfo();
        console.log('before rebalance beforeBaseMintInfo.tokenId: ', beforeBaseMintInfo.baseTokenId);
        await stakeWiseEthSeth23000Strategy.rebalanceByKeeper({"from": keeper});
        const afterBaseMintInfo = await stakeWiseEthSeth23000Strategy.getMintInfo();
        console.log('after rebalance afterBaseMintInfo.tokenId: ', afterBaseMintInfo.baseTokenId);
        assert(beforeBaseMintInfo.baseTokenId !== afterBaseMintInfo.baseTokenId, 'rebalance fail');
        wantBalance = new BigNumber(await balanceOf(wants[0], investor));
        console.log('StakeWiseEthSeth23000Strategy uniswapV3RebalanceCallback 2 wantBalance: %d', wantBalance);
        wantToken.approve(mockUniswapV3Router.address, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {from: investor});
        await mockUniswapV3Router.swap("0x7379e81228514a1D2a6Cf7559203998E20598346", true, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});

        await advanceBlock(1);

        twap = new BigNumber(await stakeWiseEthSeth23000Strategy.getTwap());
        console.log('after rebalance swap twap: %s', twap.toFixed());

        pendingRewards = await stakeWiseEthSeth23000Strategy.harvest.call({
            from: keeper,
        });
        await stakeWiseEthSeth23000Strategy.harvest({from: keeper});
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
