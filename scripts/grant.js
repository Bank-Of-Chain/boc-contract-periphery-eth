const {
    ethers, upgrades,
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
    const governor = accounts[0].address;
    const delegator = accounts[17].address;
    const vaultManager = accounts[17].address;
    const keeper = accounts[19].address;

    console.log('Transferring ownership of ProxyAdmin...');
    const proxyAdmin = await ProxyAdmin.at('0xFa738A66B5531F20673eE2189CF4C0E5CB97Cd33');
    // console.log('proxyAdmin owner', await proxyAdmin);
    // The owner of the ProxyAdmin can upgrade our contracts
    await proxyAdmin.transferOwnership(governor, {from: admin});
    console.log('Transferred ownership of ProxyAdmin to:', governor);

    // get vault's accessControlProxy
    const accessControlProxyAddress = await (await Vault.at(vaultAddress)).accessControlProxy()
    console.log('access control proxy address：', accessControlProxyAddress)

    //upgrade AccessControlProxy
    console.log('=========AccessControlProxy upgrade starting==========');
    const contractArtifact = await ethers.getContractFactory('AccessControlProxy');
    await upgrades.upgradeProxy(accessControlProxyAddress, contractArtifact);
    console.log('=========AccessControlProxy upgrade completed==========');

    // add account[0] to admin
    const constract = await AccessControlProxy.at(accessControlProxyAddress);

    const govRole = await constract.DEFAULT_ADMIN_ROLE()
    console.log('gov role permission：%s, member:', govRole, governor);
    try {
        await constract.grantRole(govRole, governor, {
            from: admin
        });
        console.log('Add permission successfully!')
    } catch (e) {
        console.log('Add permission fail!', e)
    }
    const delegateRole = await constract.DELEGATE_ROLE()
    console.log('delegate role permission：%s, member:', delegateRole, delegator);
    try {
        await constract.grantRole(delegateRole, delegator, {
            from: admin
        });
        console.log('Add permission successfully!')
    } catch (e) {
        console.log('Add permission fail!', e)
    }

    const vaultRole = await constract.VAULT_ROLE()
    console.log('vault role ermissions：%s, member:', vaultRole, vaultManager);
    try {
        await constract.grantRole(vaultRole, vaultManager, {
            from: delegator
        });
        console.log('Add permission successfully!')
    } catch (e) {
        console.log('Add permission fail!', e)
    }

    const keeperRole = await constract.KEEPER_ROLE()
    console.log('keeper role permissions：%s, member:', keeperRole,keeper);
    try {
        await constract.grantRole(keeperRole, keeper, {
            from: delegator
        });
        console.log('Add permission successfully!')
    } catch (e) {
        console.log('Add permission fail!', e)
    }
    // Determine whether the permission is added successfully
    console.log('Permission verification admin(isGovOrDelegate)：', await constract.isGovOrDelegate(admin))
    console.log('Permission Verification governor(isGovOrDelegate)：', await constract.isGovOrDelegate(governor))
    console.log('Permission Verification delegator(isVaultOrGovOrDelegate)：', await constract.isGovOrDelegate(delegator))
    console.log('Permission Verification vaultManager(isVaultOrGovOrDelegate)：', await constract.isVaultOrGovOrDelegate(vaultManager))
    console.log('Permission Verification keeper(isKeeperOrVaultOrGov)：', await constract.isKeeperOrVaultOrGov(keeper))
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
