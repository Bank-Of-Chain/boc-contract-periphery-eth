const {
    ethers
} = require('hardhat');

const BigNumber = require('bignumber.js');
const {
    isEmpty,
    get,
    reduce,
    keys,
    includes,
    isEqual
} = require('lodash');
const inquirer = require('inquirer');

const MFC_TEST = require('../config/mainnet-fork-test-config');
const MFC_PRODUCTION = require('../config/mainnet-fork-config');
const {
    strategiesList: strategiesListUsd
} = require('../config/strategy-usd/strategy-config-usd');
const {
    strategiesList: strategiesListEth
} = require('../config/strategy-eth/strategy-config-eth');

const {
    deploy,
    deployProxy
} = require('../utils/deploy-utils');

// === Utils === //
const USDVaultContract = hre.artifacts.require("IVault");

// === USD Constants === //
const USDVault = 'Vault';
const USDVaultBuffer = 'USDVaultBuffer';
const USDPegToken = 'USDPegToken';
const USDVaultAdmin = 'VaultAdmin';
const Treasury = 'Treasury';
const ValueInterpreter = 'ValueInterpreter';
const ParaSwapV5Adapter = 'ParaSwapV5Adapter';
const OneInchV4Adapter = 'OneInchV4Adapter';
const ChainlinkPriceFeed = 'ChainlinkPriceFeed';
const ExchangeAggregator = 'ExchangeAggregator';
const AccessControlProxy = 'AccessControlProxy';
const AggregatedDerivativePriceFeed = 'AggregatedDerivativePriceFeed';
const Harvester = 'Harvester';
const Dripper = 'Dripper';
const USDT_ADDRESS = 'USDT_ADDRESS';
const Verification = 'Verification';
const USD_INITIAL_ASSET_LIST = [
    MFC_PRODUCTION.USDT_ADDRESS,
    MFC_PRODUCTION.USDC_ADDRESS,
    MFC_PRODUCTION.DAI_ADDRESS,
]

// === Utils === //
const VaultContract = hre.artifacts.require("IETHVault");
const AggregatedDerivativePriceFeedContract = hre.artifacts.require("AggregatedDerivativePriceFeed");
const ChainlinkPriceFeedContract = hre.artifacts.require("ChainlinkPriceFeed");

// === Constants ETH === //
const ETHVault = 'ETHVault';
const ETHVaultAdmin = 'ETHVaultAdmin';
const ETHVaultBuffer = 'ETHVaultBuffer';
const ETHPegToken = 'ETHPegToken';
const PriceOracleConsumer = 'PriceOracleConsumer';
const HarvestHelper = 'HarvestHelper';
const ETH_INITIAL_ASSET_LIST = [
    MFC_PRODUCTION.ETH_ADDRESS,
]

// Used to store address information during deployment
// ** Note that if an address is configured in this object, no publishing operation will be performed.
const addressMap = {
    ...reduce(strategiesListUsd, (rs, i) => {
        rs[i.name] = '';
        return rs
    }, {}),
    //----------------Common---------------------------
    [Verification]: '0x3eBd354DF4134951a5AFde008E63BfC93D2b6F59',
    [AccessControlProxy]: '0x94c0AA94Ef3aD19E3947e58a855636b38aDe53e0',
    [OneInchV4Adapter]: '0xe3a66514B6e0aFa08aC98607D3d7eC6B8bACd6D5',
    [ParaSwapV5Adapter]: '0x9a020e23814be9980D64357aE9aEa44Fc3f6A51f',
    [ExchangeAggregator]: '0x921FE3dF4F2073f0d4d0B839B6068460397a04f9',
    [Treasury]: '0xc156E56402D0A2C8924e87ff8195A4635B44BD6a',
    //----------------USD---------------------------
    [ChainlinkPriceFeed]: '0xA92C91Fe965D7497A423d951fCDFA221fC354B5a',
    [AggregatedDerivativePriceFeed]: '0xFee7b64EB3A80B80D22193BA317a39D7F40c55F3',
    [ValueInterpreter]: '0xE4153088577C2D634CB4b3451Aa4ab7E7281ef1f',
    [USDVault]: '0x30D120f80D60E7b58CA9fFaf1aaB1815f000B7c3',
    [Harvester]: '0x238ECCBf7532B9e622372981e6707B7e88392e60',
    [Dripper]: '',
    [USDT_ADDRESS]: MFC_PRODUCTION.USDT_ADDRESS,
    [USDVaultAdmin]: '0x2D90Cb03031a45773E95eAdd49465A636C547631',
    [USDPegToken]: '0x83131242843257bc6C43771762ba467346Efb2CF',
    [USDVaultBuffer]: '0x0b8D3634a05cc6b50E4D026c0eaFa8469cA98480',
    //----------------ETH---------------------------
    ...reduce(strategiesListEth, (rs, i) => {
        rs[i.name] = '';
        return rs
    }, {}),
    [PriceOracleConsumer]: '0xc542b8c1b38BD87D6aFc0346f041b2FAC8301467',
    [ETHVault]: '0x8f0Cb368C63fbEDF7a90E43fE50F7eb8B9411746',
    [ETHVaultAdmin]: '0x78eE089276194a8C3D278ca46B29ce40Ea62613b',
    [HarvestHelper]: '0xdcE94fDbAB4a65FEC92C69a4b78e0d8476ADE040',
    [ETHPegToken]: '0x1A597356E7064D4401110FAa2242bD0B51D1E4Fa',
    [ETHVaultBuffer]: '0xC8915157b36ed6D0F36827a1Bb5E9b0cDd1e87Cd'
}
const questionOfWhichVault = [{
    type: 'list',
    name: 'type',
    message: 'Please select the product to be deployed？\n',
    choices: [
        {
            key: 'USD&ETH Vault',
            name: 'USD&ETH Vault',
            value: 3,
        },
        {
            key: 'USD Vault',
            name: 'USD Vault',
            value: 1,
        },
        {
            key: 'ETH Vault',
            name: 'ETH Vault',
            value: 2,
        }
    ]
}];

/**
 * Add dependent addresses to addressMap
 * @param {string} dependName Name of the dependency
 * @returns
 */
const addDependAddress = async (dependName) => {
    const questions = [{
        type: 'input',
        name: 'address',
        message: `${dependName} The contract address is missing, please enter the latest address\n`,
        validate(value) {
            console.log('Start to continue calibration：', value);
            const pass = value.match(
                /^0x[a-fA-F0-9]{40}$/
            );
            if (pass) {
                return true;
            }
            return 'Please enter the correct contract address';
        }
    }];

    return inquirer.prompt(questions).then((answers) => {
        const {
            address
        } = answers;
        if (!isEmpty(address)) {
            addressMap[dependName] = address;
        }
        return;
    });
}

/**
 * Basic Deployment Logic
 * @param {string} contractName Contract Name
 * @param {string[]} depends Contract Fronting Dependency
 */
const deployBase = async (contractName, depends = []) => {
    console.log(` 🛰  Deploying: ${contractName}`);
    const keyArray = keys(addressMap);
    const nextParams = [];
    for (const depend of depends) {
        if (includes(keyArray, depend)) {
            if (isEmpty(get(addressMap, depend))) {
                await addDependAddress(depend);
            }
            nextParams.push(addressMap[depend]);
            continue;
        }
        nextParams.push(depend);
    }

    try {
        const constract = await deploy(contractName, nextParams);
        await constract.deployed();
        addressMap[contractName] = constract.address;
        return constract;
    } catch (error) {
        console.log('Contract Deployment Exceptions：', error);
        const questions = [{
            type: 'list',
            name: 'confirm',
            message: `${contractName} The contract release failed, do you want to retry？\n`,
            choices: [{
                key: 'y',
                name: 'Try again',
                value: 1,
            },
            {
                key: 'n',
                name: 'Exit Deployment',
                value: 2,
            },
            {
                key: 's',
                name: 'Ignore this deployment exception',
                value: 3,
            },
            ],
        }];

        return inquirer.prompt(questions).then((answers) => {
            const {
                confirm
            } = answers;
            if (confirm === 1) {
                return deployBase(contractName, depends);
            } else if (confirm === 2) {
                return process.exit(0)
            }
            return
        });
    }
}

/**
 * Basic Deployment Logic
 * @param {string} contractName Contract Name
 * @param {string[]} depends Contract Fronting Dependency
 */
const deployProxyBase = async (contractName, depends = [], customParams = [], name = null) => {
    console.log(` 🛰  Deploying[Proxy]: ${contractName}`);
    const keyArray = keys(addressMap);
    const dependParams = [];
    for (const depend of depends) {
        if (includes(keyArray, depend)) {
            if (isEmpty(get(addressMap, depend))) {
                await addDependAddress(depend);
            }
            dependParams.push(addressMap[depend]);
            continue;
        }
        dependParams.push(depend);
    }

    try {
        const allParams = [
            ...dependParams,
            ...customParams
        ];

        const constract = await deployProxy(contractName, allParams, { timeout: 0 });
        await constract.deployed();
        addressMap[name == null ? contractName : name] = constract.address;
        return constract;
    } catch (error) {
        console.log('Contract Deployment Exceptions：', error);
        const questions = [{
            type: 'list',
            name: 'confirm',
            message: `${contractName} The contract release failed, do you want to retry？\n`,
            choices: [{
                key: 'y',
                name: 'Try again',
                value: 1,
            },
            {
                key: 'n',
                name: 'Exit Deployment',
                value: 2,
            },
            {
                key: 's',
                name: 'Ignore this deployment exception',
                value: 3,
            },
            ],
        }];

        return inquirer.prompt(questions).then((answers) => {
            const {
                confirm
            } = answers;
            if (confirm === 1) {
                return deployProxyBase(contractName, depends);
            } else if (confirm === 2) {
                return process.exit(0)
            }
            return
        });
    }
}



const main = async () => {

    const network = hre.network.name;
    const accounts = await ethers.getSigners();
    console.log('\n\n 📡 Deploying... At %s Network \n', network);
    assert(accounts.length > 0, 'Need a Signer!');
    const balanceBeforeDeploy = await ethers.provider.getBalance(accounts[0].address);
    const governor = accounts[0].address;
    const delegator = process.env.DELEGATOR_ADDRESS || get(accounts, '16.address', '');
    const vaultManager = process.env.VAULT_MANAGER_ADDRESS || get(accounts, '17.address', '');
    const keeper = process.env.KEEPER_ACCOUNT_ADDRESS || get(accounts, '18.address', '');
    console.log('governor address:%s',governor);
    console.log('delegator address:%s',delegator);
    console.log('vaultManager address:%s',vaultManager);
    console.log('usd keeper address:%s',keeper);

    const MFC = network === 'localhost' || network === 'hardhat' ? MFC_TEST : MFC_PRODUCTION

    if (!isEmpty(addressMap[ChainlinkPriceFeed])) {
        const chainlinkPriceFeedContract =  await ChainlinkPriceFeedContract.at(addressMap[ChainlinkPriceFeed]);
        let primitives = new Array();
        let aggregators = new Array();
        let heartbeats = new Array();
        let rateAssets = new Array();

        const value = MFC.CHAINLINK.aggregators['STETH_ETH'];
        primitives.push(value.primitive);
        aggregators.push(value.aggregator);
        heartbeats.push(value.heartbeat);
        rateAssets.push(value.rateAsset);
        await chainlinkPriceFeedContract.addPrimitives(primitives,aggregators,heartbeats,rateAssets);
        console.log('chain link price feed add steth success');
    }

    const balanceAfterDeploy = await ethers.provider.getBalance(accounts[0].address);
    console.log('balanceBeforeDeploy:%d,balanceAfterDeploy:%d', ethers.utils.formatEther(balanceBeforeDeploy), ethers.utils.formatEther(balanceAfterDeploy));
}

main().then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
