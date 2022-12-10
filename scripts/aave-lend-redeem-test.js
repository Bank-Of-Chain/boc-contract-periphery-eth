const {getDefaultProvider, Contract} = require('ethers');
const { default: BigNumber } = require('bignumber.js');
// const {vaultABI} = require ('./vault-abi.json');
const {reportOracle} = require('./mock-lidoOracle');

const {
    topUpUsdtByAddress,
    topUpWETHByAddress,
    topUpWstEthByAddress,
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
const EulerRevolvingLoanStrategy = hre.artifacts.require('EulerRevolvingLoanStrategy');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');

const {
    wstETH_ADDRESS,
    WETH_ADDRESS,
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
    const wethAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpWETHByAddress(wethAmount, ethiVaultAddress);
    const wstethAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpWstEthByAddress(wstethAmount, ethiVaultAddress);
    console.log(`top up successfully`);

    // const eulerRevolvingLoanStrategyContract = await EulerRevolvingLoanStrategy.at('0xFCFE742e19790Dd67a627875ef8b45F17DB1DaC6');
    // const eulContract = await ERC20.at('0xd9fcd98c322942075a5c3860693e9f4f03aae07b');
    //
    // console.log("before claim",(await eulContract.balanceOf('0xDb29eC3Fb265A03943bfEdBDF4eE9D9867B368e8')).toString());
    //
    // await eulerRevolvingLoanStrategyContract.claim('0xDb29eC3Fb265A03943bfEdBDF4eE9D9867B368e8','0xd9fcd98c322942075a5c3860693e9f4f03aae07b',new BigNumber('497785343330298145256'),['0x400b9b2297978587c1cd5b4fadcf3178b9877480136ea2636fbabfa4fb9f0927',
    //     '0x9b470c59b050d69b9d2771a7aca9b67e7af7b790f2a92da06b44e54dd5f2652c',
    //     '0x2cd60e7b560ab7ef045ee8288b58ca5d138cb98b5258d066c3c7f9af75f5df5c',
    //     '0x7f0b3b6e90ca7d5be8f37b42a9383823d9fec3ce09c33e53ea619f4deeecbbf2',
    //     '0x5506bc91b352a144b03569a87cabe11e5d97b9b045b04544fa673cdf2a3859c0',
    //     '0x1c4aae302076285a9ecfb90c3545c948c731ac81a122c826c40187ca85d71fa7',
    //     '0xff184685dfff8643cf01e4a60e9dca04acd2398fd491959af7651360e1e7d9fb',
    //     '0x77429b1acf8f45b202b02688fa794e4b98e286b997d7ac283bf50102b10f4e31',
    //     '0x802bda5b2f51bce02f877c1adff1908e9a8ec1cc34a088f9bc9e1c84517366e7',
    //     '0x8066296b3da0d977260df342e43a37cde13732861d2a2fa9262de66154fe7c88',
    //     '0xd058a4936c3526b77c03713d54004e63a0ea91121228898e562104fe26759a3a',
    //     '0xe7ec33504f89c1a4530a01ded0b1804ff4232d9e985470afce1b4a5c2c7a7a9d',
    //     '0x6574e63efc4f82be8fb41a0f48740b41d7bd2ef6fb24915cd2d5aab3f72a3c68'],'0x0000000000000000000000000000000000000000');
    //
    // console.log("after claim",(await eulContract.balanceOf('0xDb29eC3Fb265A03943bfEdBDF4eE9D9867B368e8')).toString());

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

    let tokens = [USDC_ADDRESS];
    let amounts = [usdcAmount.dividedBy(2).toFixed()];

    let strategyAddress = '0xbe18A1B61ceaF59aEB6A9bC81AB4FB87D56Ba167';
    let estimationGas;

    let vaultContract = await IVault.at(vaultAddress);
    let  tx;
    for(let i = 0; i < 30; i++){
        console.log("USDC",i);
        estimationGas = await vaultContract.lend.estimateGas(strategyAddress, tokens, amounts,{from:keeper});
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

    tokens = [DAI_ADDRESS];
    amounts = [daiAmount.dividedBy(2).toFixed()];

    strategyAddress = '0xFCFE742e19790Dd67a627875ef8b45F17DB1DaC6';
    for(let i = 0; i < 30; i++){
        console.log("DAI",i);
        estimationGas = await vaultContract.lend.estimateGas(strategyAddress, exchangeTokens);
        tx = await vaultContract.lend(strategyAddress, tokens, amounts,{gas:4000000,from:keeper});
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

    tokens = [USDT_ADDRESS];
    amounts = [usdtAmount.dividedBy(2).toFixed()];

    strategyAddress = '0x398E4948e373Db819606A459456176D31C3B1F91';
    for(let i = 0; i < 30; i++){
        console.log("USDT",i);
        estimationGas = await vaultContract.lend.estimateGas(strategyAddress, exchangeTokens);
        tx = await vaultContract.lend(strategyAddress, tokens, amounts,{gas:4000000,from:keeper});
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

    tokens = [WETH_ADDRESS];
    amounts = [wethAmount.dividedBy(2).toFixed()];
    strategyAddress = '0x4f42528B7bF8Da96516bECb22c1c6f53a8Ac7312';
    const ethiVaultContract = await IVault.at(ethiVaultAddress);
    const wethContract = await ERC20.at(WETH_ADDRESS);
    console.log("ethiVaultContract weth=",(await wethContract.balanceOf(ethiVaultContract.address)).toString());
    for(let i = 0; i < 30; i++){
        console.log("WETH",i);
        estimationGas = await ethiVaultContract.lend.estimateGas(strategyAddress, exchangeTokens);
        tx = await ethiVaultContract.lend(strategyAddress, tokens, amounts,{gas:4000000,from:keeper});
        console.log("WETH lend estimationGas=",estimationGas.toString());
        console.log("WETH lend gasUsed=",tx.receipt.gasUsed);
        console.log("WETH lend estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
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
        console.log("WETH redeem estimationGas=",estimationGas.toString());
        console.log("WETH redeem gasUsed=",tx.receipt.gasUsed);
        console.log("WETH redeem estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
    }

    tokens = [wstETH_ADDRESS];
    amounts = [wstethAmount.dividedBy(2).toFixed()];
    strategyAddress = '0x8f119cd256a0FfFeed643E830ADCD9767a1d517F';

    for(let i = 0; i < 30; i++){
        console.log("WstETH",i);
        estimationGas = await ethiVaultContract.lend.estimateGas(strategyAddress, exchangeTokens);
        tx = await ethiVaultContract.lend(strategyAddress, tokens, amounts,{gas:4000000,from:keeper});
        console.log("WstETH lend estimationGas=",estimationGas.toString());
        console.log("WstETH lend gasUsed=",tx.receipt.gasUsed);
        console.log("WstETH lend estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
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
        console.log("WstETH redeem estimationGas=",estimationGas.toString());
        console.log("WstETH redeem gasUsed=",tx.receipt.gasUsed);
        console.log("WstETH redeem estimationGas/gasUsed",new BigNumber(tx.receipt.gasUsed.toString()).multipliedBy(1000).div( new BigNumber(estimationGas.toString())).toFixed());
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
