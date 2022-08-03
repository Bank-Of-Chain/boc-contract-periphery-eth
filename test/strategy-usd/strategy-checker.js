const { default: BigNumber } = require('bignumber.js');
const { ethers } = require('hardhat');
const { assert } = require('chai');

const MFC = require('../../config/mainnet-fork-test-config');
const addressConfig = require('../../config/address-config');

const topUp = require('../../utils/top-up-utils');
const { advanceBlock, getLatestBlock } = require('../../utils/block-utils');

const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const AccessControlProxy = hre.artifacts.require('AccessControlProxy');
const ChainlinkPriceFeed = hre.artifacts.require('ChainlinkPriceFeed');
const AggregatedDerivativePriceFeed = hre.artifacts.require('AggregatedDerivativePriceFeed');
const ValueInterpreter = hre.artifacts.require('ValueInterpreter');
const MockVault = hre.artifacts.require('contracts/usd/mock/MockVault.sol:MockVault');
const IUniswapV2 = hre.artifacts.require('IUniswapV2');
const MockUniswapV3Router = hre.artifacts.require('contracts/usd/mock/MockUniswapV3Router.sol:MockUniswapV3Router');

const ZERO_BN = new BigNumber(0);

let accessControlProxy;
let valueInterpreter;
let mockVault;
let mockUniswapV3Router;
let strategy;

let governance;
let keeper;
let investor;
let harvester;

async function _initPriceFeed() {
    const primitives = new Array();
    const aggregators = new Array();
    const heartbeats = new Array();
    const rateAssets = new Array();
    for (const key in MFC.CHAINLINK.aggregators) {
        const value = MFC.CHAINLINK.aggregators[key];
        primitives.push(value.primitive);
        aggregators.push(value.aggregator);
        heartbeats.push(value.heartbeat);
        rateAssets.push(value.rateAsset);
    }
    const basePeggedPrimitives = new Array();
    const basePeggedRateAssets = new Array();
    for (const key in MFC.CHAINLINK.basePegged) {
        const value = MFC.CHAINLINK.basePegged[key];
        basePeggedPrimitives.push(value.primitive);
        basePeggedRateAssets.push(value.rateAsset);
    }
    const chainlinkPriceFeed = await ChainlinkPriceFeed.new(MFC.CHAINLINK.ETH_USD_AGGREGATOR, MFC.CHAINLINK.ETH_USD_HEARTBEAT, primitives, aggregators, heartbeats, rateAssets, basePeggedPrimitives, basePeggedRateAssets, accessControlProxy.address);
    let derivatives = new Array();
    const priceFeeds = new Array();
    const aggregatedDerivativePriceFeed = await AggregatedDerivativePriceFeed.new(derivatives, priceFeeds, accessControlProxy.address);
    valueInterpreter = await ValueInterpreter.new(chainlinkPriceFeed.address, aggregatedDerivativePriceFeed.address, accessControlProxy.address);
}

function contains(arr, obj) {
    let i = arr.length;
    while (i--) {
        if (arr[i].toLowerCase() === obj.toLowerCase()) {
            return true;
        }
    }
    return false;
}

async function getTokenPrecision(address) {
    const erc20Contract = await ERC20.at(address);
    return new BigNumber(10 ** await erc20Contract.decimals());
}

async function _topUpFamilyBucket() {
    const {
        _assets: wants
    } = await strategy.getWantsInfo();
    console.log('wants:', wants);
    if (contains(wants, MFC.USDT_ADDRESS)) {
        console.log('top up USDT');
        let token = await ERC20.at(MFC.USDT_ADDRESS);
        let tokenDecimals = await token.decimals();
        await topUp.topUpUsdtByAddress(1e7 * 10 ** tokenDecimals, investor);
    }
    if (contains(wants, MFC.USDC_ADDRESS)) {
        console.log('top up USDC');
        let token = await ERC20.at(MFC.USDC_ADDRESS);
        let tokenDecimals = await token.decimals();
        await topUp.topUpUsdcByAddress(1e7 * 10 ** tokenDecimals, investor);
    }
    if (contains(wants, MFC.DAI_ADDRESS)) {
        console.log('top up DAI');
        await topUp.topUpDaiByAddress(1e7 * 1e18, investor);
    }
    if (contains(wants, MFC.BUSD_ADDRESS)) {
        console.log('top up BUSD');
        await topUp.impersonates([addressConfig.BUSD_WHALE_ADDRESS]);
        await topUp.topUpMain(
            addressConfig.BUSD_ADDRESS,
            addressConfig.BUSD_WHALE_ADDRESS,
            investor,
            1e7 * 1e18
        );
    }
    if (contains(wants, MFC.MIM_ADDRESS)) {
        console.log('top up MIM');
        await topUp.impersonates([addressConfig.MIM_WHALE_ADDRESS]);
        await topUp.topUpMain(
            addressConfig.MIM_ADDRESS,
            addressConfig.MIM_WHALE_ADDRESS,
            investor,
            1e7 * 1e18
        );
    }
    if (contains(wants, MFC.TUSD_ADDRESS)) {
        console.log('top up TUSD');
        await topUp.topUpTusdByAddress(1e7 * 1e18, investor);
    }
    if (contains(wants, MFC.USDP_ADDRESS)) {
        console.log('top up USDP');
        await topUp.impersonates([addressConfig.USDP_WHALE_ADDRESS]);
        await topUp.topUpMain(
            addressConfig.USDP_ADDRESS,
            addressConfig.USDP_WHALE_ADDRESS,
            investor,
            1e7 * 1e18
        );
    }
    if (contains(wants, MFC.LUSD_ADDRESS)) {
        console.log('top up LUSD');
        await topUp.topUpLusdByAddress(1e7 * 1e18, investor);
    }
    if (contains(wants, MFC.GUSD_ADDRESS)) {
        console.log('top up GUSD');
        await topUp.impersonates([addressConfig.GUSD_WHALE_ADDRESS]);
        await topUp.topUpMain(
            addressConfig.GUSD_ADDRESS,
            addressConfig.GUSD_WHALE_ADDRESS,
            investor,
            1e7 * 1e18
        );
    }
    console.log('topUp finish!');
}

async function check(strategyName, callback, exchangeRewardTokenCallback = {}, uniswapV3RebalanceCallback,outputCode = 0) {
    before(async function () {
        accounts = await ethers.getSigners();
        governance = accounts[0].address;
        investor = accounts[1].address;
        harvester = accounts[2].address;
        keeper = accounts[19].address;

        accessControlProxy = await AccessControlProxy.new();
        await accessControlProxy.initialize(governance, governance, governance, keeper);
        // init vault
        underlying = await ERC20.at(MFC.USDT_ADDRESS);
        // init price feed
        await _initPriceFeed();
        // init mockVault
        mockVault = await MockVault.new(accessControlProxy.address, valueInterpreter.address);
        // init mockUniswapV3Router
        mockUniswapV3Router = await MockUniswapV3Router.new();
        console.log('mock vault address:%s', mockVault.address);
        // init strategy
        const Strategy = hre.artifacts.require(strategyName);
        strategy = await Strategy.new();
        await strategy.initialize(mockVault.address, harvester);
        // top up for vault
        await _topUpFamilyBucket();
    });

    it('[strategy name should match the file name]', async function () {
        const name = await strategy.name();
        assert.deepEqual(name, strategyName, 'strategy name do not match the file name');
    });

    let wants;
    let wantsInfo;
    it('[wants info should be same with wants]', async function () {
        wantsInfo = await strategy.getWantsInfo();
        wants = wantsInfo._assets;
        assert(wants.length > 0, 'the length of wants should be greater than 0');
    });

    it('[100,000USD < Third Pool Assets < 5,000,000,000USD]', async function () {
        let thirdPoolAssets = new BigNumber(await strategy.get3rdPoolAssets());
        console.log('3rdPoolAssets: %s', thirdPoolAssets.toFixed());
        let precision = new BigNumber(10 ** 18)
        let min = new BigNumber(100_000).multipliedBy(precision);
        let max = new BigNumber(5_000_000_000).multipliedBy(precision);
        assert(thirdPoolAssets.isGreaterThan(min) && thirdPoolAssets.isLessThan(max), 'large deviation in thirdPoolAssets estimation');
    });
    
    let depositUSD = new BigNumber(0);
    it('[estimatedTotalAssets = transferred tokens value]', async function () {
        let depositedAssets = [];
        let depositedAmounts = [];
        let wants0Contract = await ERC20.at(wantsInfo._assets[0]);
        let wants0Precision = new BigNumber(10 ** (await wants0Contract.decimals()));
        let initialAmount = new BigNumber(10000);
        let initialRatio = wantsInfo._ratios[0];
        for (let i = 0; i < wants.length; i++) {
            const asset = wantsInfo._assets[i];
            depositedAssets.push(asset);
            const ratio = wantsInfo._ratios[i];
            const assetContract = await ERC20.at(asset);
            let assetPrecision = new BigNumber(10 ** (await assetContract.decimals()));
            let amount;
            let isIgnoreRatio = await strategy.isWantRatioIgnorable();
            if (i !== 0 && !isIgnoreRatio) {
                amount = new BigNumber(initialAmount.multipliedBy(wants0Precision).multipliedBy(ratio).dividedBy(initialRatio).toFixed(0));
            } else {
                amount = initialAmount.multipliedBy(assetPrecision);
            }
            let wantToken = await ERC20.at(wantsInfo._assets[i]);
            let wantBalance = new BigNumber(await wantToken.balanceOf(investor));
            console.log('wantBalance:',wantBalance);
            console.log('isIgnoreRatio:',isIgnoreRatio);
            console.log('want:%s,balance:%s,amount:%s',asset,wantBalance.toFixed(),amount.toFixed());
            if (wantBalance.gte(amount)){
                await assetContract.transfer(mockVault.address, amount, {
                    from: investor,
                });
                depositedAmounts.push(amount);
                depositUSD = depositUSD.plus(await valueInterpreter.calcCanonicalAssetValueInUsd(asset, amount));
            } else if (isIgnoreRatio){
                console.log('use 0');
                depositedAmounts.push(new BigNumber(0));
            }
        }
        console.log('Lend:',depositedAssets,depositedAmounts.map(i => i.toFormat()));

        await mockVault.lend(strategy.address, depositedAssets, depositedAmounts);
        const estimatedTotalAssets = new BigNumber(await strategy.estimatedTotalAssets()).dividedBy(10 ** 18);
        const debtRateQuery = () => {
            if(!strategy.debtRate){
                return Promise.resolve(-1);
            }
            return strategy.debtRate().catch(() => -1)
        }
        const debtRate = new BigNumber(await debtRateQuery());
        depositUSD = depositUSD.dividedBy(10 ** 18);
        let delta = depositUSD.minus(estimatedTotalAssets);
        console.log('depositUSD:%s,estimatedTotalAssets:%s,delta:%s', depositUSD.toFixed(), estimatedTotalAssets.toFixed(), delta.toFixed());
        console.log('debtRate=%s', debtRate.toString());
        // If the strategy does not have debit, debtRate=-1, if there is debit, such as IronBank, the debit rate must be greater than 70% less than 100%
        assert(debtRate.eq(-1) || (debtRate.gt(7000) && debtRate.lt(10000)), 'debtRate must gt 7000 in Ironbank');
        assert(delta.abs().isLessThan(3), 'estimatedTotalAssets does not match depositedUSD value');
    });

    it('[the stablecoins balance of strategy should be zero]', async function () {
        let totalBalance = 0;
        for (let want of wants) {
            let token = await ERC20.at(want);
            let balance = await token.balanceOf(strategy.address);
            console.log('after deposit %s strategy balance is %s', await token.symbol(), balance.toString());
            totalBalance += balance;
        }
        assert(totalBalance == 0, 'there are some stablecoins left in strategy');
    });

    let pendingRewards;
    let produceReward = false;
    it('[totalAssets should increase after 3 days]', async function () {
        const beforeTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
        if (callback) {
            await callback(strategy.address,keeper);
        }
        await advanceBlock(3);
        pendingRewards = await strategy.harvest.call({
            from: keeper,
        });
        await strategy.harvest({ from: keeper });
        // After the harvest is completed, IronBank needs to perform one more step to sell and reinvest the mine
        const {
            investWithSynthForex
        } = exchangeRewardTokenCallback;
        if (typeof investWithSynthForex === 'function') {
            await investWithSynthForex(strategy, keeper).catch(() => {});
        }
        const rewardsTokens = pendingRewards._rewardsTokens;
        for (let i = 0; i < rewardsTokens.length; i++) {
            const rewardToken = rewardsTokens[i];
            let rewardTokenContract = await ERC20.at(rewardToken);
            let rewardTokenBalance = await rewardTokenContract.balanceOf(harvester);
            if (rewardTokenBalance > 0) {
                produceReward = true;
            }
        }
        const afterTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
        console.log('beforeTotalAssets:%s,afterTotalAssets:%s,produceReward:%s', beforeTotalAssets.toFixed(), afterTotalAssets.toFixed(), produceReward);
        assert(afterTotalAssets.isGreaterThan(beforeTotalAssets) || produceReward, 'there is no profit after 3 days');
    });

    if (uniswapV3RebalanceCallback) {
        it('[UniswapV3 rebalance]', async function () {
            await uniswapV3RebalanceCallback(strategy.address);
        });
    }

    it('[estimatedTotalAssets should be 0 after withdraw all assets]', async function () {
        const estimatedTotalAssets0 = new BigNumber(await strategy.estimatedTotalAssets());
        await mockVault.redeem(strategy.address, estimatedTotalAssets0,outputCode);
        const estimatedTotalAssets1 = new BigNumber(await strategy.estimatedTotalAssets()).dividedBy(10 ** 18);
        console.log('After withdraw all shares,strategy assets:%s', estimatedTotalAssets1.toFixed());
        assert.isTrue(estimatedTotalAssets1.multipliedBy(10000).isLessThan(depositUSD), 'assets left in strategy should not be more than 1/10000');
    });

    let withdrawUSD = new BigNumber(0);
    it('[the value of stablecoins returned should increase]', async function () {
        let rewardUsd = new BigNumber(0);
        for (let want of wants) {
            let token = await ERC20.at(want);
            let balance = new BigNumber(await token.balanceOf(mockVault.address));
            let usd = new BigNumber(await valueInterpreter.calcCanonicalAssetValueInUsd(want, balance));
            withdrawUSD = withdrawUSD.plus(usd);
        }
        withdrawUSD = withdrawUSD.dividedBy(10 ** 18);
        console.log('depositUSD:%s,withdrawUSD:%s,rewardUSD:%s', depositUSD.toFixed(), withdrawUSD.toFixed(), rewardUsd.toFixed());
        let strategyTotalWithdrawUsd = depositUSD.plus(rewardUsd);
        assert(strategyTotalWithdrawUsd.isGreaterThanOrEqualTo(depositUSD), 'the value of stablecoins user got do not increase');
    });
}

async function exchangeRewardToken(pendingRewards, harvesterAddress, valueInterpreter, rewardsExchangePath, router = addressConfig.QUICKSWAP_ADDRESS) {
    let rewardUsd = new BigNumber(0);

    const rewardsTokens = pendingRewards._rewardsTokens;
    for (let i = 0; i < rewardsTokens.length; i++) {
        //get reward token amount
        const rewardTokenAddress = rewardsTokens[i];
        let rewardTokenContract = await ERC20.at(rewardTokenAddress);
        let rewardTokenAmount = new BigNumber(await rewardTokenContract.balanceOf(harvesterAddress));
        console.log('rewardToken ' + rewardTokenAddress + ' amount ' + rewardTokenAmount);

        //exchange reward token to stablecoins
        await topUp.impersonates([harvesterAddress]);
        let rewardTokenUsd = new BigNumber(0);
        if (rewardTokenAmount.isGreaterThan(0)) {
            rewardTokenContract.approve(router, 0, { from: harvesterAddress });
            rewardTokenContract.approve(router, rewardTokenAmount, { from: harvesterAddress });
            const routerContract = await IUniswapV2.at(router);
            let lastBlock = await getLatestBlock();
            let oneDayAfterLastBlockTimestamp = lastBlock.timestamp + 24 * 60 * 60;
            let exchangePath = rewardsExchangePath.get(rewardTokenAddress);
            await routerContract.swapExactTokensForTokens(rewardTokenAmount, 0, exchangePath, harvesterAddress, oneDayAfterLastBlockTimestamp, { from: harvesterAddress });

            //get reward token usd value
            let stablecoinsAddress = exchangePath[exchangePath.length - 1];
            let stablecoinContract = await ERC20.at(stablecoinsAddress);
            let harvesterStablecoinAmount = await stablecoinContract.balanceOf(harvesterAddress);
            rewardTokenUsd = new BigNumber(await valueInterpreter.calcCanonicalAssetValueInUsd(stablecoinsAddress, harvesterStablecoinAmount));
            console.log('reward[%s] harvester Usd Amount %s', i, rewardTokenUsd);
        }

        rewardUsd = rewardUsd.plus(rewardTokenUsd);
    }
    return rewardUsd;
}

module.exports = {
    check,
    exchangeRewardToken,
};
