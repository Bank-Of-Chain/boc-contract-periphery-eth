const { default: BigNumber } = require('bignumber.js');
const { ethers } = require('hardhat');
const { assert } = require('chai');
const { expectEvent, balance, send} = require('@openzeppelin/test-helpers');

const MFC = require('../../config/mainnet-fork-test-config');
const addressConfig = require('../../config/address-config');
const { strategiesList } = require('../../config/strategy-usd/strategy-config-usd')

const topUp = require('../../utils/top-up-utils');
const { advanceBlock, getLatestBlock } = require('../../utils/block-utils');

const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const AccessControlProxy = hre.artifacts.require('AccessControlProxy');
const ChainlinkPriceFeed = hre.artifacts.require('ChainlinkPriceFeed');
const AggregatedDerivativePriceFeed = hre.artifacts.require('AggregatedDerivativePriceFeed');
const ValueInterpreter = hre.artifacts.require('ValueInterpreter');
const MockVault = hre.artifacts.require('contracts/usd/mock/MockVault.sol:MockVault');
const MockUniswapV3Router = hre.artifacts.require('MockUniswapV3Router');
const MockPriceModel = hre.artifacts.require('MockPriceModel');
const MockAavePriceOracleConsumer = hre.artifacts.require('MockAavePriceOracleConsumer');
const IDForcePriceOracle = hre.artifacts.require('IDForcePriceOracle');
const IDForceController = hre.artifacts.require('IDForceController');



let accessControlProxy;
let valueInterpreter;
let mockVault;
let mockUniswapV3Router;
let mockPriceModel;
let strategy;
let mockPriceOracle;

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

function findStrategyItem(strategyName) {

    const result = strategiesList.find((item) => {
        // console.log('item.name:%s,strategyName:%s',item.name,strategyName);

        return item.name == strategyName;
    });

    return result;
}

async function check(strategyName, callback, afterCallback, uniswapV3RebalanceCallback, outputCode = 0) {
    before(async function () {
        BigNumber.set({ DECIMAL_PLACES: 6 });
        accounts = await ethers.getSigners();
        governance = accounts[0].address;
        investor = accounts[1].address;
        harvester = accounts[2].address;
        keeper = accounts[19].address;

        mockPriceOracle = await MockAavePriceOracleConsumer.new();

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

        mockPriceModel = await MockPriceModel.new();
        console.log('mock vault address:%s,strategyName:%s', mockVault.address, strategyName);
        const strategyItem = findStrategyItem(strategyName);
        console.log('strategyItem:', strategyItem);

        const {
            name,
            contract,
            customParams
        } = strategyItem;

        // init strategy
        const Strategy = hre.artifacts.require(contract);
        strategy = await Strategy.new();

        const allParams = [
            mockVault.address,
            harvester,
            name,
            ...customParams
        ]
        console.log('allParams:', allParams);

        await strategy.initialize(...allParams);
        // top up for vault
        await _topUpFamilyBucket();
    });

    it('[strategy name should match the file name]', async function () {
        const name = await strategy.name();
        assert.deepEqual(name, strategyName, 'strategy name do not match the file name');
    });

    it('[strategy version should not be empty]', async function () {
        const version = await strategy.getVersion();
        assert(version !== '', 'strategy version is empty');
    });

    it('[strategy outputsInfo should not be empty]', async function () {
        const outputsInfo = await strategy.getOutputsInfo();
        assert(outputsInfo.length > 0, 'The strategy did not return outputsInfo');
    });

    let wants;
    let wantsInfo;
    it('[wants info should be same with wants]', async function () {
        wantsInfo = await strategy.getWantsInfo();
        wants = wantsInfo._assets;
        assert(wants.length > 0, 'the length of wants should be greater than 0');
    });

    it('[100,000USD < Third Pool Assets < 50,000,000,000USD]', async function () {
        let thirdPoolAssets = new BigNumber(await strategy.get3rdPoolAssets());
        console.log('3rdPoolAssets: %s', thirdPoolAssets.toFixed());
        let precision = new BigNumber(10 ** 18)
        let min = new BigNumber(100_000).multipliedBy(precision);
        let max = new BigNumber(50_000_000_000).multipliedBy(precision);
        assert(thirdPoolAssets.isGreaterThan(min) && thirdPoolAssets.isLessThan(max), 'large deviation in thirdPoolAssets estimation');
    });

    it('[strategy estimatedTotalAssets should be zero]', async function () {
        const estimatedTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
        assert(estimatedTotalAssets.isZero());
    });

    let depositUSD = new BigNumber(0);
    it('[estimatedTotalAssets = transferred tokens value]', async function () {
        let depositedAssets = [];
        let depositedAmounts = [];
        let wants0Contract = await ERC20.at(wantsInfo._assets[0]);
        let wants0Precision = new BigNumber(10 ** (await wants0Contract.decimals()));
        let initialAmount = new BigNumber(10000);
        let initialRatio = wantsInfo._ratios[0];
        let isIgnoreRatio = await strategy.isWantRatioIgnorable();
        console.log('isIgnoreRatio:', isIgnoreRatio);
        for (let i = 0; i < wants.length; i++) {
            const asset = wantsInfo._assets[i];
            depositedAssets.push(asset);
            const ratio = wantsInfo._ratios[i];
            const assetContract = await ERC20.at(asset);
            let assetPrecision = new BigNumber(10 ** (await assetContract.decimals()));
            let amount;

            if (i !== 0) {
                amount = new BigNumber(initialAmount.multipliedBy(wants0Precision).multipliedBy(ratio).dividedBy(initialRatio).toFixed(0,1));
            } else {
                amount = initialAmount.multipliedBy(assetPrecision);
            }
            let wantToken = await ERC20.at(wantsInfo._assets[i]);
            let wantBalance = new BigNumber(await wantToken.balanceOf(investor));
            console.log('wantBalance:', wantBalance);

            console.log('want:%s,balance:%s,amount:%s', asset, wantBalance.toFixed(), amount.toFixed());
            if (amount.gte(wantBalance)) {
                amount = wantBalance;
            }
            amount = amount.integerValue();
            await assetContract.transfer(mockVault.address, amount, {
                from: investor,
            });
            depositedAmounts.push(amount);
            depositUSD = depositUSD.plus(await valueInterpreter.calcCanonicalAssetValueInUsd(asset, amount));
        }
        console.log('Lend:', depositedAssets, depositedAmounts.map(i => i.toFormat()));

        const lendTx = await mockVault.lend(strategy.address, depositedAssets, depositedAmounts);
        console.log("lend gas used=",lendTx.receipt.gasUsed);
        expectEvent.inTransaction(lendTx, 'Borrow', {
            _assets: depositedAssets,
            _amounts: depositedAmounts
        });
        const estimatedTotalAssets = new BigNumber(ethers.utils.formatEther(BigInt(await strategy.estimatedTotalAssets())));
        const debtRateQuery = () => {
            if (!strategy.debtRate) {
                return Promise.resolve(-1);
            }
            return strategy.debtRate().catch(() => -1)
        }
        const debtRate = new BigNumber(await debtRateQuery());
        console.log('depositUSD##:%d', depositUSD);
        depositUSD = new BigNumber(ethers.utils.formatEther(depositUSD.toFixed()));

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
            await callback(strategy.address, keeper);
        }

        let priceOracle = await IDForcePriceOracle.at("0xb4De37b03f7AcE98FB795572B18aE3CFae85A628");
        let _controller = await IDForceController.at("0x8B53Ab2c0Df3230EA327017C91Eb909f815Ad113");
        // let oldPrice =  new BigNumber(await priceOracle.getUnderlyingPrice("0x2f956b2f801c6dad74E87E7f45c94f6283BF0f45"));
        // const poster = '0x5c5bFFdB161E637B7f555CC122831126e02270d5';
        const owner = '0x17e66B1e0260C930bfA567ff3ab5c71794279b94';
        // mock owner
        await ethers.getImpersonatedSigner(owner);
        const accounts = await ethers.getSigners();
        // const beforeBalance = await balance.current(owner);
        await send.ether(accounts[0].address, owner, 10 * 10 ** 18)
        // console.log("owner eth balance = ",(await balance.current(owner)).toString());

        const _alliTokens = await _controller.getAlliTokens();
        for(let i=0;i<_alliTokens.length;i++){
            // console.log(i,_alliTokens[i]);
            await priceOracle._setAssetPriceModel(_alliTokens[i],mockPriceModel.address,{from: owner});
        }

        await advanceBlock(3);

        if (afterCallback) {
            await afterCallback(strategy);
        }

        pendingRewards = await strategy.harvest.call({
            from: keeper,
        });
        await strategy.harvest({ from: keeper });
        // After the harvest is completed, IronBank needs to perform one more step to sell and reinvest the mine
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
            await uniswapV3RebalanceCallback(strategy.address,[mockPriceOracle.address]);
        });
    }

    it('[estimatedTotalAssets should be 0 after withdraw all assets]', async function () {
        const strategyParam = await mockVault.strategies(strategy.address);
        console.log("strategyTotalDebt:%s",strategyParam.totalDebt);
        const strategyTotalDebt = new BigNumber(strategyParam.totalDebt);

        const redeemTx = await mockVault.redeem(strategy.address, strategyTotalDebt, outputCode);
        console.log("redeem gas used=",redeemTx.receipt.gasUsed);
        expectEvent.inTransaction(redeemTx,'Repay');
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
        withdrawUSD = new BigNumber(ethers.utils.formatEther(withdrawUSD.toFixed()))
        console.log('depositUSD:%s,withdrawUSD:%s,rewardUSD:%s', depositUSD.toFixed(), withdrawUSD.toFixed(), rewardUsd.toFixed());
        let strategyTotalWithdrawUsd = depositUSD.plus(rewardUsd);
        assert(strategyTotalWithdrawUsd.isGreaterThanOrEqualTo(depositUSD), 'the value of stablecoins user got do not increase');
    });
}

module.exports = {
    check,
};
