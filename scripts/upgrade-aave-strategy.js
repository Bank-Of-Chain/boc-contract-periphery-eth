const { upgrades, ethers } = require("hardhat");

const pendingUpgradesInfo = [
    //AaveWETHstETHStrategy
    {
        strategyAddress: '0x70C0E1B334124C7d46fC0c7a9048A802ab4C39C6',
        strategyArtifact: 'AaveWETHstETHStrategy'
    },
    //AaveDaiLendingStEthStrategy
    {
        strategyAddress: '0x71298672cE73b85e06E0504C88A9A9f0c9dF3b9f',
        strategyArtifact: 'AaveLendingStEthStrategy'
    },
    //AaveUSDCLendingStEthStrategy
    {
        strategyAddress: '0xaEC8046c9d8F6f85F3b92B63594fAD3C4c929A6b',
        strategyArtifact: 'AaveLendingStEthStrategy'
    }
]

const main = async () => {
    let network = hre.network.name;
    console.log('upgrade contract on network-%s', network);

    for (const strategyInfo of pendingUpgradesInfo) {
        const strategyArtifacts = await ethers.getContractFactory(strategyInfo.strategyArtifact);
        const strategyContract = hre.artifacts.require(strategyInfo.strategyArtifact);
        const strategy = await strategyContract.at(strategyInfo.strategyAddress);
        console.log('contract %s upgrade,current version:%s',await strategy.name(),await strategy.getVersion());
        let upgraded = await upgrades.upgradeProxy(strategyInfo.strategyAddress, strategyArtifacts);
        console.log('after upgrade strategy version:%s',await strategy.getVersion());
        console.log('before setBorrowCount ');
        console.log('borrowCount:%s',(await strategy.borrowCount()).toString());
        console.log('leverage:%s',(await strategy.leverage()).toString());
        console.log('leverageMax:%s',(await strategy.leverageMax()).toString());
        console.log('leverageMin:%s',(await strategy.leverageMin()).toString());
        await strategy.setBorrowCount((await strategy.borrowCount()).toString());
        console.log('after setBorrowCount ');
        console.log('borrowCount:%s',(await strategy.borrowCount()).toString());
        console.log('leverage:%s',(await strategy.leverage()).toString());
        console.log('leverageMax:%s',(await strategy.leverageMax()).toString());
        console.log('leverageMin:%s',(await strategy.leverageMin()).toString());
    }

    console.log('=========contract upgrade completed==========');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });