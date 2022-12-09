const { upgrades, ethers } = require("hardhat");
const {default: BigNumber} = require("bignumber.js");

const IStrategy = hre.artifacts.require('IStrategy');

const pendingUpgradesInfo = [
    //Vault
    {
        vaultAddress: '0x30D120f80D60E7b58CA9fFaf1aaB1815f000B7c3',
        vaultArtifact: 'Vault',
        vaultAdminArtifact: 'VaultAdmin',
        iValut: 'IVault'
    },
    //ETHVault
    {
        vaultAddress: '0x8f0Cb368C63fbEDF7a90E43fE50F7eb8B9411746',
        vaultArtifact: 'ETHVault',
        vaultAdminArtifact: 'ETHVaultAdmin',
        iValut: 'IETHVault'
    }
]

const main = async () => {
    let network = hre.network.name;
    console.log('upgrade contract on network-%s', network);

    //OneInchV4Adapter   '0xe3a66514B6e0aFa08aC98607D3d7eC6B8bACd6D5'
    //ParaSwapV5Adapter  '0x9a020e23814be9980D64357aE9aEa44Fc3f6A51f'
    //AccessControlProxy '0x94c0AA94Ef3aD19E3947e58a855636b38aDe53e0'
    const adapterArray = ['0xe3a66514B6e0aFa08aC98607D3d7eC6B8bACd6D5', '0x9a020e23814be9980D64357aE9aEa44Fc3f6A51f'];
    const exchangeAggregatorArtifacts = await ethers.getContractFactory('ExchangeAggregator');
    const exchangeAggregatorContractArgs = [['0xe3a66514B6e0aFa08aC98607D3d7eC6B8bACd6D5', '0x9a020e23814be9980D64357aE9aEa44Fc3f6A51f'],'0x94c0AA94Ef3aD19E3947e58a855636b38aDe53e0'];
    const exchangeAggregatorOverrides = {};
    console.log('stat deploy ExchangeAggregator');
    const exchangeAggregatorConstract = await exchangeAggregatorArtifacts.deploy(...exchangeAggregatorContractArgs, exchangeAggregatorOverrides);
    console.log(`ExchangeAggregatordeployed, address=`, exchangeAggregatorConstract.address);

    for (const contractInfo of pendingUpgradesInfo) {
        const contractArtifact = await ethers.getContractFactory(contractInfo.vaultArtifact);
        const contractInstantiation = hre.artifacts.require(contractInfo.vaultArtifact);
        const vaultContract = await contractInstantiation.at(contractInfo.vaultAddress);
        console.log('contract %s upgrade,current version:%s',contractInfo.vaultArtifact,await vaultContract.getVersion());
        let upgraded = await upgrades.upgradeProxy(contractInfo.vaultAddress, contractArtifact);

        console.log('after upgrade instantiation version:%s',await vaultContract.getVersion());

        const adminArtifacts = await ethers.getContractFactory(contractInfo.vaultAdminArtifact);
        console.log('stat deploy ',contractInfo.vaultAdminArtifact);
        const contractArgs = [];
        const overrides = {};
        const constract = await adminArtifacts.deploy(...contractArgs, overrides);
        console.log(`${contractInfo.vaultAdminArtifact} deployed, address=`, constract.address);
        console.log('stat setAdminImpl');
        await vaultContract.setAdminImpl(constract.address);
        console.log('completed setAdminImpl');
        const IVault= hre.artifacts.require(contractInfo.iValut);
        const iVault = await IVault.at(contractInfo.vaultAddress);
        console.log("old exchangeManager = ",await iVault.exchangeManager());
        await iVault.setExchangeManagerAddress(exchangeAggregatorConstract.address);
        console.log("new exchangeManager = ",await iVault.exchangeManager());
    }

    console.log('=========contract upgrade completed==========');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });