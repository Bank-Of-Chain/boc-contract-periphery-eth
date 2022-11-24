const { upgrades, ethers } = require("hardhat");

const main = async () => {
    let network = hre.network.name;
    console.log('upgrade contract on network-%s', network);
    const ETHAaveStrategy = hre.artifacts.require('AaveWETHstETHStrategy');
    const ethAaveStrategyArtifacts = await ethers.getContractFactory('AaveWETHstETHStrategy');

    //AaveWETHstETHStrategy
    let ethAaveStrategyProxyAddr = '0x70C0E1B334124C7d46fC0c7a9048A802ab4C39C6';
    let ethAaveStrategyContract = await ETHAaveStrategy.at(ethAaveStrategyProxyAddr);
    await upgrades.upgradeProxy(ethAaveStrategyContract, ethAaveStrategyArtifacts);
    console.log('contract %s upgrade success,version:%s',(await ethAaveStrategyContract.name()).toString(), (await ethAaveStrategyContract.getVersion()).toString());
    console.log('before setBorrowCount ');
    console.log('leverage:%s',(await ethAaveStrategyContract.leverage()).toString());
    console.log('leverageMax:%s',(await ethAaveStrategyContract.leverageMax()).toString());
    console.log('leverageMin:%s',(await ethAaveStrategyContract.leverageMin()).toString());
    await ethAaveStrategyContract.setBorrowCount(3);
    console.log('after setBorrowCount ');
    console.log('leverage:%s',(await ethAaveStrategyContract.leverage()).toString());
    console.log('leverageMax:%s',(await ethAaveStrategyContract.leverageMax()).toString());
    console.log('leverageMin:%s',(await ethAaveStrategyContract.leverageMin()).toString());

    const USDAaveStrategy = hre.artifacts.require('AaveLendingStEthStrategy');
    const usdAaveStrategyArtifacts = await ethers.getContractFactory('AaveLendingStEthStrategy');

    //AaveDaiLendingStEthStrategy
    let usdAaveStrategyProxyAddr = '0x71298672cE73b85e06E0504C88A9A9f0c9dF3b9f';
    let usdAaveStrategyContract = await USDAaveStrategy.at(usdAaveStrategyProxyAddr);
    await upgrades.upgradeProxy(usdAaveStrategyContract, usdAaveStrategyArtifacts);
    console.log('contract %s upgrade success,version:%s',(await usdAaveStrategyContract.name()).toString(), (await usdAaveStrategyContract.getVersion()).toString());
    console.log('before setBorrowCount ');
    console.log('leverage:%s',(await usdAaveStrategyContract.leverage()).toString());
    console.log('leverageMax:%s',(await usdAaveStrategyContract.leverageMax()).toString());
    console.log('leverageMin:%s',(await usdAaveStrategyContract.leverageMin()).toString());
    await usdAaveStrategyContract.setBorrowCount(3);
    console.log('after setBorrowCount ');
    console.log('leverage:%s',(await usdAaveStrategyContract.leverage()).toString());
    console.log('leverageMax:%s',(await usdAaveStrategyContract.leverageMax()).toString());
    console.log('leverageMin:%s',(await usdAaveStrategyContract.leverageMin()).toString());

    //AaveUSDCLendingStEthStrategy
    usdAaveStrategyProxyAddr = '0xaEC8046c9d8F6f85F3b92B63594fAD3C4c929A6b';
    usdAaveStrategyContract = await USDAaveStrategy.at(usdAaveStrategyProxyAddr);
    await upgrades.upgradeProxy(usdAaveStrategyContract, usdAaveStrategyArtifacts);
    console.log('contract %s upgrade success,version:%s',(await usdAaveStrategyContract.name()).toString(), (await usdAaveStrategyContract.getVersion()).toString());
    console.log('before setBorrowCount ');
    console.log('leverage:%s',(await usdAaveStrategyContract.leverage()).toString());
    console.log('leverageMax:%s',(await usdAaveStrategyContract.leverageMax()).toString());
    console.log('leverageMin:%s',(await usdAaveStrategyContract.leverageMin()).toString());
    await usdAaveStrategyContract.setBorrowCount(3);
    console.log('after setBorrowCount ');
    console.log('leverage:%s',(await usdAaveStrategyContract.leverage()).toString());
    console.log('leverageMax:%s',(await usdAaveStrategyContract.leverageMax()).toString());
    console.log('leverageMin:%s',(await usdAaveStrategyContract.leverageMin()).toString());

    console.log('=========contract upgrade completed==========');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });