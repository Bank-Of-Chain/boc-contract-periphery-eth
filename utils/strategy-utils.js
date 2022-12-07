// === Utils === //
const BigNumber = require("bignumber.js")
const { map, uniq, flatten, isEmpty } = require("lodash")

// === Contracts === //
const Vault = hre.artifacts.require("IVault")
const IStrategy = hre.artifacts.require("IStrategy")
const IERC20 = hre.artifacts.require(
    "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol:IERC20Metadata",
)

/**
 * get Strategy Details
 * @param {address} vaultAddress vault address
 */
const getStrategyDetails = async vaultAddress => {
    const vault = await Vault.at(vaultAddress)
    const strategies = await vault.getStrategies()
    this.result = await Promise.all(
        strategies.map(async item => {
            const strategy = await IStrategy.at(item)
            const name = await strategy.name()
            const investTargetAssets = (await strategy.get3rdPoolAssets()).toString()
            const checkBalance = (await strategy.checkBalance()).toString()
            // const balanceOfLpToken = (await strategy.balanceOfLpTokens().then(array => array[0])).toString();
            const state = await vault.strategies(item);
            // Get a list of want coins for the strategy
            const wants = await strategy.getWants()
            const wantBalances = new Array()
            // Iterate through the want array, piecing together a display string for each coin, eg usdt:100000
            // Show multiple coins in a new line with the join() method
            const balanceOfWants = await Promise.all(
                map(wants, async wantItem => {
                    const wantConstract = await IERC20.at(wantItem)
                    const wantBalance = (await wantConstract.balanceOf(item)).toString()
                    wantBalances.push(wantBalance)
                    const wantName = await wantConstract.symbol()
                    return `${wantName}:${wantBalance}`
                }),
            )

            const {
                lastReport,
                totalDebt,
                profitLimitRatio,
                lossLimitRatio,
                enforceChangeLimit,
                lastClaim,
            } = state
            return {
                address: item,
                name,
                investTargetAssets,
                estimatedTotalAssetsToVault: checkBalance,
                lastReport,
                totalDebt,
                profitLimitRatio,
                lossLimitRatio,
                enforceChangeLimit,
                lastClaim,
                wantBalances,
                balanceOfWants,
            }
        }),
    ).catch(err => console.log("err:", err))
    this.log = () => {
        console.table(this.result, [
            "name",
            "totalDebt",
            "estimatedTotalAssetsToVault",
            "investTargetAssets",
            "balanceOfWants",
            "enforceChangeLimit",
            "investTargetAssets",
        ])
        return this
    }
    return this
}

/**
 * Get the balance of multiple coins on the address
 * @param {*} targetAddress target address
 * @param {*} addresses Address list of the query coins
 */
const getWantsBalance = async (targetAddress, addresses = []) => {
    if (isEmpty(targetAddress) || isEmpty(addresses))
        return new Error("must have targetAddress and addresses!")
    this.result = await Promise.all(
        addresses.map(async item => {
            const wantConstract = await IERC20.at(item)
            const name = await wantConstract.name()
            const balance = new BigNumber(await wantConstract.balanceOf(targetAddress)).toFormat()
            return {
                address: item,
                name,
                balance,
            }
        }),
    )
    this.log = () => {
        console.table(this.result, ["address", "name", "balance"])
        return this
    }
    return this
}

const getStrategiesWants = async vaultAddress => {
    const vault = await Vault.at(vaultAddress)
    const strategies = await vault.getStrategies()
    const result = await Promise.all(
        strategies.map(async item => {
            const strategy = await IStrategy.at(item)
            const wants = await strategy.getWants()
            return wants
        }),
    )
    return uniq(flatten(result))
}
module.exports = {
    getStrategyDetails,
    getStrategiesWants,
    getWantsBalance,
}
