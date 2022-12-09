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
    
    if (isEmpty(addressMap[AccessControlProxy])) {
        const accessControlProxy = await deployProxyBase(AccessControlProxy, [governor, delegator, vaultManager, keeper]);
        const governorRole = await accessControlProxy.DEFAULT_ADMIN_ROLE();
        const delegatorRole = await accessControlProxy.DELEGATE_ROLE();
        const vaultRole = await accessControlProxy.VAULT_ROLE();
        const keeperRole = await accessControlProxy.KEEPER_ROLE();
        console.log('%s has governor role:%s',governor,await accessControlProxy.hasRole(governorRole,governor));
        console.log('%s has delegator role:%s',delegator,await accessControlProxy.hasRole(delegatorRole,delegator));
        console.log('%s has vaultManager role:%s',vaultManager,await accessControlProxy.hasRole(vaultRole,vaultManager));
        console.log('%s has keeper role:%s',keeper,await accessControlProxy.hasRole(keeperRole,keeper));
        
        // const AccessControlProxyContract = hre.artifacts.require("AccessControlProxy");
        // const accessControlProxy2 = await AccessControlProxyContract.at(accessControlProxy.address);
        // console.log('keeperRole:%s',keeperRole);
        
        // await accessControlProxy2.grantRole(keeperRole,keeperForEth,{from:delegator});
        // console.log('%s has keeper role:%s',keeperForEth,await accessControlProxy.hasRole(keeperRole,keeperForEth));
    }

    if (isEmpty(addressMap[Treasury])) {
        await deployProxyBase(Treasury, [AccessControlProxy]);
    }

    if (isEmpty(addressMap[OneInchV4Adapter])) {
        oneInchV4Adapter = await deployBase(OneInchV4Adapter);
    }
    if (isEmpty(addressMap[ParaSwapV5Adapter])) {
        paraSwapV5Adapter = await deployBase(ParaSwapV5Adapter);
    }

    if (isEmpty(addressMap[ExchangeAggregator])) {
        const adapterArray = [addressMap[OneInchV4Adapter], addressMap[ParaSwapV5Adapter]];
        exchangeAggregator = await deployBase(ExchangeAggregator, [adapterArray, AccessControlProxy]);
    }
}

const deploy_usd = async () => {
    console.log('process.argv:', process.argv);

    let vault;
    let vaultBuffer;
    let pegToken;

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


    if (isEmpty(addressMap[Harvester])) {
        harvester = await deployProxyBase(Harvester, [AccessControlProxy, USDVault, USDT_ADDRESS, USDVault]);
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
        // await cVault.setRebaseThreshold(1);
        // await cVault.setUnderlyingUnitsPerShare(new BigNumber(10).pow(18).toFixed());
        // await cVault.setMaxTimestampBetweenTwoReported(604800);
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
