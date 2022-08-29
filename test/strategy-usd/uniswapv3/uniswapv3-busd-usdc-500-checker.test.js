const checker = require('../strategy-checker');
const {ethers} = require('hardhat');
const {default: BigNumber} = require('bignumber.js');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const topUp = require('../../../utils/top-up-utils');
const {advanceBlock} = require('../../../utils/block-utils');
const MockUniswapV3Router = hre.artifacts.require('contracts/usd/mock/MockUniswapV3Router.sol:MockUniswapV3Router');
const UniswapV3BusdUsdc500Strategy = hre.artifacts.require("UniswapV3Strategy");

describe('【UniswapV3BusdUsdc500Strategy Strategy Checker】', function () {
    checker.check('UniswapV3BusdUsdc500Strategy', async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const uniswapV3BusdUsdc500Strategy = await UniswapV3BusdUsdc500Strategy.at(strategy);
        const wantsInfo = await uniswapV3BusdUsdc500Strategy.getWantsInfo();
        const wants = wantsInfo._assets;
        for (let i = 0; i < wants.length; i++) {
            let wantToken = await ERC20.at(wants[i]);
            let wantTokenDecimals = await wantToken.decimals();
            wantToken.approve(mockUniswapV3Router.address, new BigNumber(10).pow(6).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});
            await mockUniswapV3Router.swap('0x00cEf0386Ed94d738c8f8A74E8BFd0376926d24C', i === 0 ? true : false, new BigNumber(10).pow(6).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});
        }
    }, {}, async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        keeper = accounts[19].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const uniswapV3BusdUsdc500Strategy = await UniswapV3BusdUsdc500Strategy.at(strategy);

        let twap = new BigNumber(await uniswapV3BusdUsdc500Strategy.getTwap());
        console.log('before swap twap: %s', twap.toFixed());

        const wantsInfo = await uniswapV3BusdUsdc500Strategy.getWantsInfo();
        const wants = wantsInfo._assets;

        let wantToken = await ERC20.at(wants[1]);
        let wantTokenDecimals = await wantToken.decimals();
        wantToken.approve(mockUniswapV3Router.address, new BigNumber(10).pow(6).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {from: investor});
        await mockUniswapV3Router.swap("0x00cEf0386Ed94d738c8f8A74E8BFd0376926d24C", false, new BigNumber(10).pow(6).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});

        await advanceBlock(1);
        twap = new BigNumber(await uniswapV3BusdUsdc500Strategy.getTwap());
        console.log('after swap twap: %s', twap.toFixed());

        await topUp.topUpBusdByAddress(new BigNumber(10).pow(22), strategy);

        const beforeBaseMintInfo = await uniswapV3BusdUsdc500Strategy.getMintInfo();
        console.log('before rebalance beforeBaseMintInfo.tokenId: ', beforeBaseMintInfo.baseTokenId);
        await uniswapV3BusdUsdc500Strategy.rebalanceByKeeper({from: keeper});
        const afterBaseMintInfo = await uniswapV3BusdUsdc500Strategy.getMintInfo();
        console.log('after rebalance afterBaseMintInfo.tokenId: ', afterBaseMintInfo.baseTokenId);
        assert(beforeBaseMintInfo.baseTokenId !== afterBaseMintInfo.baseTokenId, 'rebalance fail');

        wantToken.approve(mockUniswapV3Router.address, new BigNumber(10).pow(6).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {from: investor});
        await mockUniswapV3Router.swap("0x00cEf0386Ed94d738c8f8A74E8BFd0376926d24C", false, new BigNumber(10).pow(6).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});

        await advanceBlock(1);

        twap = new BigNumber(await uniswapV3BusdUsdc500Strategy.getTwap());
        console.log('after rebalance swap twap: %s', twap.toFixed());

        pendingRewards = await uniswapV3BusdUsdc500Strategy.harvest.call({
            from: keeper,
        });
        await uniswapV3BusdUsdc500Strategy.harvest({from: keeper});
    });
});
