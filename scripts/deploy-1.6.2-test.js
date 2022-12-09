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
const os = require("os");
const axios = require("axios");
const hardhatConfig = require("../hardhat.config");

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
const MockValueInterpreter = 'MockValueInterpreter';
const TestAdapter = 'TestAdapter';
const AggregatedDerivativePriceFeed = 'AggregatedDerivativePriceFeed';
const Harvester = 'Harvester';
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

/**
 * Add strategy to vault
 */
const addStrategiesToUSDVault = async (vault, allArray, increaseArray) => {
    const isFirst = isEqual(allArray, increaseArray);
    if (isFirst) {
        console.log('All strategies:');
        console.table(allArray);
    } else {
        console.log('All strategies:');
        console.table(allArray);
        console.log('New Strategy:');
        console.table(increaseArray);
    }

    const questionOfAddStrategy = [{
        type: 'list',
        name: 'type',
        message: 'Please select the list of policies to be added？\n',
        choices: isFirst ? [{
            key: 'y',
            name: 'All strategies',
            value: 1,
        }, {
            key: 'n',
            name: 'Exit, I will not add!',
            value: 0,
        }] : [{
            key: 'y',
            name: 'All strategies',
            value: 1,
        }, {
            key: 'n',
            name: 'Add new Strategy',
            value: 2,
        }, {
            key: 'n',
            name: 'Exit, I will not add!',
            value: 0,
        }],
    }];

    if (isEmpty(vault)) {
        vault = await USDVaultContract.at(addressMap[USDVault]);
    }
    let type = process.env.USDI_STRATEGY_TYPE_VALUE;
    if (!type) {
        type = await inquirer.prompt(questionOfAddStrategy).then((answers) => {
            const {
                type
            } = answers;
            return type;
        });
    }

    if (!type) {
        return
    }

    const nextArray = type === 1 ? allArray : increaseArray

    return vault.addStrategies(nextArray.map(item => {
        return {
            strategy: item.strategy,
            profitLimitRatio: item.profitLimitRatio,
            lossLimitRatio: item.lossLimitRatio
        }
    }));
}

/**
 * add Strategies to eth vault
 */
const addStrategiesToETHVault = async (vault, allArray, increaseArray) => {
    const isFirst = isEqual(allArray, increaseArray);
    if (isFirst) {
        console.log('All strategies:');
        console.table(allArray);
    } else {
        console.log('All strategies:');
        console.table(allArray);
        console.log('New Strategy:');
        console.table(increaseArray);
    }

    const questionOfAddStrategy = [{
        type: 'list',
        name: 'type',
        message: 'Please select the list of policies to be added？\n',
        choices: isFirst ? [{
            key: 'y',
            name: 'All strategies',
            value: 1,
        }, {
            key: 'n',
            name: 'Exit, I will not add!',
            value: 0,
        }] : [{
            key: 'y',
            name: 'All strategies',
            value: 1,
        }, {
            key: 'n',
            name: 'Add new Strategy',
            value: 2,
        }, {
            key: 'n',
            name: 'Exit, I will not add!',
            value: 0,
        }],
    }];

    if (isEmpty(vault)) {
        vault = await ETHVaultContract.at(addressMap[ETHVault]);
    }
    let type = process.env.ETHI_STRATEGY_TYPE_VALUE;
    if(!type){
        type = await inquirer.prompt(questionOfAddStrategy).then((answers) => {
            const {
                type
            } = answers;
            return type ;
        });
    }
    if (!type) {
        return
    }

    const nextArray = type === 1 ? allArray : increaseArray

    return vault.addStrategies(nextArray.map(item => {
        return {
            strategy: item.strategy,
            profitLimitRatio: item.profitLimitRatio,
            lossLimitRatio: item.lossLimitRatio
        }
    }));
}

const main = async () => {
    let type = process.env.VAULT_TYPE_VALUE;
    if(!type){
        console.log('start select');
        type = await inquirer.prompt(questionOfWhichVault).then((answers) => {
            const {
                type
            } = answers;

            return type;
        })
    }
    if (!type) {
        return
    }

    const accounts = await ethers.getSigners();
    const balanceBeforeDeploy = await ethers.provider.getBalance(accounts[0].address);

    await deploy_common();
    if (type == 1) {
        await deploy_usd();
    } else if (type == 2) {
        await deploy_eth();
    } else if (type == 3) {
        await deploy_usd();
        await deploy_eth();
    }

    console.table(addressMap);


    const balanceAfterDeploy = await ethers.provider.getBalance(accounts[0].address);
    console.log('balanceBeforeDeploy:%d,balanceAfterDeploy:%d', ethers.utils.formatEther(balanceBeforeDeploy), ethers.utils.formatEther(balanceAfterDeploy));

    if (hre.network.name == 'localhost') {
        console.log('start set apollo config');
        const {clusterName,host} = await get_apollo_cluster_name();
        console.log(clusterName,host);
        const blockNumber = hardhatConfig.networks.hardhat.forking.blockNumber;
        await modify_apollo_config('boc.networks.eth.startBlock', blockNumber, clusterName, host);
        await modify_apollo_config('boc.networks.ethi.startBlock', blockNumber, clusterName, host);
        for (let key in addressMap) {
            if (Object.prototype.hasOwnProperty.call(addressMap, key)) {
                if (key == 'Vault') {
                    await modify_apollo_config('boc.networks.eth.vaultAddress', addressMap[key], clusterName, host);
                } else if (key == 'ETHVault') {
                    await modify_apollo_config('boc.networks.ethi.vaultAddress', addressMap[key], clusterName, host);
                } else if (key == 'USDVaultBuffer') {
                    await modify_apollo_config('boc.networks.eth.vaultBufferAddress', addressMap[key], clusterName, host);
                } else if (key == 'ETHVaultBuffer') {
                    await modify_apollo_config('boc.networks.ethi.vaultBufferAddress', addressMap[key], clusterName, host);
                } else if (key == 'USDPegToken') {
                    await modify_apollo_config('boc.networks.eth.pegTokenAddress', addressMap[key], clusterName, host);
                } else if (key == 'TestAdapter') {
                    await modify_apollo_config('boc.networks.eth.TestAdapter', addressMap[key], clusterName, host);
                } else if (key == 'ETHTestAdapter') {
                    await modify_apollo_config('boc.networks.ethi.TestAdapter', addressMap[key], clusterName, host);
                } else if (key == 'ETHPegToken') {
                    await modify_apollo_config('boc.networks.ethi.pegTokenAddress', addressMap[key], clusterName, host);
                } else if (key == 'Verification') {
                    await modify_apollo_config('boc.networks.eth.verificationAddress', addressMap[key], clusterName, host);
                    await modify_apollo_config('boc.networks.ethi.verificationAddress', addressMap[key], clusterName, host);
                } else if (key == 'Harvester') {
                    await modify_apollo_config('boc.networks.eth.harvester', addressMap[key], clusterName, host);
                }  else if (key == 'HarvestHelper') {
                    await modify_apollo_config('boc.networks.ethi.harvestHelpAddress', addressMap[key], clusterName, host);
                } else {
                    await modify_apollo_config(`boc.networks.eth.${key}`, addressMap[key], clusterName, host);
                }
            }
        }

        await publish_apollo_config(clusterName, host);
        console.log('end set apollo config');
    }
}

const get_apollo_cluster_name = async () =>{
    let windowsIp = '127.0.0.1';
    let localIp = windowsIp;
    let host = '172.31.30.50:8070';
    const osType = os.type();
    const netInfo = os.networkInterfaces();
    if (osType === 'Windows_NT'){
        host = '13.215.137.222:8070';
        for (let devName  in netInfo) {
            const iface = netInfo[devName];
            for (let i = 0; i < iface.length; i++) {
                const alias = iface[i];
                if (alias.family === 'IPv4' && alias.address !== '127.0.0.1' && !alias.internal) {
                    localIp = alias.address;
                    break;
                }
            }
            if(localIp != windowsIp){
                break;
            }
        }
    } else{
        localIp = netInfo && netInfo.eth0 && netInfo.eth0.length>0 && netInfo.eth0[0].address || windowsIp;
    }
    console.log('localIp',localIp);
    let url = `http://${host}/openapi/v1/envs/DEV/apps/boc-common/clusters/default/namespaces/boc1.application`;
    let config = {
        headers: {
            Authorization:'e9ac544052e7e295e453f414363e8ccf5ff37ff3',
            'Content-Type':'application/json;charset=UTF-8'
        },
        params: {

        }
    };
    let resp =  await axios.get(url, config);
    const itemData =  resp.data?.items.find(function (item) {
        return item.key == localIp;
    });
    let clusterName = 'local';
    if(itemData && itemData.value){
        clusterName = itemData.value;
    }
    return {clusterName,host};
}

const publish_apollo_config = async (clusterName,host) =>{
    let url = `http://${host}/openapi/v1/envs/DEV/apps/boc-common/clusters/${clusterName}/namespaces/boc1.application/releases`;
    let questBody = {
        "releaseTitle": new Date().toLocaleDateString(),
        "releaseComment": 'publish smart contract',
        "releasedBy":"apollo"
    };
    let config = {
        headers: {
            Authorization:'e9ac544052e7e295e453f414363e8ccf5ff37ff3',
            'Content-Type':'application/json;charset=UTF-8'
        },
        params: {
            createIfNotExists: true
        }
    };
    await axios.post(url, questBody, config);
}

const modify_apollo_config = async (key,value,clusterName,host) =>{
    let url = `http://${host}/openapi/v1/envs/DEV/apps/boc-common/clusters/${clusterName}/namespaces/boc1.application/items/${key}`;
    let questBody = {
        "key": key,
        "value": value,
        "dataChangeLastModifiedBy":"apollo",
        "dataChangeCreatedBy":"apollo"
    };
    let config = {
        headers: {
            Authorization:'e9ac544052e7e295e453f414363e8ccf5ff37ff3',
            'Content-Type':'application/json;charset=UTF-8'
        },
        params: {
            createIfNotExists: true
        }
    };
    await axios.put(url, questBody, config);
}

const deploy_common = async () => {
    const network = hre.network.name;
    console.log('\n\n 📡 Deploying... At %s Network \n', network);
    const accounts = await ethers.getSigners();
    assert(accounts.length > 0, 'Need a Signer!');
    const governor = accounts[0].address;
    const delegator = process.env.DELEGATOR_ADDRESS || get(accounts, '16.address', '');
    const vaultManager = process.env.VAULT_MANAGER_ADDRESS || get(accounts, '17.address', '');
    const keeper = process.env.KEEPER_ACCOUNT_ADDRESS || get(accounts, '18.address', '');
    console.log('governor address:%s',governor);
    console.log('delegator address:%s',delegator);
    console.log('vaultManager address:%s',vaultManager);
    console.log('usd keeper address:%s',keeper);
}

const deploy_usd = async () => {
    console.log('process.argv:', process.argv);

    if (hre.network.name == 'localhost') {
        if (isEmpty(addressMap[MockValueInterpreter])) {
            await deployBase(MockValueInterpreter, [ChainlinkPriceFeed, AggregatedDerivativePriceFeed, AccessControlProxy]);
        }
        if (isEmpty(addressMap[TestAdapter])) {
            await deployBase(TestAdapter, [MockValueInterpreter]);
        }
    }

    let cVault = await USDVaultContract.at(addressMap[USDVault]);

    const allArray = [];
    const increaseArray = [];
    for (const strategyItem of strategiesListUsd) {
        const {
            name,
            contract,
            addToVault,
            profitLimitRatio,
            lossLimitRatio,
            customParams
        } = strategyItem
        let strategyAddress = addressMap[name];
        if (isEmpty(strategyAddress)) {
            const deployStrategy = await deployProxyBase(contract, [USDVault, Harvester], [name, ...customParams], name);
            if (addToVault) {
                strategyAddress = deployStrategy.address;
                increaseArray.push({
                    name,
                    strategy: strategyAddress,
                    profitLimitRatio,
                    lossLimitRatio,
                })
            }
        }
        allArray.push({
            name,
            strategy: strategyAddress,
            profitLimitRatio,
            lossLimitRatio,
        })
    }

    await addStrategiesToUSDVault(cVault, allArray, increaseArray);
    // console.log('getStrategies=', await cVault.getStrategies());
};

const deploy_eth = async () => {

    let cVault = await VaultContract.at(addressMap[ETHVault]);

    const allArray = [];
    const increaseArray = [];
    for (const strategyItem of strategiesListEth) {
        const {
            name,
            contract,
            addToVault,
            profitLimitRatio,
            lossLimitRatio,
            customParams
        } = strategyItem
        let strategyAddress = addressMap[name];
        if (isEmpty(strategyAddress)) {
            const deployStrategy = await deployProxyBase(contract, [ETHVault], [name, ...customParams], name);
            if (addToVault) {
                strategyAddress = deployStrategy.address;
                increaseArray.push({
                    name,
                    strategy: strategyAddress,
                    profitLimitRatio,
                    lossLimitRatio,
                })
            }
        }
        allArray.push({
            name,
            strategy: strategyAddress,
            profitLimitRatio,
            lossLimitRatio,
        })
    }

    await addStrategiesToETHVault(cVault, allArray, increaseArray);
    // console.log('getStrategies=', await cVault.getStrategies());
};

main().then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
