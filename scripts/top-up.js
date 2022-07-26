const {
    topUpUsdtByAddress,
    topUpUsdcByAddress,
    topUpDaiByAddress
} = require('./../utils/top-up-utils');
const BigNumber = require('bignumber.js');

const main = async () => {
    const network = hre.network.name;
    console.log('\n\n 📡 top up... At %s Network \n', network);
    const accounts = await ethers.getSigners();
    // recharge
    // account2
    await topUpUsdtByAddress(new BigNumber(10 ** 12), accounts[2].address);
    // account1
    await topUpUsdtByAddress(new BigNumber(10 ** 12), accounts[1].address);
    // admin account0
    await topUpUsdtByAddress(new BigNumber(10 ** 12), accounts[0].address);
    await topUpDaiByAddress(new BigNumber(10 ** 24), accounts[0].address);
    await topUpUsdcByAddress(new BigNumber(10 ** 12), accounts[0].address);
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });