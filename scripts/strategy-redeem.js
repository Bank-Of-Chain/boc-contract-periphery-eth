const { makeTransferProxyAdminOwnership } = require('@openzeppelin/hardhat-upgrades/dist/admin');
const {
    ethers,
    upgrades
} = require('hardhat');
const {
    impersonates
} = require('../utils/top-up-utils');
const {
    send
} = require('@openzeppelin/test-helpers');

const Vault = hre.artifacts.require("IVault");
const AccessControlProxy = hre.artifacts.require("AccessControlProxy");
const ProxyAdmin = hre.artifacts.require('@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin');
const ConvexIBUsdtStrategy = hre.artifacts.require("ConvexIBUsdtStrategy");
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');

async function main() {
    // Production vault address
    const vaultAddress = '0x30D120f80D60E7b58CA9fFaf1aaB1815f000B7c3'
    // Production administrator account, need to be disguised
    const admin = '0x4fd4c98baBEe5E22219C573713308329da40649D'
    await impersonates([admin])

    const accounts = await ethers.getSigners();
    // console.log('accounts:',accounts);
    
    const nextManagement = accounts[0].address;
    // const keeper = accounts[19].address;

    const vault = await Vault.at(vaultAddress);
    // get vault's accessControlProxy
    const accessControlProxyAddress = await vault.accessControlProxy()
    console.log('access control proxy address：', accessControlProxyAddress)
    // add account[0] to admin
    const constract = await AccessControlProxy.at(accessControlProxyAddress)

    const delegateRole = await constract.DELEGATE_ROLE()
    await constract.grantRole(delegateRole, nextManagement, {
        from: admin
    })

    await transferwnership()

    const strategy = await ConvexIBUsdtStrategy.at('0x18d9eFb0e5d4FB27f3c35C55801877b2143d44CF')
    const strategyArtifacts = await ethers.getContractFactory('ConvexIBUsdtStrategy');
    let upgraded = await upgrades.upgradeProxy(strategy.address, strategyArtifacts);
    console.log('finish upgrade, version:%s',await strategy.getVersion())
    const strategyParams = await vault.strategies(strategy.address)
    console.log('strategyParams:',strategyParams);
    const usdt = await ERC20.at('0xdAC17F958D2ee523a2206206994597C13D831ec7')
    console.log('strategy assets:%s',await strategy.estimatedTotalAssets());
    
    console.log('usdt balance before redeem:%d',await usdt.balanceOf(vault.address))
    await vault.redeem(strategy.address,strategyParams.totalDebt,0)
    console.log('usdt balance after redeem:%d',await usdt.balanceOf(vault.address))

    
}

async function transferwnership(){
    const governance = '0x4fd4c98baBEe5E22219C573713308329da40649D'
    const proxyAdminAddress = '0xFa738A66B5531F20673eE2189CF4C0E5CB97Cd33'
    await impersonates([governance]);
        const accounts = await ethers.getSigners();
        const nextManagement = accounts[0].address;
        await send.ether(nextManagement, governance, 10 * (10 ** 18));
        //transfer ownership
        let proxyAdmin = await ProxyAdmin.at(proxyAdminAddress);
        let proxyAdminOwner = await proxyAdmin.owner();
        if (proxyAdminOwner == governance) {
            await proxyAdmin.transferOwnership(nextManagement, { from: governance });
        }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
