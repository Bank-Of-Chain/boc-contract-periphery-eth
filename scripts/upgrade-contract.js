
const { upgrades, ethers } = require("hardhat");

const stakewiseStrategyProxyAddr = '0xE933639733c212265Ed7a243A061e705D0410CA5';
const StakeWiseEthSeth23000Strategy = hre.artifacts.require('StakeWiseEthSeth23000Strategy');

const main = async () => {
    let network = hre.network.name;
    console.log('upgrade contract on network-%s', network);

    const accounts = await ethers.getSigners();
    const governance = accounts[0].address;

    // 升级StakeWiseEthSeth23000Strategy合约
    const stakeWiseEthSeth23000StrategyContract = await StakeWiseEthSeth23000Strategy.at(stakewiseStrategyProxyAddr);
    const stakewiseStrategyArtifacts = await ethers.getContractFactory('StakeWiseEthSeth23000Strategy');
    let upgraded = await upgrades.upgradeProxy(stakewiseStrategyProxyAddr, stakewiseStrategyArtifacts);
    let statusInfo = await stakeWiseEthSeth23000StrategyContract.getStatus();
    console.log('contract upgrade success,before baseThreshold:%s', statusInfo._baseThreshold.toString());
    await stakeWiseEthSeth23000StrategyContract.setBaseThreshold(0,{from: governance});
    statusInfo = await stakeWiseEthSeth23000StrategyContract.getStatus();
    console.log('contract upgrade success,after baseThreshold:%s', statusInfo._baseThreshold.toString());
    console.log('=========contract 升级完成==========');
    await stakeWiseEthSeth23000StrategyContract.rebalanceByKeeper({from: governance});
    console.log('=========rebalanceByKeeper 完成==========');

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });