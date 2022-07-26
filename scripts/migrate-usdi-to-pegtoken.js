const {
    ethers,
    upgrades
} = require('hardhat');

// const { Contract, Provider } = require('ethers-multicall');

const {
    deploy,
    deployProxy
} = require('../utils/deploy-utils');
const {
    send
} = require('@openzeppelin/test-helpers');
const ProxyAdmin = hre.artifacts.require('@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol:ProxyAdmin');
const IVault = hre.artifacts.require('IVault');
const USDi = hre.artifacts.require('USDi');
const PegToken = hre.artifacts.require('PegToken');
const vaultAbi = require('../artifacts/boc-contract-core/contracts/vault/IVault.sol/IVault.json');
const assert = require('assert');

const governance = '0xc791B4A9B10b1bDb5FBE2614d389f0FE92105279';
const proxyAdminAddress = '0x56db3157F8cF98E1c5d11707e4DCAF86e50a55Ec';


const vaultAddr = "0xd5C7A01E49ab534e31ABcf63bA5a394fF1E5EfAC";
const usdiAddr = "0xBe15Eed7D8e91D20263d4521c9eB0F4e3510bfBF";
const accessControlProxy = "0xf2Dc068255a4dD00dA73a5a668e8BB1e0cfd347f";

const usdiHolders = [
    "0xee3dB241031c4Aa79fECA628f7a00AAa603901a6",
    "0x6b4B48CCDb446A109AE07D8b027CE521B5e2F1Ff",
    "0x2346C6b1024E97c50370c783A66d80f577fE991d",
    "0x579a09bbFEaFb4d23d9fA36C08FAE754f1E612B7",
];

const main = async () => {
    let network = hre.network.name;
    console.log('upgrade Vault on network-%s', network);

    /********* Local Fork environment impersonating a governance account start*******/
    if (network == 'localhost') {
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
    /********* Local Fork environment impersonating a governance account end*******/

    const usdi = await USDi.at(usdiAddr);
    const usdiTotalSupply = BigInt(await usdi.totalSupply());
    const rebasingCreditsPerToken = BigInt(await usdi.rebasingCreditsPerToken());
    const rebasingCreditsPerTokenRevert = BigInt(1e45) / rebasingCreditsPerToken;
    console.log('USDi total supply:%d,rebasingCreditsPerToken:%d,rebasingCreditsPerTokenRevert:%d',
        usdiTotalSupply,
        rebasingCreditsPerToken,
        rebasingCreditsPerTokenRevert);

    const pegTokenShares = [];
    let totalBalance = BigInt(0);
    for (let index = 0; index < usdiHolders.length; index++) {
        const account = usdiHolders[index];
        const usdiBalance = BigInt(await usdi.balanceOf(account));
        totalBalance = totalBalance + usdiBalance;
        pegTokenShares.push(usdiBalance * BigInt(1e27) / rebasingCreditsPerTokenRevert);
        console.log('%s USDi balance:%d', account, usdiBalance);
    }
    console.log('totalBalance:%d', totalBalance);
    console.log('Number(totalBalance):%d,Number(usdiTotalSupply):%d', Number(totalBalance), Number(usdiTotalSupply));
    assert(Number(totalBalance) == Number(usdiTotalSupply));

    //deploy PegToken
    const pegToken = await deployProxy("PegToken", ["USD Peg Token", "USDi", 18, vaultAddr, accessControlProxy]);

    //upgrade Vault
    const vaultArtifacts = await ethers.getContractFactory("Vault");
    let vaultUpgraded = await upgrades.upgradeProxy(vaultAddr, vaultArtifacts);
    console.log('vaultUpgraded:', vaultUpgraded.address);

    const iVault = await IVault.at(vaultAddr);
    console.log('finish upgraded Vault,version:%s', await iVault.getVersion());
    const balanceBefore = await ethers.provider.getBalance(governance);
    console.log('balanceBefore:%d', ethers.utils.formatEther(balanceBefore.toString()));

    //deploy VaultBuffer
    const vaultBuffer = await deployProxy("VaultBuffer", ['USD Peg Token Ticket', 'tUSDi', vaultAddr, pegToken.address, accessControlProxy]);

    //deploy VaultAdmin
    const vaultAdmin = await deploy("VaultAdmin");

    console.log('Vault setup start.');
    await iVault.setAdminImpl(vaultAdmin.address, { from: governance });
    await iVault.setPegTokenAddress(pegToken.address, { from: governance });
    await iVault.setVaultBufferAddress(vaultBuffer.address, { from: governance });
    await iVault.setUnderlyingUnitsPerShare(rebasingCreditsPerTokenRevert,{ from: governance });
    await iVault.setRebaseThreshold(10,{ from: governance });
    await iVault.setMaxTimestampBetweenTwoReported(604800,{ from: governance });
    await iVault.setEmergencyShutdown(true, { from: governance });
    console.log('Vault setup end.');

    //migrate
    const signedPegToken = await PegToken.at(pegToken.address);
    await signedPegToken.migrate(usdiHolders, pegTokenShares, { from: governance });
    
    await iVault.setEmergencyShutdown(false, { from: governance });
    console.log('Migrate finish!');
    console.log('UnderlyingUnit per share:%d', await iVault.underlyingUnitsPerShare());
    console.log('PegToken total shares:%d', await pegToken.totalShares());
    console.log('PegToken total supply:%d', await pegToken.totalSupply());
    console.log('Vault total assets:%d', await iVault.totalAssets());


    for (let index = 0; index < usdiHolders.length; index++) {
        const account = usdiHolders[index];
        const pegTokenShare = await pegToken.sharesOf(account);
        const pegTokenBalance = await pegToken.balanceOf(account);
        console.log('%s PegToken share:%d balance:%d', account, pegTokenShare, pegTokenBalance);
    }

    const balanceAfter = await ethers.provider.getBalance(governance);
    console.log('balanceAfter:%d', ethers.utils.formatEther(balanceAfter.toString()));
    console.log('use eth:%d', ethers.utils.formatEther((balanceBefore - balanceAfter).toString()));

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