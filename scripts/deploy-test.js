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

const axios = require('axios');
const os = require('os')
const hardhatConfig = require('../hardhat.config');


const {
    deploy,
    deployProxy
} = require('../utils/deploy-utils');

// === Utils === //
const USDVaultContract = hre.artifacts.require("IVault");
const ValueInterpreterContract = hre.artifacts.require("ValueInterpreter");
const ChainlinkPriceFeedContract = hre.artifacts.require("ChainlinkPriceFeed");

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
const MockPriceModel = 'MockPriceModel';
const TestAdapter = 'TestAdapter';
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

    //----------------USD---------------------------
    [Verification]: '0x3eBd354DF4134951a5AFde008E63BfC93D2b6F59',
    [AccessControlProxy]: '',
    [ChainlinkPriceFeed]: '',
    [AggregatedDerivativePriceFeed]: '',
    [ValueInterpreter]: '',
    [OneInchV4Adapter]: '',
    [ParaSwapV5Adapter]: '',
    [ExchangeAggregator]: '',
    [Treasury]: '',
    [USDVault]: '',
    [Harvester]: '',
    [Dripper]: '',
    [USDT_ADDRESS]: MFC_PRODUCTION.USDT_ADDRESS,
    [USDVaultAdmin]: '',
    //----------------ETH---------------------------
    ...reduce(strategiesListEth, (rs, i) => {
        rs[i.name] = '';
        return rs
    }, {}),
    [PriceOracleConsumer]: '',
    [ETHVault]: '',
    [ETHVaultAdmin]: '',
    [HarvestHelper]: '',
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

const questionOfUpdateType = [{
    type: 'list',
    name: 'type',
    message: 'Please select the type to be update？\n',
    choices: [
        {
            key: 'Update aggregator',
            name: 'Update aggregator',
            value: 1,
        },
        {
            key: 'Not Update',
            name: 'Not Update',
            value: 0,
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

    return vault.addStrategy(nextArray.map(item => {
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

    return vault.addStrategy(nextArray.map(item => {
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

    let updateType = process.env.AGGREGATOR_UPDATE_TYPE_VALUE;
    if(!updateType){
        updateType = await inquirer.prompt(questionOfUpdateType).then((answers) => {
            const {
                type
            } = answers;

            return type;
        })
    }
    if (updateType) {
        let primitives = []
        let aggregators = []
        let heartbeats = []
        const valueInterpreter = await ValueInterpreterContract.at(addressMap[ValueInterpreter]);
        const chainlinkPriceFeedAddr = await valueInterpreter.getPrimitivePriceFeed()

        const chainlinkPriceFeed = await ChainlinkPriceFeedContract.at(chainlinkPriceFeedAddr);

        const MFC = network === 'localhost' || network === 'hardhat' ? MFC_TEST : MFC_PRODUCTION

        for (const key in MFC.CHAINLINK.aggregators) {
            if (Object.hasOwnProperty.call(MFC.CHAINLINK.aggregators, key)) {
                const aggregator = MFC.CHAINLINK.aggregators[key]
                if (await chainlinkPriceFeed.isSupportedAsset(aggregator.primitive)) {
                    primitives.push(aggregator.primitive)
                    aggregators.push(aggregator.aggregator)
                    heartbeats.push(60 * 60 * 24 * 365)
                    console.log(`will update ${aggregator.primitive} aggregator`)
                }
            }
        }

        await chainlinkPriceFeed.updatePrimitives(primitives, aggregators, heartbeats);

        await chainlinkPriceFeed.setEthUsdAggregator('0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', 60 * 60 * 24 * 365)

        console.log('update aggregator successfully')
    }

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
                } else if (key == 'Dripper') {
                    await modify_apollo_config('boc.networks.eth.dripper', addressMap[key], clusterName, host);
                } else if (key == 'HarvestHelper') {
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
    const delegator = process.env.DELEGATOR_ADDRESS || get(accounts, '17.address', '');
    const vaultManager = process.env.VAULT_MANAGER_ADDRESS || get(accounts, '18.address', '');
    const keeper = process.env.KEEPER_ACCOUNT_ADDRESS || get(accounts, '19.address', '');
    console.log('governor address:%s',governor);
    console.log('delegator address:%s',delegator);
    console.log('vaultManager address:%s',vaultManager);
    console.log('keeper address:%s',keeper);
    
    if (isEmpty(addressMap[AccessControlProxy])) {
        await deployProxyBase(AccessControlProxy, [governor, delegator, vaultManager, keeper]);
    }

    if (isEmpty(addressMap[Treasury])) {
        await deployProxyBase(Treasury, [AccessControlProxy]);
    }
}

const deploy_usd = async () => {
    console.log('process.argv:', process.argv);

    let vault;
    let vaultBuffer;
    let pegToken;
    let dripper;

    const network = hre.network.name;
    const MFC = network === 'localhost' || network === 'hardhat' ? MFC_TEST : MFC_PRODUCTION

    if (isEmpty(addressMap[ChainlinkPriceFeed])) {
        let primitives = new Array();
        let aggregators = new Array();
        let heartbeats = new Array();
        let rateAssets = new Array();
        for (const key in MFC.CHAINLINK.aggregators) {
            const value = MFC.CHAINLINK.aggregators[key];
            primitives.push(value.primitive);
            aggregators.push(value.aggregator);
            heartbeats.push(value.heartbeat);
            rateAssets.push(value.rateAsset);
        }
        let basePeggedPrimitives = new Array();
        let basePeggedRateAssets = new Array();
        for (const key in MFC.CHAINLINK.basePegged) {
            const value = MFC.CHAINLINK.basePegged[key];
            basePeggedPrimitives.push(value.primitive);
            basePeggedRateAssets.push(value.rateAsset);
        }
        chainlinkPriceFeed = await deployBase(ChainlinkPriceFeed, [
            MFC.CHAINLINK.ETH_USD_AGGREGATOR,
            MFC.CHAINLINK.ETH_USD_HEARTBEAT,
            primitives,
            aggregators,
            heartbeats,
            rateAssets,
            basePeggedPrimitives,
            basePeggedRateAssets,
            AccessControlProxy
        ]);
    }

    if (isEmpty(addressMap[AggregatedDerivativePriceFeed])) {
        let derivatives = [];
        let priceFeeds = [];
        aggregatedDerivativePriceFeed = await deployBase(AggregatedDerivativePriceFeed, [derivatives, priceFeeds, AccessControlProxy]);
    }

    if (isEmpty(addressMap[ValueInterpreter])) {
        valueInterpreter = await deployBase(ValueInterpreter, [ChainlinkPriceFeed, AggregatedDerivativePriceFeed, AccessControlProxy]);
    }
    if (isEmpty(addressMap[OneInchV4Adapter])) {
        oneInchV4Adapter = await deployBase(OneInchV4Adapter);
    }
    if (isEmpty(addressMap[ParaSwapV5Adapter])) {
        paraSwapV5Adapter = await deployBase(ParaSwapV5Adapter);
    }
    if (hre.network.name == 'localhost') {
        if (isEmpty(addressMap[MockValueInterpreter])) {
            await deployBase(MockValueInterpreter, [ChainlinkPriceFeed, AggregatedDerivativePriceFeed, AccessControlProxy]);
        }
        if (isEmpty(addressMap[TestAdapter])) {
            await deployBase(TestAdapter, [MockValueInterpreter]);
        }
        if (isEmpty(addressMap[MockPriceModel])) {
            await deployBase(MockPriceModel, []);
        }
    }

    if (isEmpty(addressMap[ExchangeAggregator])) {
        const adapterArray = [addressMap[OneInchV4Adapter], addressMap[ParaSwapV5Adapter]];
        exchangeAggregator = await deployBase(ExchangeAggregator, [adapterArray, AccessControlProxy]);
    }

    if (isEmpty(addressMap[USDVaultAdmin])) {
        vaultAdmin = await deployBase(USDVaultAdmin);
    }

    let cVault;
    if (isEmpty(addressMap[USDVault])) {
        vault = await deployProxyBase(USDVault, [AccessControlProxy, Treasury, ExchangeAggregator, ValueInterpreter]);
        cVault = await USDVaultContract.at(addressMap[USDVault]);
        await vault.setAdminImpl(addressMap[USDVaultAdmin]);
        for (let i = 0; i < USD_INITIAL_ASSET_LIST.length; i++) {
            const asset = USD_INITIAL_ASSET_LIST[i];
            await cVault.addAsset(asset);
        }
    } else {
        cVault = await USDVaultContract.at(addressMap[USDVault]);
    }

    if (isEmpty(addressMap[USDPegToken])) {
        console.log(` 🛰  Deploying[Proxy]: ${USDPegToken}`);
        console.log('vault address=', addressMap[USDVault]);
        pegToken = await deployProxy('PegToken', ["USD Peg Token", "USDi", 18, addressMap[USDVault], addressMap[AccessControlProxy]], { timeout: 0 });
        await pegToken.deployed();
        addressMap[USDPegToken] = pegToken.address;
        await cVault.setPegTokenAddress(addressMap[USDPegToken]);
        // await cVault.setRebaseThreshold(1);
        // await cVault.setMaxTimestampBetweenTwoReported(604800);
        // await cVault.setUnderlyingUnitsPerShare(new BigNumber(10).pow(18).toFixed());
    }

    if (isEmpty(addressMap[USDVaultBuffer])) {
        console.log(` 🛰  Deploying[Proxy]: ${USDVaultBuffer}`);
        console.log('vault address=', addressMap[USDVault]);
        vaultBuffer = await deployProxy('VaultBuffer', ['USD Peg Token Ticket', 'tUSDi', addressMap[USDVault], addressMap[USDPegToken], addressMap[AccessControlProxy]], { timeout: 0 });
        await vaultBuffer.deployed();
        addressMap[USDVaultBuffer] = vaultBuffer.address;
        await cVault.setVaultBufferAddress(addressMap[USDVaultBuffer]);
    }

    if (isEmpty(addressMap[Dripper])) {
        dripper = await deployProxyBase(Dripper, [AccessControlProxy, USDVault, USDT_ADDRESS]);
        await dripper.setDripDuration(7 * 24 * 60 * 60);
    }

    if (isEmpty(addressMap[Harvester])) {
        harvester = await deployProxyBase(Harvester, [AccessControlProxy, Dripper, USDT_ADDRESS, USDVault]);
    }

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
    let priceOracle;
    let vault;
    let vaultBuffer;
    let vaultAdmin;
    let ethExchangeAggregator;
    let pegToken;
    let harvestHelper;


    if (isEmpty(addressMap[PriceOracleConsumer])) {
        priceOracle = await deployProxyBase(PriceOracleConsumer, []);
    }

    if (isEmpty(addressMap[OneInchV4Adapter])) {
        oneInchV4Adapter = await deployBase(OneInchV4Adapter);
    }
    if (isEmpty(addressMap[ParaSwapV5Adapter])) {
        paraSwapV5Adapter = await deployBase(ParaSwapV5Adapter);
    }
    if (hre.network.name == 'localhost') {
        if (isEmpty(addressMap[MockValueInterpreter])) {
            await deployBase(MockValueInterpreter, [ChainlinkPriceFeed, AggregatedDerivativePriceFeed, AccessControlProxy]);
        }
        if (isEmpty(addressMap[TestAdapter])) {
            await deployBase(TestAdapter, [MockValueInterpreter]);
        }
    }

    const adapterArray = [addressMap[OneInchV4Adapter], addressMap[ParaSwapV5Adapter]];
    if (isEmpty(addressMap[ExchangeAggregator])) {
        await deployBase(ExchangeAggregator, [adapterArray, AccessControlProxy]);
    }

    if (isEmpty(addressMap[ETHVaultAdmin])) {
        vaultAdmin = await deployBase(ETHVaultAdmin);
    }

    let cVault;
    if (isEmpty(addressMap[ETHVault])) {
        vault = await deployProxyBase(ETHVault, [AccessControlProxy, Treasury, ExchangeAggregator, PriceOracleConsumer]);
        cVault = await VaultContract.at(addressMap[ETHVault]);
        await vault.setAdminImpl(vaultAdmin.address);
        for (let i = 0; i < ETH_INITIAL_ASSET_LIST.length; i++) {
            const asset = ETH_INITIAL_ASSET_LIST[i];
            await cVault.addAsset(asset);
        }
    } else {
        cVault = await VaultContract.at(addressMap[ETHVault]);
    }

    if (isEmpty(addressMap[ETHPegToken])) {
        console.log(` 🛰  Deploying[Proxy]: ${ETHPegToken}`);
        console.log('vault address=', addressMap[ETHVault]);
        pegToken = await deployProxy('PegToken', ["ETH Peg Token", "ETHi", 18, addressMap[ETHVault], addressMap[AccessControlProxy]], { timeout: 0 });
        await pegToken.deployed();
        addressMap[ETHPegToken] = pegToken.address;
        await cVault.setPegTokenAddress(addressMap[ETHPegToken]);
        await cVault.setRebaseThreshold(1);
        // await cVault.setUnderlyingUnitsPerShare(new BigNumber(10).pow(18).toFixed());
        await cVault.setMaxTimestampBetweenTwoReported(604800);
        console.log("maxTimestampBetweenTwoReported:", new BigNumber(await cVault.maxTimestampBetweenTwoReported()).toFixed());
    }

    if (isEmpty(addressMap[ETHVaultBuffer])) {
        console.log(` 🛰  Deploying[Proxy]: ${ETHVaultBuffer}`);
        console.log('vault address=', addressMap[ETHVault]);
        vaultBuffer = await deployProxy('VaultBuffer', ['ETH Peg Token Ticket', 'tETHi', addressMap[ETHVault], addressMap[ETHPegToken], addressMap[AccessControlProxy]], { timeout: 0 });
        await vaultBuffer.deployed();
        addressMap[ETHVaultBuffer] = vaultBuffer.address;
        await cVault.setVaultBufferAddress(addressMap[ETHVaultBuffer]);
    }

    if (isEmpty(addressMap[HarvestHelper])) {
        harvestHelper = await deployBase(HarvestHelper, [AccessControlProxy]);
    }

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
