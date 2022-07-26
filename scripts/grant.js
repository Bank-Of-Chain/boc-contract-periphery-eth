const {
    ethers,
} = require('hardhat');
const {
    impersonates
} = require('../utils/top-up-utils');

const Vault = hre.artifacts.require("IVault");
const AccessControlProxy = hre.artifacts.require("AccessControlProxy");
const ProxyAdmin = hre.artifacts.require('@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin');

async function main() {
    // Production vault address
    const vaultAddress = '0xd5C7A01E49ab534e31ABcf63bA5a394fF1E5EfAC'
    // Production administrator account, need to be disguised
    const admin = '0xc791b4a9b10b1bdb5fbe2614d389f0fe92105279'
    await impersonates([admin])

    const accounts = await ethers.getSigners();
    const nextManagement = accounts[0].address;
    const keeper = accounts[19].address;

    // get vault's accessControlProxy
    const accessControlProxyAddress = await (await Vault.at(vaultAddress)).accessControlProxy()
    console.log('access control proxy address：', accessControlProxyAddress)
    // add account[0] to admin
    const constract = await AccessControlProxy.at(accessControlProxyAddress)

    const delegateRole = await constract.DELEGATE_ROLE()
    await constract.grantRole(delegateRole, nextManagement, {
        from: admin
    })

    const role = await constract.VAULT_ROLE()
    console.log('Permissions：', role)
    try {
        await constract.grantRole(role, nextManagement, {
            from: admin
        })
        await constract.grantRole(role, keeper, {
            from: admin
        })
        console.log('Add permission successfully!')
    } catch (e) {
        console.log('Add permission fail!', e)
    }
    // Determine whether the permission is added successfully
    console.log('Permission verification admin：', await constract.isVaultOrGov(admin))
    console.log('Permission Verification nextManagement：', await constract.isVaultOrGov(nextManagement))

    console.log('Transferring ownership of ProxyAdmin...');
    const proxyAdmin = await ProxyAdmin.at('0x56db3157F8cF98E1c5d11707e4DCAF86e50a55Ec');
    console.log('proxyAdmin owner', await proxyAdmin);
    // The owner of the ProxyAdmin can upgrade our contracts
    await proxyAdmin.transferOwnership(nextManagement, {from: admin});
    console.log('Transferred ownership of ProxyAdmin to:', nextManagement);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
