const {
    ethers,
    upgrades
} = require('hardhat');

const {
    send
} = require('@openzeppelin/test-helpers');
const ProxyAdmin = hre.artifacts.require('@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin');

const governance = '0xc791B4A9B10b1bDb5FBE2614d389f0FE92105279';
const proxyAdminETHAddress = '0xCde447B0bd5D93FC6E82F095e4E28595b20Ee590';
const proxyAdminUSDAddress = '0x56db3157F8cF98E1c5d11707e4DCAF86e50a55Ec';

const ethiProxyDeployInfo = require('../.openzeppelin/v1.5.3/mainnet-eth.json');

const main = async () => {
    //update ProxyAdmin
    const proxies = ethiProxyDeployInfo.proxies;
    console.log('proxies:', proxies);

    /********* Local Fork environment impersonating a governance account start*******/
    let network = hre.network.name;
    if (network == 'localhost') {
        await impersonates([governance]);
        const accounts = await ethers.getSigners();
        const nextManagement = accounts[0].address;
        await send.ether(nextManagement, governance, 10 * (10 ** 18));
        //transfer ownership
        let proxyAdmin = await ProxyAdmin.at(proxyAdminETHAddress);
        let proxyAdminOwner = await proxyAdmin.owner();
        if (proxyAdminOwner == governance) {
            await proxyAdmin.transferOwnership(nextManagement, { from: governance });
        }


    }
    /********* Local Fork environment impersonating a governance account end*******/
    //invoke with main-eth.json
    for (const proxyInfo of proxies) {
        // await proxyAdmin.changeProxyAdmin(proxyInfo.address,proxyAdminUSDAddress);
        await upgrades.admin.changeProxyAdmin(proxyInfo.address, proxyAdminUSDAddress);
        console.log('changeProxyAdmin:', proxyInfo.address);
    }

};

async function impersonates(targetAccounts) {
    for (i = 0; i < targetAccounts.length; i++) {
        await hre.network.provider.request({
            method: 'hardhat_impersonateAccount',
            params: [targetAccounts[i]],
        });
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });