const { default: BigNumber } = require('bignumber.js');
const { ethers } = require('hardhat');
const { assert } = require('chai');
const { expectEvent} = require('@openzeppelin/test-helpers');

const MFC = require('../../config/mainnet-fork-test-config');
const {strategiesList} = require('../../config/strategy-eth/strategy-config-eth')
const topUp = require('../../utils/top-up-utils');
const assertUtils = require('../../utils/assert-utils');
const { advanceBlock, } = require('../../utils/block-utils');
const { send } = require('@openzeppelin/test-helpers');

const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const AccessControlProxy = hre.artifacts.require('AccessControlProxy');
const PriceOracleConsumer = hre.artifacts.require('PriceOracleConsumer');
const MockVault = hre.artifacts.require('contracts/eth/mock/MockVault.sol:MockVault');
const Mock3rdEthPool = hre.artifacts.require('contracts/eth/mock/Mock3rdEthPool.sol:Mock3rdEthPool');
const MockUniswapV3Router = hre.artifacts.require('contracts/eth/mock/MockUniswapV3Router.sol:MockUniswapV3Router');

let accessControlProxy;
let priceOracleConsumer;
let mockVault;
let mockUniswapV3Router;
let strategy;

let governance;
let keeper;
let investor;

function contains(arr, obj) {
    let i = arr.length;
    while (i--) {
        if (arr[i].toLowerCase() === obj.toLowerCase()) {
            return true;
        }
    }
    return false;
}

async function _topUpFamilyBucket() {
    const {
        _assets: wants
    } = await strategy.getWantsInfo();
    console.log('wants:', wants);
    const amount = new BigNumber(10000);
    // ETH
    if (contains(wants, MFC.ETH_ADDRESS)) {
        console.log('top up ETH');
        await topUp.impersonates([MFC.ETH_WHALE_ADDRESS]);
        await send.ether(MFC.ETH_WHALE_ADDRESS, investor, '200000000000000000000');
    }
    // wETH
    if (contains(wants, MFC.WETH_ADDRESS)) {
        console.log('top up wETH');
        await topUp.topUpWETHByAddress(amount.multipliedBy(1e18), investor);
    }
    // stETH
    if (contains(wants, MFC.stETH_ADDRESS)) {
        console.log('top up stETH');
        await topUp.topUpSTETHByAddress(amount.multipliedBy(1e18), investor);
    }
    // wstETH
    if (contains(wants, MFC.wstETH_ADDRESS)) {
        console.log('top up wstETH');
        await topUp.topUpWstEthByAddress(amount.multipliedBy(1e18), investor);
    }
    // rocketPoolETH
    if (contains(wants, MFC.rocketPoolETH_ADDRESS)) {
        console.log('top up rocketPoolETH');
        await topUp.topUpRocketPoolEthByAddress(amount.multipliedBy(1e18), investor);
    }
    // sETH
    if (contains(wants, MFC.sETH_ADDRESS)) {
        console.log('top up sETH');
        await topUp.topUpSEthByAddress(amount.multipliedBy(1e18), investor);
    }
    // sETH2
    if (contains(wants, MFC.sETH2_ADDRESS)) {
        console.log('top up sETH2');
        await topUp.topUpSEth2ByAddress(amount.multipliedBy(1e18), investor);
    }
    // rETH2
    if (contains(wants, MFC.rETH2_ADDRESS)) {
        console.log('top up rETH2');
        await topUp.topUpREth2ByAddress(amount.multipliedBy(1e18), investor);
    }
}

async function decimals(asset) {
    if (asset === MFC.ETH_ADDRESS) {
        return 18;
    } else {
        const tokenContract = await ERC20.at(asset);
        return await tokenContract.decimals();
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

async function transfer(asset, amount, from, to) {
    if (asset === MFC.ETH_ADDRESS) {
        await send.ether(from, to, amount);
    } else {
        const tokenContract = await ERC20.at(asset);
        await tokenContract.transfer(to, amount, {
            from
        });
    }
}

function findStrategyItem(strategyName) {

    const result = strategiesList.find((item) => {
        return item.name == strategyName;
    });

    return result;
}

async function check(strategyName, beforeCallback, afterCallback, uniswapV3RebalanceCallback,outputCode = 0) {
    before(async function () {
        BigNumber.set({ DECIMAL_PLACES: 6 });
        accounts = await ethers.getSigners();
        governance = accounts[0].address;
        investor = accounts[1].address;
        harvester = accounts[2].address;
        keeper = accounts[19].address;

        accessControlProxy = await AccessControlProxy.new();
        priceOracleConsumer = await PriceOracleConsumer.new();
        await accessControlProxy.initialize(governance, governance, governance, keeper);
        // init mockVault
        mockVault = await MockVault.new(accessControlProxy.address, priceOracleConsumer.address);
        // init mockUniswapV3Router
        mockUniswapV3Router = await MockUniswapV3Router.new();
        console.log('mock vault address:%s', mockVault.address);
        // find strategy config
        const strategyItem = findStrategyItem(strategyName);
        console.log('strategyItem:',strategyItem);
        
        const {
            name,
            contract,
            customParams
        } = strategyItem;
        // init strategy
        const Strategy = hre.artifacts.require(contract);
        strategy = await Strategy.new();
        console.log('%s address:%s', strategyName, strategy.address);

        const allParams = [
            mockVault.address,
            name,
            ...customParams
        ]
        console.log('allParams:',allParams);
        
        await strategy.initialize(...allParams);

        // if (strategyName === 'MockEthStrategy') {
        //     let mock3rdEthPool = await Mock3rdEthPool.new();
        //     await strategy.initialize(mockVault.address, mock3rdEthPool.address);
        // } else {
        //     await strategy.initialize(mockVault.address);
        // }
        // console.log('strategy initialize finish.');

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
        wantsInfo._ratios.forEach(element => {
            console.log('wants ratio:%d', element);
        });

        assert(wants.length > 0, 'the length of wants should be greater than 0');
    });

    it('[50ETH < Third Pool Assets < 10,000,000ETH]', async function () {
        let thirdPoolAssets = new BigNumber(await strategy.get3rdPoolAssets());
        console.log('3rdPoolAssets: %d', thirdPoolAssets);
        let min = new BigNumber(50).multipliedBy(1e18);
        let max = new BigNumber(10_000_000).multipliedBy(1e18);
        assertUtils.assertBNBt(
            min,
            thirdPoolAssets,
            max,
            'large deviation in thirdPoolAssets estimation'
        );
    });

    let depositETH = new BigNumber(0);
    it('[estimatedTotalAssets = transferred tokens value]', async function () {
        // variable store lend information
        let depositedAssets = [];
        let depositedAmounts = [];
        // initial parameters definition
        let initialAmount = new BigNumber(20);
        let initialRatio = wantsInfo._ratios[0];
        let wants0Precision = new BigNumber(10 ** (await decimals(wantsInfo._assets[0])));

        // is ignore want ratio
        let isIgnoreRatio = await strategy.isWantRatioIgnorable();
        console.log('isIgnoreRatio:', isIgnoreRatio);
        for (let i = 0; i < wants.length; i++) {
            // local variable
            const asset = wantsInfo._assets[i];
            const ratio = wantsInfo._ratios[i];
            // asset precision
            let assetPrecision = new BigNumber(10 ** (await decimals(asset)));

            depositedAssets.push(asset);

            // calculate amount wanted to deposit
            let amount;
            
            if (i !== 0) {
                // for example,
                // assets: [ETH, stETH]
                // ratios: [100, 200]
                // we assume that ETH amount is 20
                // then, USDT amount = ETH amount * 200 / 100 = 40
                amount = initialAmount.multipliedBy(wants0Precision).multipliedBy(ratio).dividedBy(initialRatio);
            } else {
                amount = initialAmount.multipliedBy(assetPrecision);
            }

            let wantBalance = new BigNumber(await balanceOf(asset, investor));
            
            console.log('want:%s,balance:%d,amount:%d', asset, wantBalance, amount);
            // check balance enough
            if (wantBalance.gte(amount)) {
                await transfer(asset, amount, investor, mockVault.address);
                depositedAmounts.push(amount);
                if (asset === MFC.ETH_ADDRESS) {
                    depositETH = depositETH.plus(amount);
                } else {
                    depositETH = depositETH.plus(await priceOracleConsumer.valueInEth(asset, amount));
                }
            } else if (isIgnoreRatio) {
                console.log('use 0');
                depositedAmounts.push(0);
            }
        }
        console.log('Lend:', depositedAssets, depositedAmounts);

        const lendTx = await mockVault.lend(strategy.address, depositedAssets, depositedAmounts);
        expectEvent.inTransaction(lendTx, 'Borrow', {
            _assets: depositedAssets,
            _amounts: depositedAmounts
        });
        depositETH = new BigNumber(ethers.utils.formatEther(depositETH.toFixed()));
        const estimatedTotalAssets = new BigNumber(ethers.utils.formatEther(BigInt(await strategy.estimatedTotalAssets())));
        let delta = depositETH.minus(estimatedTotalAssets);
        console.log('depositETH:%d,estimatedTotalAssets:%d,delta:%d', depositETH, estimatedTotalAssets, delta);
        
        // we can tolerate a little loss
        assertUtils.assertBNBt(
            depositETH.multipliedBy(9995).dividedBy(10000),
            estimatedTotalAssets,
            depositETH.multipliedBy(10005).dividedBy(10000),
            'estimatedTotalAssets does not match depositedETH value'
        );
    });

    it('[the wants balances of strategy should be zero]', async function () {
        for (let want of wants) {
            let balance = await balanceOf(want, strategy.address);
            console.log('strategy remain want :%d', balance);

            assert(balance == 0, 'there are some wants left in strategy');
        }
    });

    it('[totalAssets should increase after 3 days]', async function () {
        const beforeTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
        if (beforeCallback) {
            await beforeCallback(strategy);
        }
        await advanceBlock(3);
        if (afterCallback) {
            await afterCallback(strategy);
        }
        const harvestTx = await strategy.harvest({ from: keeper });
        expectEvent.inTransaction(harvestTx,'StrategyReported');
        const afterTotalAssets = new BigNumber(await strategy.estimatedTotalAssets());
        console.log('beforeTotalAssets:%s, afterTotalAssets:%s', beforeTotalAssets.toFixed(), afterTotalAssets.toFixed());
        assert(afterTotalAssets.isGreaterThan(beforeTotalAssets), 'there is no profit after 3 days');
    });

    if (uniswapV3RebalanceCallback) {
        it('[UniswapV3 rebalance]', async function () {
            await uniswapV3RebalanceCallback(strategy.address);
        });
    }

    it('[estimatedTotalAssets should be 0 after withdraw all assets]', async function () {
        const estimatedTotalAssets0 = new BigNumber(await strategy.estimatedTotalAssets());
        const redeemTx = await mockVault.redeem(strategy.address, estimatedTotalAssets0, outputCode);
        expectEvent.inTransaction(redeemTx,'Repay');
        const estimatedTotalAssets1 = new BigNumber(await strategy.estimatedTotalAssets());
        console.log('After withdraw all shares,strategy assets:%d', estimatedTotalAssets1);
        assert.isTrue(estimatedTotalAssets1.multipliedBy(10000).isLessThan(depositETH), 'assets left in strategy should not be more than 1/10000');
    });

    let withdrawETH = new BigNumber(0);
    it('[the value of wants returned should increase]', async function () {
        for (let want of wants) {
            let balance = new BigNumber(await balanceOf(want, mockVault.address));
            if (want === MFC.ETH_ADDRESS) {
                withdrawETH = withdrawETH.plus(balance);
            } else {
                let eth = new BigNumber(await priceOracleConsumer.valueInEth(want, balance));
                withdrawETH = withdrawETH.plus(eth);
            }
        }
        withdrawETH = new BigNumber(ethers.utils.formatEther(withdrawETH.toFixed()));
        console.log('depositETH:%s, withdrawETH:%s', depositETH.toFixed(), withdrawETH.toFixed());
        assert(withdrawETH.isGreaterThan(depositETH), 'the value of wants user got do not increase');
    });
}

module.exports = {
    check,
};
