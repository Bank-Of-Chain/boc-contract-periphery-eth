const { send } = require("@openzeppelin/test-helpers")
const MockPriceOracle = hre.artifacts.require('MockPriceOracle');
const Comptroller = hre.artifacts.require('Comptroller');

const main = async () => {
    const mockPriceOracle = await MockPriceOracle.new();
    console.log('mockPriceOracle address:%s',mockPriceOracle.address);
    //set
    const comptroller = await Comptroller.at('0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB');
    const comptrollerAdmin = '0x5b12f04e22384b01f42ed14da23eacd21f14ac17';
    await impersonates([comptrollerAdmin]);
    const accounts = await ethers.getSigners();
    await send.ether(accounts[0].address, comptrollerAdmin, 10 * 10 ** 18)
    await comptroller._setPriceOracle(mockPriceOracle.address,{from:comptrollerAdmin});
    console.log('comptroller oracle:%s',await comptroller.oracle());
    
};

/**
 * impersonates
 * @param {*} targetAccounts
 * @returns
 */
 async function impersonates (targetAccounts) {
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: targetAccounts,
    })
    return async () => {
        await hre.network.provider.request({
            method: "hardhat_stopImpersonatingAccount",
            params: targetAccounts,
        })
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });