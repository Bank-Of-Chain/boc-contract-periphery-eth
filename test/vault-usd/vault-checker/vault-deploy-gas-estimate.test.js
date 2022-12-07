const {
	ethers
} = require('hardhat');
const {
	isEmpty,
	get,
	reduce,
	keys,
	includes,
	isEqual
} = require('lodash');
const inquirer = require('inquirer');

const MFC_TEST = require('../../../config/mainnet-fork-test-config');
const MFC_PRODUCTION = require('../../../config/mainnet-fork-config');
const {
	strategiesList
} = require('../../../config/strategy-usd/strategy-config-usd.js');

const {
	deploy,
	deployProxy
} = require('../../../utils/deploy-utils');

// === Utils === //
const VaultContract = hre.artifacts.require("IVault");

// === Constants === //
const Vault = 'Vault';
const VaultBuffer = 'VaultBuffer';
const VaultAdmin = 'VaultAdmin';
const PegToken = 'PegToken';
const Treasury = 'Treasury';
const OneInchAdapter = 'OneInchAdapter';
const ValueInterpreter = 'ValueInterpreter';
const ParaSwapV5Adapter = 'ParaSwapV5Adapter';
const ChainlinkPriceFeed = 'ChainlinkPriceFeed';
const ExchangeAggregator = 'ExchangeAggregator';
const AccessControlProxy = 'AccessControlProxy';
const AggregatedDerivativePriceFeed = 'AggregatedDerivativePriceFeed';
const OneInchV4Adapter = 'OneInchV4Adapter';
const Harvester = 'Harvester';
const USDT_ADDRESS = 'USDT_ADDRESS';
const Verification = 'Verification';
const INITIAL_ASSET_LIST = [
    MFC_PRODUCTION.USDT_ADDRESS,
    MFC_PRODUCTION.USDC_ADDRESS,
    MFC_PRODUCTION.DAI_ADDRESS,
]

// Used to store address information during deployment
// ** Note that if an address is configured in this object, no publishing operation will be performed.
const addressMap = {
	...reduce(strategiesList, (rs, i) => {
		rs[i.name] = '';
		return rs
	}, {}),
	Curve3CrvStrategy: '',
	AaveUsdtStrategy: '',
	AaveUsdcStrategy: '',
	QuickswapDaiUsdtStrategy: '',
	QuickswapUsdcDaiStrategy: '',
	QuickswapUsdcUsdtStrategy: '',
	SushiUsdcDaiStrategy: '',
	SushiUsdcUsdtStrategy: '',
	BalancerUsdcUsdtDaiTusdStrategy: '',
	DodoUsdtUsdcStrategy: '',
	Synapse4UStrategy: '',
	[Verification]: '0x3eBd354DF4134951a5AFde008E63BfC93D2b6F59',
	[AccessControlProxy]: '',
	[ChainlinkPriceFeed]: '',
	[AggregatedDerivativePriceFeed]: '',
	[ValueInterpreter]: '',
	[OneInchV4Adapter]: '',
	[OneInchAdapter]: '',
	[ParaSwapV5Adapter]: '',
	[ExchangeAggregator]: '',
	[Treasury]: '',
    [USDi]: '',
	[Vault]: '',
	[Harvester]: '',
	[USDT_ADDRESS]: MFC_PRODUCTION.USDT_ADDRESS,
	[VaultAdmin]: '',
}

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
const depolyBase = async (contractName, depends = []) => {
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
				return depolyBase(contractName, depends);
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
const deployProxyBase = async (contractName, depends = []) => {
	console.log(` 🛰  Deploying[Proxy]: ${contractName}`);
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
		const constract = await deployProxy(contractName, nextParams);
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
const addStrategies = async (vault, allArray, increaseArray) => {
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

	const questions = [{
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
		vault = await VaultContract.at(addressMap[Vault]);
	}
	return inquirer.prompt(questions).then((answers) => {
		const {
			type
		} = answers;
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
	})
}

describe('Vault deploy gas Test', function () {
	it('Test Vault deploy gas', async function () {
	let verification;
    let vault;
    let vaultAdmin;
	let vaultBuffer;
    let accessControlProxy;
    let chainlinkPriceFeed;
    let aggregatedDerivativePriceFeed;
    let oneInchV4Adapter;
    let paraSwapV5Adapter;
    let valueInterpreter;
    let treasury;
    let exchangeAggregator;
	let pegToken;
    let harvester;

    const network = hre.network.name;
	const MFC = network === 'localhost' || network === 'hardhat' ? MFC_TEST : MFC_PRODUCTION
	console.log('\n\n 📡 Deploying... At %s Network \n', network);
	const accounts = await ethers.getSigners();
	assert(accounts.length > 0, 'Need a Signer!');
	const management = accounts[0].address;
	const keeper = process.env.KEEPER_ACCOUNT_ADDRESS || get(accounts, '19.address', '');

	if (isEmpty(addressMap[AccessControlProxy])) {
		accessControlProxy = await deployProxyBase(AccessControlProxy, [management,management,management,keeper]);
	}

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
		chainlinkPriceFeed = await depolyBase(ChainlinkPriceFeed, [
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
		aggregatedDerivativePriceFeed = await depolyBase(AggregatedDerivativePriceFeed, [derivatives, priceFeeds, AccessControlProxy]);
	}

	if (isEmpty(addressMap[ValueInterpreter])) {
		valueInterpreter = await depolyBase(ValueInterpreter, [ChainlinkPriceFeed, AggregatedDerivativePriceFeed, AccessControlProxy]);
	}
	// if (isEmpty(addressMap[OneInchAdapter])) {
	// 	oneInchAdapter = await depolyBase(OneInchAdapter);
	// }
	if (isEmpty(addressMap[OneInchV4Adapter])) {
		oneInchV4Adapter = await depolyBase(OneInchV4Adapter);
	}
	if (isEmpty(addressMap[ParaSwapV5Adapter])) {
		paraSwapV5Adapter = await depolyBase(ParaSwapV5Adapter);
	}

	if (isEmpty(addressMap[ExchangeAggregator])) {
		const adapterArray = [addressMap[OneInchV4Adapter], addressMap[ParaSwapV5Adapter]];
		exchangeAggregator = await depolyBase(ExchangeAggregator, [adapterArray, AccessControlProxy]);
	}

    if (isEmpty(addressMap[VaultAdmin])) {
	    vaultAdmin = await depolyBase(VaultAdmin);
	}

	if (isEmpty(addressMap[Treasury])) {
		treasury = await deployProxyBase(Treasury, [AccessControlProxy]);
	}

	let cVault;
	if (isEmpty(addressMap[Vault])) {
		vault = await deployProxyBase(Vault, [AccessControlProxy, Treasury, ExchangeAggregator, ValueInterpreter]);
	    cVault = await VaultContract.at(addressMap[Vault]);
		await vault.setAdminImpl(vaultAdmin.address);
        for (let i = 0; i < INITIAL_ASSET_LIST.length; i++) {
            const asset = INITIAL_ASSET_LIST[i];
            await cVault.addAsset(asset);
        }
	}else{
		cVault = await VaultContract.at(addressMap[Vault]);
	}
	if (isEmpty(addressMap[PegToken])) {
		console.log(` 🛰  Deploying[Proxy]: ${PegToken}`);
		console.log('vault address=', addressMap[Vault]);
		pegToken = await deployProxy(PegToken, ["USD Peg Token", "USDi", 18, addressMap[Vault], addressMap[AccessControlProxy]], {timeout: 0});
		await pegToken.deployed();
		addressMap[PegToken] = pegToken.address;
		await cVault.setPegTokenAddress(addressMap[PegToken]);
		// await cVault.setRebaseThreshold(1);
		// await cVault.setUnderlyingUnitsPerShare(new BigNumber(10).pow(18).toFixed());
		// await cVault.setMaxTimestampBetweenTwoReported(604800);
		console.log("maxTimestampBetweenTwoReported:",new BigNumber(await cVault.maxTimestampBetweenTwoReported()).toFixed());
	}

	if (isEmpty(addressMap[VaultBuffer])) {
		console.log(` 🛰  Deploying[Proxy]: ${VaultBuffer}`);
		console.log('vault address=', addressMap[Vault]);
		console.log('usdi address=', addressMap[PegToken]);
		const vaultBuffer = await deployProxy(VaultBuffer, ['USD Peg Token Ticket', 'tUSDi', addressMap[Vault], addressMap[PegToken], addressMap[AccessControlProxy]]);
		await vaultBuffer.deployed();
		addressMap[VaultBuffer] = vaultBuffer.address;
		await cVault.setVaultBufferAddress(addressMap[VaultBuffer]);
	}


	if (isEmpty(addressMap[Harvester])) {
		harvester = await deployProxyBase(Harvester, [AccessControlProxy, Vault, USDT_ADDRESS, Vault]);
	}

	const allArray = [];
	const increaseArray = [];
	for (const strategyItem of strategiesList) {
		const {
			name,
			addToVault,
			profitLimitRatio,
			lossLimitRatio,
		} = strategyItem
		let strategyAddress = addressMap[name];
		if (isEmpty(strategyAddress)) {
			const deployStrategy = await deployProxyBase(name, [Vault, Harvester]);
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

	await addStrategies(cVault, allArray, increaseArray);
	console.log('getStrategies=', await cVault.getStrategies());
	console.table(addressMap);
	});
});
