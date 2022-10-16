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


    const accounts = await ethers.getSigners();
    const tx = await ethers.getDefaultProvider().getTransaction('0xe3bcda6b608c76eca9422207eb926c6fe0da0f1b9ce3b82b1d1fc6501e03cc2e')
    console.log(tx)

    const tx_new = {
        nonce: 112,
        to: ethers.constants.AddressZero,
        data: '0x',
        gasPrice: 15 * 10 ** 9
      }; // costs 21000 gas

    await accounts[0].sendTransaction(tx_new);
    console.log('--------')
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
