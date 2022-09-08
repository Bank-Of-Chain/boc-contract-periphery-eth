const {
    CHAINLINK
} = require("../config/mainnet-fork-test-config")
const {
    impersonates
} = require('../utils/contract-utils-usd')
const {
    send
} = require('@openzeppelin/test-helpers')

const Vault = hre.artifacts.require('Vault')
const ValueInterpreter = hre.artifacts.require('ValueInterpreter')
const ChainlinkPriceFeed = hre.artifacts.require('ChainlinkPriceFeed')

// const admin = '0x4fd4c98babee5e22219c573713308329da40649d'
const vaultAddr = '0x30D120f80D60E7b58CA9fFaf1aaB1815f000B7c3'

const main = async () => {
    let vault
    let valueInterpreter
    let chainlinkPriceFeed

    vault = await Vault.at(vaultAddr);
    const valueInterpreterAddr = await vault.valueInterpreter()
    valueInterpreter = await ValueInterpreter.at(valueInterpreterAddr)
    const chainlinkPriceFeedAddr = await valueInterpreter.getPrimitivePriceFeed()

    chainlinkPriceFeed = await ChainlinkPriceFeed.at(chainlinkPriceFeedAddr)
    
    // await impersonates([admin])
    const accounts = await ethers.getSigners()
    const nextManagement = accounts[0].address
    // await send.ether(nextManagement, admin, 10 * (10 ** 18))
    
    let primitives = []
    let aggregators = []
    let heartbeats = []

    for (const key in CHAINLINK.aggregators) {
        if (Object.hasOwnProperty.call(CHAINLINK.aggregators, key)) {
            const aggregator = CHAINLINK.aggregators[key]
            if (await chainlinkPriceFeed.isSupportedAsset(aggregator.primitive)) {
                primitives.push(aggregator.primitive)
                aggregators.push(aggregator.aggregator)
                heartbeats.push(60 * 60 * 24 * 365)
                console.log(`will update ${aggregator.primitive} aggregator`)
            }
        }
    }
    
    await chainlinkPriceFeed.updatePrimitives(primitives, aggregators, heartbeats, {
        from: nextManagement
    })

    await chainlinkPriceFeed.setEthUsdAggregator('0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', 60 * 60 * 24 * 365, {
        from: nextManagement
    })
    
    console.log('update aggregator successfully')
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });