/**
 * For use in test cases, the uniform initialization of contracts
 */

// === Constants === //
const BigNumber = require("bignumber.js")
const { map } = require("lodash")

const MFC = require("../config/mainnet-fork-test-config")
const { strategiesList } = require("../config/strategy-usd/strategy-config-usd")

const { getStrategiesWants } = require("./strategy-utils")
const {
    // impersonates,
    topUpDaiByAddress,
    topUpUsdtByAddress,
    topUpTusdByAddress,
    topUpUsdcByAddress,
    topUpBusdByAddress,
    // topUpTusdByAddress,
    // topUpPaxByAddress,
    // topUpLusdByAddress,
    topUpMimByAddress,
    topUpLusdByAddress,
    topUpUsdpByAddress,
    // topUpUsdpByAddress
} = require("./top-up-utils")
const hre = require("hardhat");

// === Core Contracts === //
// Access Control Proxy
const AccessControlProxy = hre.artifacts.require("AccessControlProxy");
const Vault = hre.artifacts.require("Vault");
const VaultAdmin = hre.artifacts.require("VaultAdmin");
const VaultBuffer = hre.artifacts.require("VaultBuffer");
const IVault = hre.artifacts.require("IVault");
const Harvester = hre.artifacts.require("Harvester");
// Treasury
const Treasury = hre.artifacts.require("Treasury")
const PegToken = hre.artifacts.require("PegToken")
const ERC20 = hre.artifacts.require("@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20")

const ChainlinkPriceFeed = hre.artifacts.require("ChainlinkPriceFeed")
const AggregatedDerivativePriceFeed = hre.artifacts.require("AggregatedDerivativePriceFeed")
const ValueInterpreter = hre.artifacts.require("ValueInterpreter")
const MockValueInterpreter = hre.artifacts.require(
    "contracts/usd/mock/MockValueInterpreter.sol:MockValueInterpreter",
)
const TestAdapter = hre.artifacts.require("TestAdapter");
const ExchangeAggregator = hre.artifacts.require("ExchangeAggregator")
const IExchangeAdapter = hre.artifacts.require("IExchangeAdapter")
const OneInchV4Adapter = hre.artifacts.require('OneInchV4Adapter');
const ParaSwapV5Adapter = hre.artifacts.require('ParaSwapV5Adapter');

/**
 * Initializing vault contracts
 * @param {string} underlyingAddress
 * @param {string} keeper
 * @returns
 */
async function setupCoreProtocol (underlyingAddress, governance, keeper) {
    return await setupCoreProtocolWithMockValueInterpreter(
        underlyingAddress,
        governance,
        keeper,
        false,
    )
}

/**
 * initialize vault （Includes whether the mock valueInterpreter）
 * @param {string} underlyingAddress
 * @param {string} keeper
 * @param {boolean} mock
 * @returns
 */
async function setupCoreProtocolWithMockValueInterpreter (
    underlyingAddress,
    governance,
    keeper,
    mock,
) {
    const underlying = await ERC20.at(underlyingAddress)
    let vault = await Vault.new()
    const accessControlProxy = await AccessControlProxy.new()
    accessControlProxy.initialize(governance, governance, vault.address, keeper)
    const governanceOwner = governance

    let derivatives = new Array()
    const priceFeeds = new Array()
    const primitives = new Array()
    const aggregators = new Array()
    const heartbeats = new Array()
    const rateAssets = new Array()
    for (const key in MFC.CHAINLINK.aggregators) {
        const value = MFC.CHAINLINK.aggregators[key]
        primitives.push(value.primitive)
        aggregators.push(value.aggregator)
        heartbeats.push(value.heartbeat)
        rateAssets.push(value.rateAsset)
    }
    const basePeggedPrimitives = new Array()
    const basePeggedRateAssets = new Array()
    for (const key in MFC.CHAINLINK.basePegged) {
        const value = MFC.CHAINLINK.basePegged[key]
        basePeggedPrimitives.push(value.primitive)
        basePeggedRateAssets.push(value.rateAsset)
    }
    const chainlinkPriceFeed = await ChainlinkPriceFeed.new(
        MFC.CHAINLINK.ETH_USD_AGGREGATOR,
        MFC.CHAINLINK.ETH_USD_HEARTBEAT,
        primitives,
        aggregators,
        heartbeats,
        rateAssets,
        basePeggedPrimitives,
        basePeggedRateAssets,
        accessControlProxy.address,
    )
    const aggregatedDerivativePriceFeed = await AggregatedDerivativePriceFeed.new(
        derivatives,
        priceFeeds,
        accessControlProxy.address,
    )
    let valueInterpreter
    let exchangeAggregator
    let testAdapter;

    if (mock) {
        valueInterpreter = await MockValueInterpreter.new(
            chainlinkPriceFeed.address,
            aggregatedDerivativePriceFeed.address,
            accessControlProxy.address,
        )
        console.log('deploy TestAdapter');
        testAdapter = await TestAdapter.new(valueInterpreter.address);
        console.log('deploy ExchangeAggregator');
        exchangeAggregator = await ExchangeAggregator.new([testAdapter.address], accessControlProxy.address);
    } else {
        valueInterpreter = await ValueInterpreter.new(
            chainlinkPriceFeed.address,
            aggregatedDerivativePriceFeed.address,
            accessControlProxy.address,
        )
        console.log('deploy TestAdapter');
        testAdapter = await TestAdapter.new(valueInterpreter.address);

        console.log('deploy OneInchV4Adapter');
        const oneInchV4Adapter = await OneInchV4Adapter.new();

        console.log('deploy ParaSwapV5Adapter');
        const paraSwapV5Adapter = await ParaSwapV5Adapter.new();
        console.log('deploy ExchangeAggregator');
        exchangeAggregator = await ExchangeAggregator.new([oneInchV4Adapter.address,paraSwapV5Adapter.address], accessControlProxy.address);
    }

    const exchangePlatformAdapters = await getExchangePlatformAdapters(exchangeAggregator)

    // const usdi = await USDi.new()
    // await usdi.initialize("USDi", "USDi", 18, vault.address, accessControlProxy.address)
    const pegToken = await PegToken.new();
    await pegToken.initialize("USD Peg Token", "USDi", 18, vault.address, accessControlProxy.address)

    // treasury
    const treasury = await Treasury.new()
    await treasury.initialize(accessControlProxy.address)

    // VaultBuffer
    const vaultBuffer = await VaultBuffer.new();
    await vaultBuffer.initialize('USD Peg Token Ticket','tUSDi',vault.address,pegToken.address,accessControlProxy.address);

    await vault.initialize(accessControlProxy.address, treasury.address, exchangeAggregator.address, valueInterpreter.address);

    const vaultAdmin = await VaultAdmin.new()
    await vault.setAdminImpl(vaultAdmin.address)

    vault = await IVault.at(vault.address);
    await vault.setPegTokenAddress(pegToken.address);
    await vault.setVaultBufferAddress(vaultBuffer.address);
    // await vault.setRebaseThreshold(1);
    // await vault.setUnderlyingUnitsPerShare(new BigNumber(10).pow(18).toFixed());
    // await vault.setMaxTimestampBetweenTwoReported(604800);

    //20%
    await vault.setTrusteeFeeBps(2000)

    // await vault.addAsset(underlyingAddress)
    await vault.addAsset(MFC.USDC_ADDRESS);
    await vault.addAsset(MFC.USDT_ADDRESS);
    await vault.addAsset(MFC.DAI_ADDRESS);


    const harvester = await Harvester.new()
    await harvester.initialize(
        accessControlProxy.address,
        vault.address,
        MFC.USDT_ADDRESS,
        vault.address,
    )

    let addToVaultStrategies = new Array()
    let withdrawQueque = new Array()
    for (let i = 0; i < strategiesList.length; i++) {
        let strategyItem = strategiesList[i]
        let contractArtifact = hre.artifacts.require(strategyItem.contract)
        let strategy = await contractArtifact.new()
        let params = [vault.address, harvester.address,strategyItem.name,...strategyItem.customParams]
        await strategy.initialize(...params)
        withdrawQueque.push(strategy.address)
        addToVaultStrategies.push({
            strategy: strategy.address,
            profitLimitRatio: strategyItem["profitLimitRatio"],
            lossLimitRatio: strategyItem["lossLimitRatio"],
        })
    }
    //add to vault
    await vault.addStrategies(addToVaultStrategies, {
        from: governanceOwner,
    })
    await vault.setWithdrawalQueue(withdrawQueque)
    console.log("addStrategy ok")

    // If it is a test vault then top up the testAdapter with more wants coins to simulate the exchange operation of the vault
    console.log("This vault is a test vault and is being recharged for testAdapter....");
    const wants = await getStrategiesWants(vault.address)
    // If the wants coin does not contain USDT, top up extra
    if (wants.indexOf(MFC.USDT_ADDRESS) === -1) {
        const token = await ERC20.at(MFC.USDT_ADDRESS);
        const decimals = await token.decimals();
        // Recharge 1 billion
        const amount = new BigNumber(10).pow(decimals).multipliedBy(new BigNumber(10).pow(10));
        await topUpUsdtByAddress(amount, testAdapter.address)
    }
    for (const want of wants) {
        const token = await ERC20.at(want)
        const decimals = await token.decimals()

        // Recharge 1 billion
        const amount = new BigNumber(10).pow(decimals).multipliedBy(new BigNumber(10).pow(10))
        if (want === MFC.USDT_ADDRESS) {
            await topUpUsdtByAddress(amount, testAdapter.address)
        } else if (want === MFC.DAI_ADDRESS) {
            await topUpDaiByAddress(amount, testAdapter.address)
        } else if (want === MFC.TUSD_ADDRESS) {
            await topUpTusdByAddress(amount, testAdapter.address)
        } else if (want === MFC.USDC_ADDRESS) {
            await topUpUsdcByAddress(amount, testAdapter.address)
        } else if (want === MFC.BUSD_ADDRESS) {
            await topUpBusdByAddress(amount, testAdapter.address)
        } else if (want === MFC.MIM_ADDRESS) {
            await topUpMimByAddress(amount, testAdapter.address)
        } else if (want === MFC.LUSD_ADDRESS) {
            await topUpLusdByAddress(amount, testAdapter.address)
        } else if (want === MFC.USDP_ADDRESS) {
            await topUpUsdpByAddress(amount, testAdapter.address)
        } else {
            console.log(`WARN:Failed to top up testAdapter with enough [${want}] coins`)
        }
    }

    return {
        vault,
        vaultBuffer,
        pegToken,
        treasury,
        harvester,
        testAdapter,
        underlying,
        valueInterpreter,
        exchangePlatformAdapters,
        addToVaultStrategies,
        exchangeAggregator,
        aggregatedDerivativePriceFeed,
    }
}

async function addUnderlying (_underlyingAddress, ivault) {
    const underlying = await ERC20.at(_underlyingAddress)
    await ivault.addAsset(_underlyingAddress)
    return underlying
}

async function impersonates (targetAccounts) {
    for (i = 0; i < targetAccounts.length; i++) {
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [targetAccounts[i]],
        })
    }
}

const getTokenBalance = async (contractAddress, tokenArray) => {
    const promiseArray = tokenArray.map(async item => {
        const cst = await IERC20.at(item)
        return Promise.all([cst.name(), cst.balanceOf(contractAddress).then(v => v.toString())])
    })

    return Promise.all(promiseArray)
}

const getExchangePlatformAdapters = async exchangeAggregator => {
    const adapters = await exchangeAggregator.getExchangeAdapters()
    const exchangePlatformAdapters = {}
    for (let i = 0; i < adapters._identifiers.length; i++) {
        exchangePlatformAdapters[adapters._identifiers[i]] = adapters._exchangeAdapters[i]
    }
    return exchangePlatformAdapters
}

module.exports = {
    setupCoreProtocol,
    setupCoreProtocolWithMockValueInterpreter,
    addUnderlying,
    impersonates,
    getTokenBalance,
    getExchangePlatformAdapters,
}
