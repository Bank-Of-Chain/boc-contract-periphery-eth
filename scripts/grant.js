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
    const admin = '0x4fd4c98babee5e22219c573713308329da40649d'
    await impersonates([admin])

    const accounts = await ethers.getSigners();
    const governor = accounts[0].address;
    const delegator = accounts[17].address;
    const vaultManager = accounts[18].address;
    const keeper = accounts[19].address;

    // get vault's accessControlProxy
    const accessControlProxyAddress = await (await Vault.at(vaultAddress)).accessControlProxy()
    console.log('access control proxy address：', accessControlProxyAddress)
    // add account[0] to admin
    const constract = await AccessControlProxy.at(accessControlProxyAddress)

    const defaultAdminRole = await constract.DEFAULT_ADMIN_ROLE()
    await constract.grantRole(defaultAdminRole, governor, {
        from: admin
    })

    const delegateRole = await constract.DELEGATE_ROLE()
    await constract.grantRole(delegateRole, delegator, {
        from: admin
    })
    await constract.grantRole(delegateRole, governor, {
        from: admin
    })

    const vaultRole = await constract.VAULT_ROLE();
    const keeperRole = await constract.KEEPER_ROLE();
    console.log('Permissions：', vaultRole)
    console.log('Permissions：', keeperRole)
    try {
        await constract.grantRole(vaultRole, vaultManager, {
            from: governor
        })
        await constract.grantRole(vaultRole, governor, {
            from: governor
        })
        await constract.grantRole(keeperRole, keeper, {
            from: governor
        })
        await constract.grantRole(keeperRole, governor, {
            from: governor
        })
        console.log('Add permission successfully!')
    } catch (e) {
        console.log('Add permission fail!', e)
    }
    // Determine whether the permission is added successfully
    console.log('Permission verification admin：', await constract.isVaultOrGov(admin))
    console.log('Permission Verification governor：', await constract.isGovOrDelegate(governor))
    console.log('Permission Verification delegator：', await constract.isGovOrDelegate(delegator))
    console.log('Permission Verification vaultManager：', await constract.isVaultOrGov(vaultManager))
    console.log('Permission Verification keeper：', await constract.isKeeperOrVaultOrGov(keeper))

    console.log('Transferring ownership of ProxyAdmin...');
    const proxyAdmin = await ProxyAdmin.at('0xFa738A66B5531F20673eE2189CF4C0E5CB97Cd33');
    // console.log('proxyAdmin owner', await proxyAdmin);
    // The owner of the ProxyAdmin can upgrade our contracts
    await proxyAdmin.transferOwnership(governor, {from: admin});
    console.log('Transferred ownership of ProxyAdmin to:', governor);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
