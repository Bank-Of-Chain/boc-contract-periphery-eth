const {getDefaultProvider, Contract} = require('ethers');
const { default: BigNumber } = require('bignumber.js');
const {vaultABI} = require ('./vault-abi.json');

const {
    topUpUsdtByAddress,
    topUpUsdcByAddress,
    topUpDaiByAddress,
    topUpLusdByAddress,
    topUpUsdpByAddress,
    topUpMimByAddress,
    topUpBusdByAddress
} = require('../utils/top-up-utils');

const IVault = hre.artifacts.require('boc-contract-core/contracts/vault/IVault.sol:IVault');
const IStrategy = hre.artifacts.require('IStrategy');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');

const {
    USDT_ADDRESS,
    USDC_ADDRESS,
    DAI_ADDRESS,
} = require('../config/mainnet-fork-test-config');
const vaultAddress = '0x9BcC604D4381C5b0Ad12Ff3Bf32bEdE063416BC7';

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
    const strategies = {};
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
    //
    // top up
    const usdtAmount = new BigNumber(1000_000 * 10 ** 6);
    await topUpUsdtByAddress(usdtAmount, investor);
    const usdcAmount = new BigNumber(1000_000 * 10 ** 6);
    await topUpUsdcByAddress(usdcAmount, investor);
    const daiAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpDaiByAddress(daiAmount, investor);
    const lusdAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpLusdByAddress(lusdAmount, investor);
    const usdpAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpUsdpByAddress(usdpAmount, investor);
    const mimAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpMimByAddress(mimAmount, investor);
    const busdAmount = new BigNumber(1000_000 * 10 ** 18);
    await topUpBusdByAddress(busdAmount, investor);
    console.log(`top up successfully`);

    // approve
    const usdtContract = await ERC20.at(USDT_ADDRESS);
    await usdtContract.approve(vaultAddress, usdtAmount);
    const usdcContract = await ERC20.at(USDC_ADDRESS);
    await usdcContract.approve(vaultAddress, usdcAmount);
    const daiContract = await ERC20.at(DAI_ADDRESS);
    await daiContract.approve(vaultAddress, daiAmount);
    console.log(`approve successfully`);

    // invest
    const bocVault = await IVault.at(vaultAddress);
    await bocVault.mint(
        [USDT_ADDRESS, USDC_ADDRESS, DAI_ADDRESS],
        [usdtAmount, usdcAmount, daiAmount],
        0, {
        from: investor
    });
    console.log(`invest vault ${vaultAddress} successfully`);
    const strategyAddresses = await bocVault.getStrategies();
    console.log('strategyAddresses', strategyAddresses);
    let amountPerToken = new BigNumber(1000);
    let amounts = [];
    for(let i = 0; i < strategyAddresses.length; i++) {
        let strategyAddress = strategyAddresses[i];
        const strategy = await IStrategy.at(strategyAddress);
        let exchangeTokens = [];
        const wantsInfo = await strategy.getWantsInfo();
        for (let j = 0; j < wantsInfo._assets.length; j++) {
            const asset = wantsInfo._assets[j];
            const assetContract = await ERC20.at(asset);
            const precision = new BigNumber(10 ** (await assetContract.decimals()));
            let amountString = amountPerToken.multipliedBy(precision);
            amounts.push(amountString.toFixed(0,2));
        }
        console.log('exchangeTokens===========', exchangeTokens);
        await bocVault.lend(strategyAddress, wantsInfo._assets, amounts);
        console.log(`invest strategy ${strategyAddress} successfully`);
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
