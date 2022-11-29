const {
    ethers,
    upgrades
} = require('hardhat');

const ConvexIBUsdtStrategy = hre.artifacts.require("ConvexIBUsdtStrategy");
const pendingToUpgrades = [
    '0x59b8149C11678392874d79c076f497dE9D522D0C',
    '0x18d9eFb0e5d4FB27f3c35C55801877b2143d44CF',
    '0x2e7967F36bd5E73705F2DCB8c338e53127003cF0',
    '0x76b639Ad828AeE35ff219e73adD6aB4D6C0d233d',
    '0x47141933B82B5472c1129CF07fb74007a75666B6',
    '0x990572d68e6576c19FCc35E4cf30324320372D13'
]

async function main() {
    const strategyArtifacts = await ethers.getContractFactory('ConvexIBUsdtStrategy');
    for (const strategyAddr of pendingToUpgrades) {
        const strategy = await ConvexIBUsdtStrategy.at(strategyAddr);
        console.log('upgrade %s,current version:%s',await strategy.name(),await strategy.getVersion());
        let upgraded = await upgrades.upgradeProxy(strategyAddr, strategyArtifacts);
        console.log('after upgrade strategy version:%s',await strategy.getVersion());
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });