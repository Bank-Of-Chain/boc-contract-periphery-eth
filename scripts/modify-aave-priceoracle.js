const { send } = require("@openzeppelin/test-helpers")
const MockAavePriceOracleConsumer = hre.artifacts.require('MockAavePriceOracleConsumer');
const ILendingPoolAddressesProvider = hre.artifacts.require('ILendingPoolAddressesProvider');

const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';

const main = async () => {
    const mockPriceOracle = await MockAavePriceOracleConsumer.new();
    console.log('mockPriceOracle address:%s',mockPriceOracle.address);
    //set
    const addressProvider = await ILendingPoolAddressesProvider.at('0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5');
    const addressPrividerOwner = '0xEE56e2B3D491590B5b31738cC34d5232F378a8D5';
    await impersonates([addressPrividerOwner]);

    const originPriceOracleConsumer = await MockAavePriceOracleConsumer.at(await addressProvider.getPriceOracle());
    console.log('USDC price0:%s',await originPriceOracleConsumer.getAssetPrice(USDC));

    const accounts = await ethers.getSigners();
    await send.ether(accounts[0].address, addressPrividerOwner, 10 * 10 ** 18)
    await addressProvider.setPriceOracle(mockPriceOracle.address,{from:addressPrividerOwner});
    console.log('AaveAddressProvider oracle:%s',await addressProvider.getPriceOracle());
    
    console.log('USDC price1:%s',await mockPriceOracle.getAssetPrice(USDC));
    await mockPriceOracle.setAssetPrice(USDC,await mockPriceOracle.getAssetPrice(USDC) * 2);
    console.log('USDC price2:%s',await mockPriceOracle.getAssetPrice(USDC));
    
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