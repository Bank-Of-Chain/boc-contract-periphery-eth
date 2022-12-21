require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-etherscan');
require('@nomiclabs/hardhat-truffle5');
require('hardhat-gas-reporter');
require('hardhat-contract-sizer');
require('@openzeppelin/hardhat-upgrades');
require('hardhat-log-remover');
require('dotenv').config();

const {
    removeConsoleLog
} = require('hardhat-preprocessor');

let keys = {}
try {
    keys = require('./dev-keys.json');
} catch (error) {
    keys = {
        alchemyKey: {
            dev: process.env.CHAIN_KEY
        }
    }
}

process.env.FORCE_COLOR = '3';
process.env.TS_NODE_TRANSPILE_ONLY = 'true';
const ETHERSCAN_API = process.env.ETHERSCAN_API;

const DEFAULT_BLOCK_GAS_LIMIT = 30000000;

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
    const accounts = await ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config = {
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            chains: {
                1: {
                    hardforkHistory: {
                        berlin: 10000000,
                        london: 20000000,
                    }
                }
            },
            forking: {
                url: 'https://eth-mainnet.alchemyapi.io/v2/' + keys.alchemyKey.dev,
                blockNumber: 16224377, // <-- edit here
            },
            blockGasLimit: DEFAULT_BLOCK_GAS_LIMIT,
            timeout: 1800000,
            allowUnlimitedContractSize: true,
        },
        localhost: {
            url: 'http://127.0.0.1:8545',
            allowUnlimitedContractSize: true,
            // GasPrice used when performing blocking, in wei
            // gasPrice: 100 * 10 ** 9,
            timeout: 1800000,

            /*
              notice no mnemonic here? it will just use account 0 of the hardhat node to deploy
              (you can put in a mnemonic here to set the deployer locally)
            */
        },
        testmachine: {
            url: 'http://127.0.0.1:8545',
        },
        ropsten: {
            allowUnlimitedContractSize: true,
            url: `https://ropsten.infura.io/v3/8476fc1501574602923b36e84b1943bb`,
            accounts: process.env.ACCOUNT_PRIVATE_KEY ? [`${process.env.ACCOUNT_PRIVATE_KEY}`] : undefined,
        },
        kovan: {
            url: `https://kovan.infura.io/v3/8476fc1501574602923b36e84b1943bb`,
            accounts: process.env.ACCOUNT_PRIVATE_KEY ? [`${process.env.ACCOUNT_PRIVATE_KEY}`] : undefined,
        },
        mainnet: {
            url: `https://eth-mainnet.g.alchemy.com/v2/ZYgaLj6aguvs_FkgM-2dKhBR9ZXEGC9X`,
            accounts: process.env.ACCOUNT_PRIVATE_KEY ? [`${process.env.ACCOUNT_PRIVATE_KEY}`] : undefined,
            // The gasPrice used when performing the blocking, in wei, for the release, 80Gwei is used
            gasPrice: 10 * 10 ** 9,
            timeout: 2000000000,
            timeoutBlocks: 10000
        },
        rinkeby: {
            url: 'https://arb-mainnet.g.alchemy.com/v2/QyRoYoT8DwdeaCQC9PYwPtPKbworxRyf',
            // accounts : accounts(), //must mnemonic
            // Looking at the source code, here we enter the HardhatNetworkHDAccountsUserConfig object, which is to find the wallet address through the mnemonic.
            accounts: {
                mnemonic: 'XXXXX',
            },
        },
    },
    etherscan: {
        // The api of etherscan is wrapped in the hardhat plugin for open source use
        apiKey: ETHERSCAN_API,
    },
    solidity: {
        compilers: [{
            version: '0.6.12',
            settings: {
                optimizer: {
                    details: {
                        yul: false,
                    },
                    enabled: true,
                    runs: 200
                },
            },

        },
            {
                version: '0.8.3',
                settings: {
                    optimizer: {
                        details: {
                            yul: true,
                        },
                        enabled: true,
                        runs: 200
                    },
                },
            },
        ],
    },
    paths: {
        sources: './contracts',
        tests: './test',
        cache: './cache',
        artifacts: './artifacts',
    },
    mocha: {
        timeout: 2000000,
    },
    preprocess: {
        eachLine: removeConsoleLog(bre => bre.network.name !== 'hardhat' && bre.network.name !== 'localhost'),
    },
    gasReporter: {
        enabled: true,
        currency: 'USD',
    },
    contractSizer: {
        alphaSort: true,
        runOnCompile: true,
        disambiguatePaths: false,
    },
};

const forkLatest = process.env.FORK_LATEST;
if (forkLatest) {
    delete config.networks.hardhat.forking.blockNumber;
}

module.exports = config;
