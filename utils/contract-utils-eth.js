/**
 * For use in test cases, the uniform initialization of contracts
 */

// === Constants === //
const BigNumber = require('bignumber.js');
const {
    map
} = require('lodash');

const MFC = require("../config/mainnet-fork-test-config");
const {
    strategiesList
} = require('../config/strategy-config-eth');

const {
    getStrategiesWants
} = require('./strategy-utils');
const {
    // impersonates,
    topUpDaiByAddress,
    topUpUsdtByAddress,
    topUpTusdByAddress,
    topUpUsdcByAddress,
    topUpBusdByAddress,
    // topUpTusdByAddress,
    // topUpPaxByAddress,
    // topUpLusdByAddress,
    topUpMimByAddress,
    topUpEthByAddress,
    topUpSTETHByAddress,
    topUpWETHByAddress,
    topUpRocketPoolEthByAddress,
    topUpWstEthByAddress,
    // topUpUsdpByAddress
} = require('./top-up-utils');

// === Core Contracts === //
// Access Control Proxy
const AccessControlProxy = hre.artifacts.require("AccessControlProxy");
const Vault = hre.artifacts.require("ETHVault");
const VaultBuffer = hre.artifacts.require("VaultBuffer");
const IVaultBuffer = hre.artifacts.require("IVaultBuffer");
const PegToken = hre.artifacts.require("PegToken");
const VaultAdmin = hre.artifacts.require("ETHVaultAdmin");
const IVault = hre.artifacts.require("IETHVault");
// Treasury
const Treasury = hre.artifacts.require('Treasury');
const ETHi = hre.artifacts.require("ETHi");
const ExchangeAggregator = hre.artifacts.require('ExchangeAggregator');
const EthOneInchV4Adapter = hre.artifacts.require('OneInchV4Adapter');
const EthParaSwapV5Adapter = hre.artifacts.require('ParaSwapV5Adapter');

const IExchangeAdapter = hre.artifacts.require('IExchangeAdapter');
const PriceOracle = hre.artifacts.require('PriceOracle');
const TestAdapter = hre.artifacts.require("contracts/exchanges/adapters/TestAdapter.sol:TestAdapter");
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');

/**
 * Initializing vault contracts
 * @param {string} underlyingAddress
 * @param {string} keeper
 * @returns
 */
async function setupCoreProtocol(underlyingAddress, governance, keeper, mock = true) {
    let vault = await Vault.new();
    const accessControlProxy = await AccessControlProxy.new();
    accessControlProxy.initialize(governance, governance, vault.address, keeper);
    const governanceOwner = governance;

    // 预言机
    console.log('deploy PriceOracle');
    const priceOracle = await PriceOracle.new();

    const testAdapter = await TestAdapter.new(priceOracle.address);

    console.log('deploy EthOneInchV4Adapter');
    const ethOneInchV4Adapter = await EthOneInchV4Adapter.new();

    console.log('deploy EthParaSwapV5Adapter');
    const ethParaSwapV5Adapter = await EthParaSwapV5Adapter.new();

    console.log('deploy ExchangeAggregator');
    let exchangeAggregator;
    if (mock) {
        exchangeAggregator = await ExchangeAggregator.new([testAdapter.address], accessControlProxy.address);
    } else {
        exchangeAggregator = await ExchangeAggregator.new([ethOneInchV4Adapter.address,ethParaSwapV5Adapter.address], accessControlProxy.address);
    }
    const adapters = await exchangeAggregator.getExchangeAdapters();
    let exchangePlatformAdapters = {};
    for (let i = 0; i < adapters.identifiers_.length; i++) {
        exchangePlatformAdapters[adapters.identifiers_[i]] = adapters.exchangeAdapters_[i];
    }

    const pegToken = await PegToken.new();
    await pegToken.initialize("ETH Peg Token", "ETHi", 18, vault.address, accessControlProxy.address)

    // treasury
    const treasury = await Treasury.new();
    await treasury.initialize(accessControlProxy.address);

    // VaultBuffer
    const vaultBuffer = await VaultBuffer.new();
    await vaultBuffer.initialize('ETH Peg Token Ticket', 'tETHi',vault.address,pegToken.address,accessControlProxy.address);

    await vault.initialize(accessControlProxy.address, treasury.address, exchangeAggregator.address, priceOracle.address);

    const vaultAdmin = await VaultAdmin.new();
    await vault.setAdminImpl(vaultAdmin.address, {from: governance});

    vault = await IVault.at(vault.address);
    await vault.setPegTokenAddress(pegToken.address);
    await vault.setVaultBufferAddress(vaultBuffer.address);

    await vault.addAsset(underlyingAddress);
    //20%
    await vault.setTrusteeFeeBps(2000, {from: governance});
    await vault.setRedeemFeeBps(0, {from: governance});

    let addToVaultStrategies = new Array();
    let withdrawQueque = new Array();
    for (let i = 0; i < strategiesList.length; i++) {
        let strategyItem = strategiesList[i];
        let contractArtifact = hre.artifacts.require(strategyItem.name);
        let strategy = await contractArtifact.new();
        await strategy.initialize(vault.address);
        withdrawQueque.push(strategy.address);
        addToVaultStrategies.push({
            strategy: strategy.address,
            profitLimitRatio: strategyItem['profitLimitRatio'],
            lossLimitRatio: strategyItem['lossLimitRatio']
        });
    }
    //add to vault
    await vault.addStrategy(addToVaultStrategies, {
        from: governanceOwner
    });
    await vault.setWithdrawalQueue(withdrawQueque);
    console.log('addStrategy ok');

    // If it is a test vault then top up the testAdapter with more wants coins to simulate the exchange operation of the vault
    console.log("This vault is a test vault and is being recharged for testAdapter....");
    const wants = await getStrategiesWants(vault.address);
    if (wants.indexOf(MFC.ETH_ADDRESS) === -1) {
        const amount = new BigNumber(1e18).multipliedBy(4000);
        await topUpETHByAddress(amount, testAdapter.address);
    }
    for (const want of wants) {
        let decimals;
        if (want === MFC.ETH_ADDRESS) {
            decimals = new BigNumber(18);
        } else {
            const token = await ERC20.at(want);
            decimals = await token.decimals();
        }

        const amount = new BigNumber(10).pow(decimals).multipliedBy(4000);
        if (want === MFC.ETH_ADDRESS) {
            await topUpEthByAddress(amount, testAdapter.address);
        } else if (want === MFC.stETH_ADDRESS) {
            await topUpSTETHByAddress(amount, testAdapter.address);
        } else if (want === MFC.WETH_ADDRESS) {
            await topUpWETHByAddress(amount, testAdapter.address);
        } else if (want === MFC.rocketPoolETH_ADDRESS) {
            await topUpRocketPoolEthByAddress(amount, testAdapter.address);
        } else if (want === MFC.wstETH_ADDRESS) {
            await topUpWstEthByAddress(amount, testAdapter.address);
        } else {
            console.log(`WARN:Failed to top up testAdapter with enough [${want}] coins`)
        }
    }

    return {
        vault,
        vaultBuffer,
        pegToken,
        treasury,
        priceOracle,
        exchangePlatformAdapters,
        addToVaultStrategies,
        exchangeAggregator
    }
}


async function impersonates(targetAccounts) {
    for (i = 0; i < targetAccounts.length; i++) {
        await hre.network.provider.request({
            method: 'hardhat_impersonateAccount',
            params: [targetAccounts[i]],
        });
    }
}

const getTokenBalance = async (contractAddress, tokenArray) => {
    const promiseArray = tokenArray.map(async (item) => {
        const cst = await IERC20.at(item);
        return Promise.all([cst.name(), cst.balanceOf(contractAddress).then(v => v.toString())]);
    });

    return Promise.all(promiseArray);
}

const getExchangePlatformAdapters = async (exchangeAggregator) => {
    const adapters = await exchangeAggregator.getExchangeAdapters();
    const exchangePlatformAdapters = {};
    for (let i = 0; i < adapters.identifiers_.length; i++) {
        exchangePlatformAdapters[adapters.identifiers_[i]] = adapters.exchangeAdapters_[i];
    }
    return exchangePlatformAdapters;
}

module.exports = {
    setupCoreProtocol,
    impersonates,
    getTokenBalance,
    getExchangePlatformAdapters,
};
