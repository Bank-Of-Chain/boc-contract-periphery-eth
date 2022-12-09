/**
 * Vault Vault：
 * 1. force remove strategy
 * 2. add strategy
 */

const BigNumber = require('bignumber.js');
const {
    ethers,
} = require('hardhat');
const Utils = require('../../../utils/assert-utils');
const {
    getStrategyDetails,
} = require('../../../utils/strategy-utils');

const {
    setupCoreProtocol,
} = require('../../../utils/contract-utils-usd');
const {
    topUpUsdtByAddress,
    tranferBackUsdt,
} = require('../../../utils/top-up-utils');

// === Constants === //
const MFC = require('../../../config/mainnet-fork-test-config');
const {
	strategiesList
} = require('../../../config/strategy-usd/strategy-config-usd.js');
const IStrategy = hre.artifacts.require('IStrategy');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');


describe('【Vault unit test-add/remove strategy】', function () {
    // parties in the protocol
    let accounts;
    let governance;
    let farmer1;
    let keeper;
    let token;
    let tokenDecimals;
    let depositAmount

    // Core protocol contracts
    let vault;
    let underlying;
    let valueInterpreter;
    let exchangePlatformAdapters;
    let addToVaultStrategies;
    let farmer1Lp

    before(async function () {
        token = await ERC20.at(MFC.USDT_ADDRESS);
        tokenDecimals = new BigNumber(await token.decimals());
        depositAmount = new BigNumber(10).pow(tokenDecimals).multipliedBy(1000);
        await ethers.getSigners().then((resp) => {
            accounts = resp;
            governance = accounts[0].address;
            farmer1 = accounts[1].address;
            keeper = accounts[19].address;
        });
        await topUpUsdtByAddress(depositAmount, farmer1);
        await setupCoreProtocol(MFC.USDT_ADDRESS, governance, keeper).then((resp) => {
            vault = resp.vault;
            underlying = resp.underlying;
            valueInterpreter = resp.valueInterpreter;
            exchangePlatformAdapters = resp.exchangePlatformAdapters;
            addToVaultStrategies = resp.addToVaultStrategies;
        });
    });
    after(async function () {
        await tranferBackUsdt(farmer1);
    });

    it('verify：Vault can remove all strategies', async function () {
        let strategyAddresses = await vault.getStrategies();
        for (let strategyAdd of strategyAddresses) {
            let strategy = await IStrategy.at(strategyAdd);
            console.log('start remove strategy of %s', await strategy.name());
            await vault.forceRemoveStrategy(strategyAdd, {from: governance});
        }
        (await getStrategyDetails(vault.address)).log();
        const length = (await vault.getStrategies()).length
        console.log('count of all strategies=', length);
        Utils.assertBNEq(length, 0);
    });

    it('verify：Vault can re-add all strategies', async function () {
        let _arr = new Array();
        for (let item of addToVaultStrategies) {
            _arr.push({
                strategy: item['strategy'],
                profitLimitRatio: item['profitLimitRatio'],
                lossLimitRatio: item['lossLimitRatio']
            });
        }
        await vault.addStrategies(_arr, {from: governance});
        let strategyNum = (await vault.getStrategies()).length;
        console.log('strategyNum:%d,strategiesList.length', strategyNum, strategiesList.length);
        Utils.assertBNEq(strategyNum, strategiesList.length);
    });

});
