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
const IDForcePriceOracle = hre.artifacts.require('IDForcePriceOracle');
const IDForceController = hre.artifacts.require('IDForceController');
const MockPriceModel = hre.artifacts.require('MockPriceModel');
const IStrategy = hre.artifacts.require('IStrategy');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');

const {
    ETH_ADDRESS,
    USDT_ADDRESS,
    USDC_ADDRESS,
    DAI_ADDRESS,
} = require('../config/mainnet-fork-test-config');
const {balance, send} = require("@openzeppelin/test-helpers");
const {ethers} = require("hardhat");

const vaultAddress = '0xc6B407503dE64956Ad3cF5Ab112cA4f56AA13517';
const ethiVaultAddress = '0xF6a8aD553b265405526030c2102fda2bDcdDC177';

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
    const keeper = accounts[19].address;
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

    // let priceOracle = await IDForcePriceOracle.at("0xb4De37b03f7AcE98FB795572B18aE3CFae85A628");
    // let _controller = await IDForceController.at("0x8B53Ab2c0Df3230EA327017C91Eb909f815Ad113");
    // // let oldPrice =  new BigNumber(await priceOracle.getUnderlyingPrice("0x2f956b2f801c6dad74E87E7f45c94f6283BF0f45"));
    // // const poster = '0x5c5bFFdB161E637B7f555CC122831126e02270d5';
    // const owner = '0x17e66B1e0260C930bfA567ff3ab5c71794279b94';
    // // mock owner
    // await ethers.getImpersonatedSigner(owner);
    // // const beforeBalance = await balance.current(owner);
    // await send.ether(accounts[0].address, owner, 10 * 10 ** 18);
    // await send.ether(accounts[0].address, keeper, 100 * 10 ** 18);
    //
    // const mockPriceModelAddress = '0xf5C3953Ae4639806fcbCC3196f71dd81B0da4348';
    //
    // const _alliTokens = await _controller.getAlliTokens();
    // for(let i=0;i<_alliTokens.length;i++){
    //     await priceOracle._setAssetPriceModel(_alliTokens[i],mockPriceModelAddress,{from: owner});
    // }

    let exchangeToken = {fromToken: USDC_ADDRESS,toToken: USDC_ADDRESS,fromAmount: usdcAmount.dividedBy(2).toFixed(),exchangeParam: {
            platform: '0xbf2ad38fd09F37f50f723E35dd84EEa1C282c5C9',
            method: 0,
            encodeExchangeArgs: "0x",
            slippage: 0,
            oracleAdditionalSlippage: 0,
        } }

    let exchangeTokens = [exchangeToken];

    let strategyAddress = '0xbe18A1B61ceaF59aEB6A9bC81AB4FB87D56Ba167';
    let estimationGas;

    let vaultContract = await IVault.at(vaultAddress);
    let  tx;
    for(let i = 0; i < 30; i++){
        console.log("USDC",i);
        estimationGas = await vaultContract.lend.estimateGas(strategyAddress, exchangeTokens,{from:keeper});
        tx =  await vaultContract.lend(strategyAddress, exchangeTokens,{gas:4000000,from:keeper});
        console.log("USDC lend estimationGas=",estimationGas.toString());
        console.log("USDC lend gasUsed=",tx.receipt.gasUsed);
        console.log("USDC lend estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
        await reportOracle(1,60);
        const state = await vaultContract.strategies(strategyAddress);
        const {
            lastReport,
            totalDebt,
            profitLimitRatio,
            lossLimitRatio,
            enforceChangeLimit,
        } = state
        estimationGas = await vaultContract.redeem.estimateGas(strategyAddress, totalDebt,0,{from:keeper});
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
    strategyAddress = '0xFCFE742e19790Dd67a627875ef8b45F17DB1DaC6';
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
    exchangeToken = {fromToken: USDT_ADDRESS,toToken: USDT_ADDRESS,fromAmount: usdtAmount.dividedBy(2).toFixed(),exchangeParam: {
            platform: '0xe3a66514B6e0aFa08aC98607D3d7eC6B8bACd6D5',
            method: 0,
            encodeExchangeArgs: "0x",
            slippage: 0,
            oracleAdditionalSlippage: 0,
        } }
    exchangeTokens = [exchangeToken];
    strategyAddress = '0x398E4948e373Db819606A459456176D31C3B1F91';
    for(let i = 0; i < 30; i++){
        console.log("USDT",i);
        estimationGas = await vaultContract.lend.estimateGas(strategyAddress, exchangeTokens);
        tx = await vaultContract.lend(strategyAddress, exchangeTokens,{gas:4000000,from:keeper});
        console.log("USDT lend estimationGas=",estimationGas.toString());
        console.log("USDT lend gasUsed=",tx.receipt.gasUsed);
        console.log("USDT lend estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
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
        console.log("USDT redeem estimationGas=",estimationGas.toString());
        console.log("USDT redeem gasUsed=",tx.receipt.gasUsed);

        console.log("USDT redeem estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
    }
    exchangeToken = {fromToken: ETH_ADDRESS,toToken: ETH_ADDRESS,fromAmount: ethAmount.dividedBy(2).toFixed(),exchangeParam: {
            platform: '0xe3a66514B6e0aFa08aC98607D3d7eC6B8bACd6D5',
            method: 0,
            encodeExchangeArgs: "0x",
            slippage: 0,
            oracleAdditionalSlippage: 0,
        } }
    // exchangeTokens = [exchangeToken];
    // strategyAddress = '0x06b3244b086cecC40F1e5A826f736Ded68068a0F';
    // const ethiVaultContract = await IVault.at(ethiVaultAddress);
    // const beforeBalance = await balance.current(ethiVaultContract.address)
    // console.log("vault ethAmount",beforeBalance.toString());
    // for(let i = 0; i < 30; i++){
    //     console.log("ETH",i);
    //     estimationGas = await ethiVaultContract.lend.estimateGas(strategyAddress, exchangeTokens);
    //     tx = await ethiVaultContract.lend(strategyAddress, exchangeTokens,{gas:4000000,from:keeper});
    //     console.log("ETH lend estimationGas=",estimationGas.toString());
    //     console.log("ETH lend gasUsed=",tx.receipt.gasUsed);
    //     console.log("ETH lend estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
    //     await reportOracle(1,60)
    //     const state = await ethiVaultContract.strategies(strategyAddress,{from:keeper});
    //     const {
    //         lastReport,
    //         totalDebt,
    //         profitLimitRatio,
    //         lossLimitRatio,
    //         enforceChangeLimit,
    //     } = state
    //     estimationGas = await ethiVaultContract.redeem.estimateGas(strategyAddress, totalDebt,0);
    //     tx =  await ethiVaultContract.redeem(strategyAddress, totalDebt,0,{gas:new BigNumber(estimationGas.toString()).multipliedBy(120).dividedBy(100).toFixed(),from: keeper});
    //     console.log("ETH redeem estimationGas=",estimationGas.toString());
    //     console.log("ETH redeem gasUsed=",tx.receipt.gasUsed);
    //     console.log("ETH redeem estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
    // }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
