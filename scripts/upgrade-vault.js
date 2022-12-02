const { upgrades, ethers } = require("hardhat");
const {default: BigNumber} = require("bignumber.js");

const IStrategy = hre.artifacts.require('IStrategy');

const pendingUpgradesInfo = [
    //Vault
    {
        vaultAddress: '0x30D120f80D60E7b58CA9fFaf1aaB1815f000B7c3',
        vaultArtifact: 'Vault',
        vaultAdminArtifact: 'VaultAdmin'
    },
    //ETHVault
    {
        vaultAddress: '0x8f0Cb368C63fbEDF7a90E43fE50F7eb8B9411746',
        vaultArtifact: 'ETHVault',
        vaultAdminArtifact: 'ETHVaultAdmin'
    }
]

const main = async () => {
    let network = hre.network.name;
    console.log('upgrade contract on network-%s', network);

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

        // //Fork
        // if (network == 'localhost'){
        //     const accounts = await ethers.getSigners();
        //     const keeper = accounts[19].address;
        //     const trackedValueBeforeRedeem = await vaultContract.valueOfTrackedTokens();
        //     const strategies = await vaultContract.getStrategies();
        //     await vaultContract.reportByKeeper(strategies,{from: keeper});
        //     for (let i = 0;i < strategies.length;i++) {
        //         let strategyAddr = strategies[i];
        //         let strategy = await IStrategy.at(strategyAddr);
        //         await strategy.harvest();
        //         console.log('strategy %s (lastReport,totalDebt,profitLimitRatio,lossLimitRatio,enforceChangeLimit,lastClaim)=',await strategy.name());
        //         let strategyInfo = await vaultContract.strategies(strategyAddr);
        //         console.log(strategyInfo.lastReport.toString(),strategyInfo.totalDebt.toString(),strategyInfo.profitLimitRatio.toString(),strategyInfo.lossLimitRatio.toString(),strategyInfo.enforceChangeLimit.toString(),strategyInfo.lastClaim.toString());
        //         if (strategyInfo.totalDebt > 1e16){
        //             const estimationGas = await vaultContract.redeem.estimateGas(strategyAddr,strategyInfo.totalDebt,0,{from: keeper});
        //             await vaultContract.redeem(strategyAddr,strategyInfo.totalDebt,0,{gas:new BigNumber(estimationGas.toString()).multipliedBy(120).dividedBy(100).toFixed(0,2)});
        //             console.log('redeem %s finish.',await strategy.name());
        //         }
        //     }
        //     const trackedValueAfterRedeem = await vaultContract.valueOfTrackedTokens();
        //     console.log('trackedValueBeforeRedeem:%d,trackedValueAfterRedeem:%d',trackedValueBeforeRedeem,trackedValueAfterRedeem);
        // }
    }

    console.log('=========contract upgrade completed==========');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });