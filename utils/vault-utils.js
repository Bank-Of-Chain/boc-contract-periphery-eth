const Vault = hre.artifacts.require("IVault")
const IStrategy = hre.artifacts.require("IStrategy")
const IERC20 = hre.artifacts.require(
    "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol:IERC20Metadata",
)
const ERC20 = hre.artifacts.require("@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20")

// === Constants === //
const MFC = require("../config/mainnet-fork-test-config")

// === Utils === //
const { lendSwap } = require("piggy-finance-utils")
const { mapKeys, map, filter, isEmpty } = require("lodash")
const { ethers } = require("hardhat")
const { BigNumber } = ethers

lendSwap.setUnderlying(MFC.USDT_ADDRESS)

const depositVault = async function (_farmer, _underlying, _vault, _amount) {
    await _underlying.approve(_vault.address, 0, {
        from: _farmer,
    })
    await _underlying.approve(_vault.address, _amount, {
        from: _farmer,
    })
    let _assets = new Array()
    _assets.push(_underlying.address)
    let _amounts = new Array()
    _amounts.push(_amount)
    let _minimumUsdiAmount = 0

    let tx = await _vault.mint(_assets, _amounts, _minimumUsdiAmount, {
        from: _farmer,
    })
    const gasUsed = tx.receipt.gasUsed
    console.log("depositVault gasUsed: %d", gasUsed)
}

const depositMultCoinsToVault = async (_farmer, _vault, _underlyingArray, _amountsArray) => {
    let _assets = new Array()
    for (let i = 0; i < _underlyingArray.length; i++) {
        console.log(_underlyingArray[i].address)
        _assets.push(_underlyingArray[i].address)

        await _underlyingArray[i].approve(_vault.address, 0, {
            from: _farmer,
        })

        await _underlyingArray[i].approve(_vault.address, _amountsArray[i], {
            from: _farmer,
        })
    }

    let _minimumUsdiAmount = 0
    await _vault.mint(_assets, _amountsArray, _minimumUsdiAmount, {
        from: _farmer,
    })
}

/**
 * get Vault Details
 */
const getVaultDetails = async vaultAddress => {
    const contracts = await Vault.at(vaultAddress)
    const usdt = await IERC20.at(MFC.USDT_ADDRESS)
    const usdtBalance = (await usdt.balanceOf(vaultAddress)).toString()
    const totalAssets = (await contracts.totalAssets()).toString()
    const totalDebt = (await contracts.totalDebt()).toString()

    this.result = {
        totalAssets,
        totalDebt,
        usdtBalance,
    }
    this.log = () => {
        console.table(this.result)
        return this
    }
    return this
}

/**
 * withdraw
 * @param {string} vaultAddress vault address
 * @param {string} userAddress account address
 * @param {string} assetAddress asset address
 * @param {number} amount number of withdraw
 * @param {any} exchangePlatformAdapters exchange platform adapters
 */
const withdraw = async (
    vaultAddress,
    userAddress,
    assetAddress,
    amount,
    exchangePlatformAdapters,
) => {
    const vault = await Vault.at(vaultAddress)

    const resp = await vault.burn.call(amount, assetAddress, 0, false, [], {
        from: userAddress,
    })

    const tokens = resp[0]
    const amounts = resp[1]
    const exchangeArray = await Promise.all(
        map(tokens, async (tokenItem, index) => {
            const exchangeAmounts = amounts[index].toString()
            if (tokenItem === assetAddress) {
                return
            }
            return {
                fromToken: tokenItem,
                toToken: assetAddress,
                fromAmount: exchangeAmounts,
                exchangeParam: {
                    platform: exchangePlatformAdapters.testAdapter,
                    method: 0,
                    encodeExchangeArgs: "0x",
                    slippage: 0,
                    oracleAdditionalSlippage: 0,
                },
            }
        }),
    )
    const exchangeArrayNext = filter(exchangeArray, i => !isEmpty(i))

    let tx = await vault.burn(amount, assetAddress, 0, true, exchangeArrayNext, {
        from: userAddress,
    })

    const gasUsed = tx.receipt.gasUsed
    console.log("withdraw gasUsed: %d", gasUsed)
}

/**
 * withdraw by minimum
 * @param {string} vaultAddress vault address
 * @param {string} userAddress account address
 * @param {string} assetAddress asset address
 * @param {number} amount Number of usdi withdraw
 * @param {number} minimum The minimum number of stable coins that can be accepted
 * @param {any} exchangePlatformAdapters exchange platform adapters
 */
const withdrawByMinimum = async (
    vaultAddress,
    userAddress,
    assetAddress,
    amount,
    minimum,
    exchangePlatformAdapters,
) => {
    const vault = await Vault.at(vaultAddress)

    const resp = await vault.burn.call(amount, assetAddress, minimum, false, [], {
        from: userAddress,
    })

    const tokens = resp[0]
    const amounts = resp[1]
    const exchangeArray = await Promise.all(
        map(tokens, async (tokenItem, index) => {
            const exchangeAmounts = amounts[index].toString()
            if (tokenItem === assetAddress) {
                return
            }
            return {
                fromToken: tokenItem,
                toToken: assetAddress,
                fromAmount: exchangeAmounts,
                exchangeParam: {
                    platform: exchangePlatformAdapters.testAdapter,
                    method: 0,
                    encodeExchangeArgs: "0x",
                    slippage: 0,
                    oracleAdditionalSlippage: 0,
                },
            }
        }),
    )
    const exchangeArrayNext = filter(exchangeArray, i => !isEmpty(i))

    await vault.burn(amount, assetAddress, minimum, true, exchangeArrayNext, {
        from: userAddress,
    })
}

/**
 * lend
 * @param {string} strategyAddress strategy address
 * @param {string} vaultAddress vault address
 * @param {number} amount Amount of investment
 * @param {any} exchangePlatformAdapters exchange platform adapters
 */
const lend = async (strategyAddress, vaultAddress, amount, exchangePlatformAdapters) => {
    // const slipper = 30;
    // const underlying = await ERC20.at(MFC.USDT_ADDRESS);
    const vault = await Vault.at(vaultAddress)
    const strategy = await IStrategy.at(strategyAddress)
    // 预言机
    const yyj = (token, value, decimals) => value.mul(BigNumber.from(10).pow(decimals))

    const wantsInfo = await strategy.getWantsInfo()

    let strateAspect = new Array()

    const tokenMap = mapKeys(
        await Promise.all(
            map(wantsInfo[0], async (item, index) => {
                const token = await ERC20.at(item)
                strateAspect[index] = { token: item, aspect: wantsInfo[1][index].toString() }
                return {
                    decimals: parseInt((await token.decimals()).toString()),
                    symbol: await token.symbol(),
                    address: item,
                }
            }),
        ),
        "address",
    )
    tokenMap[MFC.USDT_ADDRESS] = {
        decimals: 6,
        symbol: "USDT",
        address: MFC.USDT_ADDRESS,
    }

    let path = await lendSwap.getAspectArray(BigNumber.from(amount), strateAspect, yyj, tokenMap)
    if (path.length < 1) {
        path = new Array()
        path.push({
            fromToken: MFC.USDT_ADDRESS,
            toToken: MFC.USDT_ADDRESS,
            fromAmount: BigNumber.from(amount),
        })
    }
    const nextPath = map(path, i => {
        return {
            ...i,
            exchangeParam: {
                platform: exchangePlatformAdapters.testAdapter,
                method: 0,
                encodeExchangeArgs: "0x",
                slippage: 0,
                oracleAdditionalSlippage: 0,
            },
        }
    })
    const tx = await vault.lend(strategyAddress, nextPath).catch(error => {
        console.error(`兑换异常：`, strategyAddress, nextPath, error)
    })
    return tx
}

const wait = secs => new Promise(resolve => setTimeout(resolve, secs))

module.exports = {
    withdraw,
    withdrawByMinimum,
    lend,
    depositVault,
    depositMultCoinsToVault,
    getVaultDetails,
    wait,
}
