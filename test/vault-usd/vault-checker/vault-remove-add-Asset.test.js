/**
 * Vault rule：
 * 1. remove asset
 * 2. add asset
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
const {strategiesList} = require('../../../config/strategy-use/strategy-config-usd');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');


describe('【Vault unit test-add/remove asset】', function () {
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

    it('verify：Vault can remove all asset', async function () {
        let assetAddresses = await vault.getSupportAssets();
        for (let assetAdd of assetAddresses) {
            console.log('start remove asset of %s', assetAdd);
            await vault.removeAsset(assetAdd, {from: governance});
        }

        const length = (await vault.getSupportAssets()).length;
        console.log('count of all asset=', length);
        Utils.assertBNEq(length, 0);
    });

    it('verify：Vault can re-add asset', async function () {
        await vault.addAsset(MFC.USDT_ADDRESS, {from: governance});
        await vault.addAsset(MFC.USDC_ADDRESS, {from: governance});
        let length = (await vault.getSupportAssets()).length;
        console.log('strategyNum:%d,strategiesList.length', length, strategiesList.length);
        Utils.assertBNEq(length, 2);
    });

});
