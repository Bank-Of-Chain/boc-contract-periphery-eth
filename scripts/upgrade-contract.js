
const { upgrades, ethers } = require("hardhat");

const pendingUpgradesInfo = [
    //AuraWstETHWETHStrategy
    {
        contractAddress: '0xc3C283aCc2Cf4F2917d80D496bab373f7b97D0fd',
        contractArtifact: 'AuraWstETHWETHStrategy',
    },
    //AuraREthWEthStrategy
    {
        contractAddress: '0x34152B0eEf70423B51556e0DCA1b8d142b6EB0f9',
        contractArtifact: 'AuraREthWEthStrategy',
    },
    //Aura3PoolStrategy
    {
        contractAddress: '0xA51ED1D803B09f4d08226F9F91e6Dcc79ec0fEB7',
        contractArtifact: 'Aura3PoolStrategy',
    }
]

const main = async () => {
    let network = hre.network.name;
    console.log('upgrade contract on network-%s', network);

    for (const contractInfo of pendingUpgradesInfo) {
        const contractArtifact = await ethers.getContractFactory(contractInfo.contractArtifact);
        const contractInstantiation = hre.artifacts.require(contractInfo.contractArtifact);
        const instantContract = await contractInstantiation.at(contractInfo.contractAddress);
        console.log('contract %s upgrade,current version:%s', contractInfo.contractArtifact, await instantContract.getVersion());
        let upgraded = await upgrades.upgradeProxy(contractInfo.contractAddress, contractArtifact);

        console.log('after upgrade instantiation version:%s', await instantContract.getVersion());
    }

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });