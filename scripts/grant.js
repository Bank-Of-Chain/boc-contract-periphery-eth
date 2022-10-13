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
    const vaultAddress = '0x30D120f80D60E7b58CA9fFaf1aaB1815f000B7c3'
    // Production administrator account, need to be disguised
    const admin = '0x4fd4c98baBEe5E22219C573713308329da40649D'
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
            from: nextManagement
        })
        await constract.grantRole(role, keeper, {
            from: nextManagement
        })
        console.log('Add permission successfully!')
    } catch (e) {
        console.log('Add permission fail!', e)
    }
    // Determine whether the permission is added successfully
    console.log('Permission verification admin(isVaultOrGov)：', await constract.isVaultOrGov(admin))
    console.log('Permission Verification nextManagement(isVaultOrGov)：', await constract.isVaultOrGov(nextManagement))
    console.log('Permission Verification nextManagement(isGovOrDelegate)：', await constract.isGovOrDelegate(nextManagement))

    console.log('Transferring ownership of ProxyAdmin...');
    const proxyAdmin = await ProxyAdmin.at('0xFa738A66B5531F20673eE2189CF4C0E5CB97Cd33');
    // console.log('proxyAdmin owner', await proxyAdmin);
    // The owner of the ProxyAdmin can upgrade our contracts
    await proxyAdmin.transferOwnership(nextManagement, {from: admin});
    console.log('Transferred ownership of ProxyAdmin to:', nextManagement);
    console.log('Permission Verification nextManagement(isGovOrDelegate)：', await constract.isGovOrDelegate(nextManagement))
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
