const {
    ethers
} = require('hardhat');

const BigNumber = require('bignumber.js');
const {
    isEmpty,
    get,
    reduce,
    keys,
    includes,
    isEqual
} = require('lodash');
const inquirer = require('inquirer');

const MFC_TEST = require('../config/mainnet-fork-test-config');
const MFC_PRODUCTION = require('../config/mainnet-fork-config');

// === Utils === //
const ChainlinkPriceFeedContract = hre.artifacts.require("ChainlinkPriceFeed");

const main = async () => {

    const network = hre.network.name;
    const accounts = await ethers.getSigners();
    console.log('\n\n 📡 Deploying... At %s Network \n', network);
    assert(accounts.length > 0, 'Need a Signer!');
    const balanceBeforeDeploy = await ethers.provider.getBalance(accounts[0].address);
    const governor = accounts[0].address;
    const delegator = process.env.DELEGATOR_ADDRESS || get(accounts, '16.address', '');
    const vaultManager = process.env.VAULT_MANAGER_ADDRESS || get(accounts, '17.address', '');
    const keeper = process.env.KEEPER_ACCOUNT_ADDRESS || get(accounts, '18.address', '');
    console.log('governor address:%s', governor);
    console.log('delegator address:%s', delegator);
    console.log('vaultManager address:%s', vaultManager);
    console.log('usd keeper address:%s', keeper);

    const MFC = network === 'localhost' || network === 'hardhat' ? MFC_TEST : MFC_PRODUCTION

    const chainlinkPriceFeedContract = await ChainlinkPriceFeedContract.at('0xA92C91Fe965D7497A423d951fCDFA221fC354B5a');
    let primitives = new Array();
    let aggregators = new Array();
    let heartbeats = new Array();
    let rateAssets = new Array();

    const value = MFC.CHAINLINK.aggregators['STETH_ETH'];
    primitives.push(value.primitive);
    aggregators.push(value.aggregator);
    heartbeats.push(value.heartbeat);
    rateAssets.push(value.rateAsset);
    await chainlinkPriceFeedContract.addPrimitives(primitives, aggregators, heartbeats, rateAssets);
    console.log('chain link price feed add steth success');

    const balanceAfterDeploy = await ethers.provider.getBalance(accounts[0].address);
    console.log('balanceBeforeDeploy:%d,balanceAfterDeploy:%d', ethers.utils.formatEther(balanceBeforeDeploy), ethers.utils.formatEther(balanceAfterDeploy));
}

main().then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
