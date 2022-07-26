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
const IETHVault = hre.artifacts.require('IETHVault');
const ETHi = hre.artifacts.require('ETHi');
const PegToken = hre.artifacts.require('PegToken');
const assert = require('assert');

const governance = '0xc791B4A9B10b1bDb5FBE2614d389f0FE92105279';
const proxyAdminETHAddress = '0xCde447B0bd5D93FC6E82F095e4E28595b20Ee590';
const proxyAdminUSDAddress = '0x56db3157F8cF98E1c5d11707e4DCAF86e50a55Ec';

const priceOracleAddr = "0x8eD25770E6480578972f8Cc9577c127D6F3b74fE";
const vaultAddr = "0xDae16f755941cbC0C9D240233a6F581d1734DaA2";
const ethiAddr = "0x8cB9Aca95D1EdebBfe6BD9Da4DC4a2024457bD32";
const accessControlProxy = "0xf2Dc068255a4dD00dA73a5a668e8BB1e0cfd347f";

const ethiHolders = [
    "0x6b4B48CCDb446A109AE07D8b027CE521B5e2F1Ff",
];

const ethiProxyDeployInfo = require('../.openzeppelin/v1.5.3/mainnet-eth.json');

// invoke migrate-proxy-admin.js first, and copy proxies&impls to mainnet-usd.json from mainnet-eth.json
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
        let proxyAdmin = await ProxyAdmin.at(proxyAdminUSDAddress);
        let proxyAdminOwner = await proxyAdmin.owner();
        if (proxyAdminOwner == governance) {
            await proxyAdmin.transferOwnership(nextManagement, { from: governance });
        }

        
    }
    /********* Local Fork environment impersonating a governance account end*******/

    const ethi = await ETHi.at(ethiAddr);
    const ethiTotalSupply = BigInt(await ethi.totalSupply());
    const ethiBalancePerShare = BigInt(await ethi.getPooledEthByShares(BigInt(1e18)));
    console.log('ETHi total supply:%d,ethiBalancePerShare:%d',
        ethiTotalSupply,
        ethiBalancePerShare);

    const pegTokenShares = [];
    let totalBalance = BigInt(0);
    for (let index = 0; index < ethiHolders.length; index++) {
        const account = ethiHolders[index];
        const ethiBalance = BigInt(await ethi.balanceOf(account));
        totalBalance = totalBalance + ethiBalance;
        pegTokenShares.push(ethiBalance * BigInt(1e27) / ethiBalancePerShare);
        console.log('%s ETHi balance:%d', account, ethiBalance);
    }
    console.log('totalBalance:%d', totalBalance);
    console.log('Number(totalBalance):%d,Number(ethiTotalSupply):%d', Number(totalBalance), Number(ethiTotalSupply));
    assert(Number(totalBalance) == Number(ethiTotalSupply));

    //upgrade PriceOracle
    const priceOracleArtifacts = await ethers.getContractFactory("PriceOracle");
    let priceOracleUpgraded = await upgrades.upgradeProxy(priceOracleAddr, priceOracleArtifacts);
    console.log('priceOracleUpgraded:%s,version:%s', priceOracleUpgraded.address,await priceOracleUpgraded.version());

    //deploy PegToken
    const pegToken = await deployProxy("PegToken", ["ETH Peg Token", "ETHi", 18, vaultAddr, accessControlProxy]);

    //upgrade Vault
    const vaultArtifacts = await ethers.getContractFactory("ETHVault");
    let vaultUpgraded = await upgrades.upgradeProxy(vaultAddr, vaultArtifacts);
    console.log('vaultUpgraded:', vaultUpgraded.address);

    const iVault = await IETHVault.at(vaultAddr);
    console.log('finish upgraded Vault,version:%s', await iVault.getVersion());
    const balanceBefore = await ethers.provider.getBalance(governance);
    console.log('balanceBefore:%d', ethers.utils.formatEther(balanceBefore.toString()));

    //deploy VaultBuffer
    const vaultBuffer = await deployProxy("VaultBuffer", ['ETH Peg Token Ticket', 'tETHi', vaultAddr, pegToken.address, accessControlProxy]);

    //deploy VaultAdmin
    const vaultAdmin = await deploy("ETHVaultAdmin");

    console.log('Vault setup start.');
    await iVault.setAdminImpl(vaultAdmin.address, { from: governance });
    await iVault.setPegTokenAddress(pegToken.address, { from: governance });
    await iVault.setVaultBufferAddress(vaultBuffer.address, { from: governance });
    await iVault.setUnderlyingUnitsPerShare(ethiBalancePerShare, { from: governance });
    await iVault.setRebaseThreshold(10, { from: governance });
    await iVault.setMaxTimestampBetweenTwoReported(604800, { from: governance });
    // await iVault.rebase({ from: governance });
    await iVault.setEmergencyShutdown(true, { from: governance });
    console.log('Vault setup end.');

    //migrate
    const signedPegToken = await PegToken.at(pegToken.address);
    await signedPegToken.migrate(ethiHolders, pegTokenShares, { from: governance });

    await iVault.setEmergencyShutdown(false, { from: governance });
    // await iVault.rebase({ from: governance });
    console.log('Migrate finish!');
    console.log('UnderlyingUnit per share:%d', await iVault.underlyingUnitsPerShare());
    console.log('PegToken total shares:%d', await pegToken.totalShares());
    console.log('PegToken total supply:%d', await pegToken.totalSupply());
    console.log('Vault total assets:%d', await iVault.totalAssets());


    for (let index = 0; index < ethiHolders.length; index++) {
        const account = ethiHolders[index];
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