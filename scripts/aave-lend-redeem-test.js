const {getDefaultProvider, Contract} = require('ethers');
const { default: BigNumber } = require('bignumber.js');
// const {vaultABI} = require ('./vault-abi.json');
const {reportOracle} = require('./mock-lidoOracle');

const {
    topUpUsdtByAddress,
    topUpUsdcByAddress,
    topUpDaiByAddress,
    topUpLusdByAddress,
    topUpUsdpByAddress,
    topUpMimByAddress,
    topUpBusdByAddress, topUpEthByAddress
} = require('../utils/top-up-utils');

const IVault = hre.artifacts.require('boc-contract-core/contracts/vault/IVault.sol:IVault');
const IStrategy = hre.artifacts.require('IStrategy');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');

const {
    ETH_ADDRESS,
    USDT_ADDRESS,
    USDC_ADDRESS,
    DAI_ADDRESS,
} = require('../config/mainnet-fork-test-config');
const {balance} = require("@openzeppelin/test-helpers");

const vaultAddress = '0x30D120f80D60E7b58CA9fFaf1aaB1815f000B7c3';
const ethiVaultAddress = '0x8f0Cb368C63fbEDF7a90E43fE50F7eb8B9411746';

async function getStrategies() {
    // Connect to the network
    // const provider = getDefaultProvider("http://localhost:8545");
    // console.log('vaultContract.provider===', provider);
    //
    // // When use the provider to connect to a contract, only have read permission for the contract
    // const {contract: vaultContract} = new Contract(vaultAddress, vaultABI, provider);
    const vaultContract = await IVault.at(vaultAddress);
    console.log('vaultContract.address===', vaultContract.address);
    const strategyArr = await vaultContract.getStrategies();

    for (const s of strategyArr) {
        console.log('strategy name:%s', s);
    }
    return strategyArr;
}

const main = async () => {
    const network = hre.network.name;
    console.log('\n\n 📡 simple lend ... At %s Network \n', network);
    if (network !== 'localhost') {
        return;
    }

    const accounts = await ethers.getSigners();
    const investor = accounts[0].address;
    const keeper = accounts[0].address;
    //
    // top up
    const ethAmount = new BigNumber(10 * 10 ** 18);
    await topUpEthByAddress(ethAmount.multipliedBy(5), investor);
    await topUpEthByAddress(ethAmount.multipliedBy(2), ethiVaultAddress);
    const usdtAmount = new BigNumber(1000_000 * 10 ** 6);
    await topUpUsdtByAddress(usdtAmount, vaultAddress);
    const usdcAmount = new BigNumber(1000_000 * 10 ** 6);
    await topUpUsdcByAddress(usdcAmount, vaultAddress);
    const daiAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpDaiByAddress(daiAmount, vaultAddress);
    const lusdAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpLusdByAddress(lusdAmount, vaultAddress);
    const usdpAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpUsdpByAddress(usdpAmount, vaultAddress);
    const mimAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpMimByAddress(mimAmount, vaultAddress);
    const busdAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpBusdByAddress(busdAmount, vaultAddress);
    console.log(`top up successfully`);

    let exchangeToken = {fromToken: USDC_ADDRESS,toToken: USDC_ADDRESS,fromAmount: usdcAmount.dividedBy(2).toFixed(),exchangeParam: {
            platform: '0xe3a66514B6e0aFa08aC98607D3d7eC6B8bACd6D5',
            method: 0,
            encodeExchangeArgs: "0x",
            slippage: 0,
            oracleAdditionalSlippage: 0,
        } }

    let exchangeTokens = [exchangeToken];

    let strategyAddress = '0xd753c12650c280383Ce873Cc3a898F6f53973d16';
    let estimationGas;

    let vaultContract = await IVault.at(vaultAddress);
    let  tx;
    for(let i = 0; i < 30; i++){
        console.log("USDC",i);
        estimationGas = await vaultContract.lend.estimateGas(strategyAddress, exchangeTokens);
        tx =  await vaultContract.lend(strategyAddress, exchangeTokens,{gas:4000000,from:keeper});
        console.log("USDC lend estimationGas=",estimationGas.toString());
        console.log("USDC lend gasUsed=",tx.receipt.gasUsed);
        console.log("USDC lend estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
        await reportOracle(1,60);
        const state = await vaultContract.strategies(strategyAddress,{from:keeper});
        const {
            lastReport,
            totalDebt,
            profitLimitRatio,
            lossLimitRatio,
            enforceChangeLimit,
        } = state
        estimationGas = await vaultContract.redeem.estimateGas(strategyAddress, totalDebt,0);
        tx =  await vaultContract.redeem(strategyAddress, totalDebt,0,{gas:new BigNumber(estimationGas.toString()).multipliedBy(120).dividedBy(100).toFixed(),from: keeper});
        console.log("USDC redeem estimationGas=",estimationGas.toString());
        console.log("USDC redeem gasUsed=",tx.receipt.gasUsed);
        console.log("USDC redeem estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
    }
    exchangeToken = {fromToken: DAI_ADDRESS,toToken: DAI_ADDRESS,fromAmount: daiAmount.dividedBy(2).toFixed(),exchangeParam: {
            platform: '0xe3a66514B6e0aFa08aC98607D3d7eC6B8bACd6D5',
            method: 0,
            encodeExchangeArgs: "0x",
            slippage: 0,
            oracleAdditionalSlippage: 0,
        } }
    exchangeTokens = [exchangeToken];
    strategyAddress = '0x10e38eE9dd4C549b61400Fc19347D00eD3edAfC4';
    for(let i = 0; i < 30; i++){
        console.log("DAI",i);
        estimationGas = await vaultContract.lend.estimateGas(strategyAddress, exchangeTokens);
        tx = await vaultContract.lend(strategyAddress, exchangeTokens,{gas:4000000,from:keeper});
        console.log("DAI lend estimationGas=",estimationGas.toString());
        console.log("DAI lend gasUsed=",tx.receipt.gasUsed);
        console.log("DAI lend estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
        await reportOracle(1,60);
        const state = await vaultContract.strategies(strategyAddress,{from:keeper});
        const {
            lastReport,
            totalDebt,
            profitLimitRatio,
            lossLimitRatio,
            enforceChangeLimit,
        } = state
        estimationGas = await vaultContract.redeem.estimateGas(strategyAddress, totalDebt,0);
        tx =  await vaultContract.redeem(strategyAddress, totalDebt,0,{gas:new BigNumber(estimationGas.toString()).multipliedBy(120).dividedBy(100).toFixed(),from: keeper});
        console.log("DAI redeem estimationGas=",estimationGas.toString());
        console.log("DAI redeem gasUsed=",tx.receipt.gasUsed);

        console.log("DAI redeem estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
    }
    exchangeToken = {fromToken: ETH_ADDRESS,toToken: ETH_ADDRESS,fromAmount: ethAmount.dividedBy(2).toFixed(),exchangeParam: {
            platform: '0xe3a66514B6e0aFa08aC98607D3d7eC6B8bACd6D5',
            method: 0,
            encodeExchangeArgs: "0x",
            slippage: 0,
            oracleAdditionalSlippage: 0,
        } }
    exchangeTokens = [exchangeToken];
    strategyAddress = '0x06b3244b086cecC40F1e5A826f736Ded68068a0F';
    const ethiVaultContract = await IVault.at(ethiVaultAddress);
    const beforeBalance = await balance.current(ethiVaultContract.address)
    console.log("vault ethAmount",beforeBalance.toString());
    for(let i = 0; i < 30; i++){
        console.log("ETH",i);
        estimationGas = await ethiVaultContract.lend.estimateGas(strategyAddress, exchangeTokens);
        tx = await ethiVaultContract.lend(strategyAddress, exchangeTokens,{gas:4000000,from:keeper});
        console.log("ETH lend estimationGas=",estimationGas.toString());
        console.log("ETH lend gasUsed=",tx.receipt.gasUsed);
        console.log("ETH lend estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
        await reportOracle(1,60)
        const state = await ethiVaultContract.strategies(strategyAddress,{from:keeper});
        const {
            lastReport,
            totalDebt,
            profitLimitRatio,
            lossLimitRatio,
            enforceChangeLimit,
        } = state
        estimationGas = await ethiVaultContract.redeem.estimateGas(strategyAddress, totalDebt,0);
        tx =  await ethiVaultContract.redeem(strategyAddress, totalDebt,0,{gas:new BigNumber(estimationGas.toString()).multipliedBy(120).dividedBy(100).toFixed(),from: keeper});
        console.log("ETH redeem estimationGas=",estimationGas.toString());
        console.log("ETH redeem gasUsed=",tx.receipt.gasUsed);
        console.log("ETH redeem estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
