const IVault = artifacts.require("IVault");
const Vault = artifacts.require("Vault");
const ConvexIronBankChfStrategy = artifacts.require("ConvexIronBankChfStrategy");


const main = async () => {
    const network = hre.network.name;
    console.log('\n\n 📡 top up... At %s Network \n', network);
    const accounts = await ethers.getSigners();
    const governance = accounts[0].address;

    const convexIB = await ConvexIronBankChfStrategy.at('0xE800152a10A3fee233De8754cb70051911a7d156');
    await convexIB.investWithSynthForex();
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });