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
	strategiesList
} = require('../config/strategy-config-eth.js');

const {
	deploy,
	deployProxy
} = require('../utils/deploy-utils');

// === Utils === //
const VaultContract = hre.artifacts.require("IETHVault");

// === Constants === //
const Vault = 'ETHVault';
const VaultAdmin = 'ETHVaultAdmin';
const VaultBuffer = 'VaultBuffer';
const PegToken = 'PegToken';
const Treasury = 'Treasury';
const HarvestHelper = 'HarvestHelper';
const PriceOracle = 'PriceOracle';
const ParaSwapV5Adapter = 'ParaSwapV5Adapter';
const ExchangeAggregator = 'ExchangeAggregator';
const AccessControlProxy = 'AccessControlProxy';
const OneInchV4Adapter = 'OneInchV4Adapter';
const Verification = 'Verification';
const INITIAL_ASSET_LIST = [
    MFC_PRODUCTION.ETH_ADDRESS,
]

// Used to store address information during deployment
// ** Note that if an address is configured in this object, no publishing operation will be performed.
const addressMap = {
	...reduce(strategiesList, (rs, i) => {
		rs[i.name] = '';
		return rs
	}, {}),
	[Verification]: '0xa43bF64d99cabcCE432310c54D0184d4D5A7d6c4',
	[AccessControlProxy]: '',	//0xf2Dc068255a4dD00dA73a5a668e8BB1e0cfd347f
	[OneInchV4Adapter]: '',
	[ParaSwapV5Adapter]: '',
	[ExchangeAggregator]: '',
	[Treasury]: '0xAc06625A3ed3D37E3e8864aF6baC82469624d24A',
	[HarvestHelper]: '',
	[PriceOracle]: '',
	[Vault]: '',
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

const main = async () => {
	let verification;
	let priceOracle;
    let vault;
	let vaultBuffer;
    let vaultAdmin;
    let accessControlProxy;
    let oneInchV4Adapter;
    let paraSwapV5Adapter;
    let treasury;
    let exchangeAggregator;
	let pegToken;
	let harvestHelper;

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

	if (isEmpty(addressMap[PriceOracle])) {
		priceOracle = await deployProxyBase(PriceOracle, []);
	}

	if (isEmpty(addressMap[OneInchV4Adapter])) {
		oneInchV4Adapter = await deployBase(OneInchV4Adapter);
	}
	if (isEmpty(addressMap[ParaSwapV5Adapter])) {
		paraSwapV5Adapter = await deployBase(ParaSwapV5Adapter);
	}

	const adapterArray = [addressMap[OneInchV4Adapter], addressMap[ParaSwapV5Adapter]];
	if (isEmpty(addressMap[ExchangeAggregator])) {
		exchangeAggregator = await deployBase(ExchangeAggregator, [adapterArray,AccessControlProxy]);
	} else {
		exchangeAggregator = await ExchangeAggregator.at(addressMap[ExchangeAggregator]);
		await exchangeAggregator.addExchangeAdapters(adapterArray);
	}

    if (isEmpty(addressMap[VaultAdmin])) {
	    vaultAdmin = await deployBase(VaultAdmin);
	}

	if (isEmpty(addressMap[Treasury])) {
		treasury = await deployProxyBase(Treasury, [AccessControlProxy]);
	}

	let cVault;
	if (isEmpty(addressMap[Vault])) {
		vault = await deployProxyBase(Vault, [AccessControlProxy, Treasury, ExchangeAggregator, PriceOracle]);
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
		pegToken = await deployProxy(PegToken, ["ETH Peg Token", "ETHi", 18, addressMap[Vault], addressMap[AccessControlProxy]], {timeout: 0});
		await pegToken.deployed();
		addressMap[PegToken] = pegToken.address;
		await cVault.setPegTokenAddress(addressMap[PegToken]);
		await cVault.setRebaseThreshold(1);
		await cVault.setUnderlyingUnitsPerShare(new BigNumber(10).pow(18).toFixed());
		await cVault.setMaxTimestampBetweenTwoReported(604800);
		console.log("maxTimestampBetweenTwoReported:",new BigNumber(await cVault.maxTimestampBetweenTwoReported()).toFixed());
	}

	if (isEmpty(addressMap[VaultBuffer])) {
		console.log(` 🛰  Deploying[Proxy]: ${VaultBuffer}`);
		console.log('vault address=', addressMap[Vault]);
		vaultBuffer = await deployProxy(VaultBuffer, ['ETH Peg Token Ticket', 'tETHi', addressMap[Vault], addressMap[PegToken], addressMap[AccessControlProxy]], {timeout: 0});
		await vaultBuffer.deployed();
		addressMap[VaultBuffer] = vaultBuffer.address;
		await cVault.setVaultBufferAddress(addressMap[VaultBuffer]);
	}

	if (isEmpty(addressMap[HarvestHelper])) {
		harvestHelper = await deployBase(HarvestHelper, [AccessControlProxy]);
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
			const deployStrategy = await deployProxyBase(name, [Vault]);
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
};

main().then(() => process.exit(0))
	.catch(error => {
		console.error(error);
		process.exit(1);
	});
