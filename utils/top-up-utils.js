const { send } = require("@openzeppelin/test-helpers")

// === Constants === //
const addresses = require("./../config/address-config")

// === Utils === //
const BigNumber = require("bignumber.js")
const { isEmpty, isArray } = require("lodash")
const { balance } = require("@openzeppelin/test-helpers")

// === Contracts === //
const IERC20_DAI = artifacts.require("IERC20_DAI")
const IERC20_USDT = artifacts.require("IERC20_USDT")
const IERC20_USDC = artifacts.require("IERC20_USDC")
const IERC20_TUSD = artifacts.require("IERC20_TUSD")
const IERC20_LUSD = artifacts.require("IERC20_LUSD")
const IERC20_SUSD = artifacts.require("IERC20_SUSD")
const IEREC20Mint = artifacts.require("IEREC20Mint")
const IERC20_STETH = artifacts.require("IERC20_STETH")
const IERC20_WETH = artifacts.require("IERC20_WETH")
const IERC20_WSTETH = artifacts.require("IERC20_WSTETH")
const IPool = artifacts.require("IPool")
const IERC20_ROCKET_POOL_ETH = artifacts.require("IERC20_ROCKET_POOL_ETH")
const RocketDepositPoolInterface = artifacts.require("RocketDepositPoolInterface")
const IRewardEthToken = artifacts.require("IRewardEthToken")

/**
 * impersonates
 * @param {*} targetAccounts
 * @returns
 */
async function impersonates (targetAccounts) {
    if (!isArray(targetAccounts)) return new Error("must be a array")
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: targetAccounts,
    })
    return async () => {
        await hre.network.provider.request({
            method: "hardhat_stopImpersonatingAccount",
            params: targetAccounts,
        })
    }
}

/**
 * Top up a specified amount of eth for the address(default 10 * 10 ** 18)
 * @param {*} reviver
 * @param {*} amount
 */
const sendEthers = async (reviver, amount = new BigNumber(10 * 10 ** 18)) => {
    if (!BigNumber.isBigNumber(amount)) return new Error("must be a bignumber.js object")
    await network.provider.send("hardhat_setBalance", [reviver, `0x${amount.toString(16)}`])
}

const removeSTETHStakeLimit = async () => {
    const TOKEN = await IERC20_STETH.at(addresses.stETH_ADDRESS)
    const masterMinter = "0x2e59A20f205bB85a89C53f1936454680651E618e"
    await sendEthers(masterMinter)
    const callback = await impersonates([masterMinter])
    await TOKEN.removeStakingLimit({ from: masterMinter })
    await callback()
}

/**
 *
 */
const setUsdcMinter = async (nextMinter, minterAmount) => {
    const TOKEN = await IERC20_USDC.at(addresses.USDC_ADDRESS)
    const masterMinter = await TOKEN.masterMinter()

    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await sendEthers(masterMinter)

    const callback = await impersonates([masterMinter])
    const isMinterBefore = await TOKEN.isMinter(nextMinter)
    console.log("USDC isMinter before=", isMinterBefore)
    await TOKEN.configureMinter(nextMinter, minterAmount, { from: masterMinter })
    const isMinterAfter = await TOKEN.isMinter(nextMinter)
    console.log("USDC isMinter after=", isMinterAfter)
    await callback()
}

/**
 * recharge core method
 */
async function topUpMain (token, tokenHolder, toAddress, amount) {
    const TOKEN = await IEREC20Mint.at(token)
    const tokenName = await TOKEN.name()
    const tokenSymbol = await TOKEN.symbol()
    const farmerBalance = await TOKEN.balanceOf(tokenHolder)
    console.log(
        `[Transfer]Start recharge ${tokenName}，Balance of token holder：%s`,
        new BigNumber(farmerBalance).toFormat(),
    )

    amount = amount.gt ? amount : new BigNumber(amount)
    // If the amount to be recharged is greater than the current account balance, the recharge is for the largest balance
    const nextAmount = amount.gt(farmerBalance) ? new BigNumber(farmerBalance) : amount
    await TOKEN.transfer(toAddress, nextAmount, {
        from: tokenHolder,
    })
    console.log(`${tokenName},${tokenSymbol} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return nextAmount
}

/**
 * The core method of recharging, implemented through mint, enables the maximum amount of currency to be recharged
 */
async function topUpMainV2 (token, toAddress, amount) {
    const TOKEN = await IEREC20Mint.at(token)
    const tokenName = await TOKEN.name()
    const tokenSymbol = await TOKEN.symbol()
    const tokenOwner = await TOKEN.owner()

    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    const accounts = await ethers.getSigners()
    await send.ether(accounts[0].address, tokenOwner, 10 * 10 ** 18)

    const nextAmount = new BigNumber(amount)
    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())
    await impersonates([tokenOwner])
    await TOKEN.issue(nextAmount, {
        from: tokenOwner,
    })
    await TOKEN.transfer(toAddress, nextAmount, {
        from: tokenOwner,
    })
    console.log(`${tokenName},${tokenSymbol} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 * New currency recharge core method, implemented through mint, adapted to owner and mint methods, same level as v2
 */
async function topUpMainV2_1 (token, toAddress, amount) {
    const TOKEN = await IEREC20Mint.at(token)
    const tokenName = await TOKEN.name()
    const tokenSymbol = await TOKEN.symbol()
    const tokenOwner = await TOKEN.owner()
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    const accounts = await ethers.getSigners()
    await send.ether(accounts[0].address, tokenOwner, 10 * 10 ** 18)
    const nextAmount = new BigNumber(amount)
    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())
    await impersonates([tokenOwner])
    await TOKEN.mint(toAddress, nextAmount, {
        from: tokenOwner,
    })
    console.log(`${tokenName},${tokenSymbol} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 *  New currency recharge core method, implemented through mint, adapted to owner and mint methods, same level as v2
 */
async function topUpMainV2_2 (token, toAddress, amount) {
    const TOKEN = await IEREC20Mint.at(token)
    const tokenName = await TOKEN.name()
    const tokenSymbol = await TOKEN.symbol()
    const tokenOwner = await TOKEN.supplyController()
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    const accounts = await ethers.getSigners()
    await send.ether(accounts[0].address, tokenOwner, 10 * 10 ** 18)

    const nextAmount = new BigNumber(amount)
    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())
    await impersonates([tokenOwner])

    await TOKEN.increaseSupply(nextAmount, {
        from: tokenOwner,
    })
    await TOKEN.transfer(toAddress, nextAmount, {
        from: tokenOwner,
    })
    console.log(`${tokenName},${tokenSymbol} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 * Top up a certain amount of USDT for a certain address(default 10 ** 6)
 */
async function topUpUsdtByAddress (amount = new BigNumber(10 * 6), toAddress) {
    if (isEmpty(toAddress)) return 0
    const TOKEN = await IERC20_USDT.at(addresses.USDT_ADDRESS)
    const tokenOwner = await TOKEN.owner()
    const tokenName = await TOKEN.name()
    const nextAmount = new BigNumber(amount)
    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())

    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await sendEthers(tokenOwner)
    const callback = await impersonates([tokenOwner])

    await TOKEN.issue(nextAmount, {
        from: tokenOwner,
    })
    await TOKEN.transfer(toAddress, nextAmount, {
        from: tokenOwner,
    })

    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    await callback()
    return amount
}

/**
 * Top up a certain amount of DAI for a certain address(default 10 ** 18)
 */
async function topUpDaiByAddress (amount = new BigNumber(10 ** 18), toAddress) {
    if (isEmpty(toAddress)) return 0
    const TOKEN = await IERC20_DAI.at(addresses.DAI_ADDRESS)
    const tokenName = await TOKEN.name()
    const tokenOwner = "0x9759a6ac90977b93b58547b4a71c78317f391a28"
    const nextAmount = new BigNumber(amount)
    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())

    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await sendEthers(tokenOwner)

    const callback = await impersonates([tokenOwner])
    await TOKEN.mint(toAddress, nextAmount, {
        from: tokenOwner,
    })

    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    await callback()
    return amount
}

/**
 * Top up a certain amount of USDC for a certain address(default 10 ** 6)
 */
async function topUpUsdcByAddress (amount = new BigNumber(10 ** 6), toAddress) {
    if (isEmpty(toAddress)) return 0
    const accounts = await ethers.getSigners()
    const TOKEN = await IERC20_USDC.at(addresses.USDC_ADDRESS)
    const tokenName = await TOKEN.name()
    const nextAmount = new BigNumber(amount)
    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())

    await setUsdcMinter(accounts[0].address, amount)

    await TOKEN.mint(toAddress, nextAmount, { from: accounts[0].address })

    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 * Top up a certain amount of UST for a certain address(default 10 ** 18)
 */
async function topUpUstByAddress (amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const accounts = await ethers.getSigners()
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await send.ether(accounts[0].address, addresses.UST_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.UST_WHALE_ADDRESS])
    return topUpMain(addresses.UST_ADDRESS, addresses.UST_WHALE_ADDRESS, to, amount)
}

/**
 * Top up a certain amount of BUSD for a certain address(default 10 ** 18)
 */
async function topUpBusdByAddress (amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    return topUpMainV2_2(addresses.BUSD_ADDRESS, to, amount)
}

/**
 * Top up a certain amount of MIM for a certain address(default 10 ** 18)
 */
async function topUpMimByAddress (amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    return topUpMainV2_1(addresses.MIM_ADDRESS, to, amount)
}

/**
 * Top up a certain amount of TUSD for a certain address(default 10 ** 18)
 */
async function topUpTusdByAddress (amount = new BigNumber(10 ** 18), toAddress) {
    if (isEmpty(toAddress)) return 0
    const TOKEN = await IERC20_TUSD.at(addresses.TUSD_ADDRESS)
    const tokenName = await TOKEN.name()
    const tokenOwner = await TOKEN.owner()
    const nextAmount = new BigNumber(amount)
    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())

    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await sendEthers(tokenOwner)

    const callback = await impersonates([tokenOwner])
    await TOKEN.mint(toAddress, nextAmount, {
        from: tokenOwner,
    })

    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    await callback()
    return amount
}
/**
 * Top up a certain amount of USDP for a certain address(default 10 ** 18)
 */
async function topUpUsdpByAddress (amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    return topUpMainV2_2(addresses.USDP_ADDRESS, to, amount)
}
/**
 * Top up a certain amount of LUSD for a certain address(default 10 ** 18)
 */
async function topUpLusdByAddress (amount = new BigNumber(10 ** 18), toAddress) {
    if (isEmpty(toAddress)) return 0
    const TOKEN = await IERC20_LUSD.at(addresses.LUSD_ADDRESS)
    const tokenName = await TOKEN.name()
    const tokenOwner = await TOKEN.borrowerOperationsAddress()
    const nextAmount = new BigNumber(amount)
    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())

    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await sendEthers(tokenOwner)

    const callback = await impersonates([tokenOwner])
    await TOKEN.mint(toAddress, nextAmount, {
        from: tokenOwner,
    })

    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    await callback()
    return amount
}

/**
 * Top up a certain amount of DODO for a certain address(default 10 ** 18)
 */
async function topUpDodoCoinByAddress (amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const accounts = await ethers.getSigners()
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await send.ether(accounts[0].address, addresses.DODO_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.DODO_WHALE_ADDRESS])
    return topUpMain(addresses.DODO_ADDRESS, addresses.DODO_WHALE_ADDRESS, to, amount)
}

/**
 * Top up a certain amount of SUSHI for a certain address(default 10 ** 18)
 */
async function topUpSushiByAddress (amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const accounts = await ethers.getSigners()
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await send.ether(accounts[0].address, addresses.SUSHI_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.SUSHI_WHALE_ADDRESS])
    return topUpMain(addresses.SUSHI_ADDRESS, addresses.SUSHI_WHALE_ADDRESS, to, amount)
}

/**
 * Top up a certain amount of CRV for a certain address(default 10 ** 18)
 */
async function topUpCrvByAddress (amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const accounts = await ethers.getSigners()
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await send.ether(accounts[0].address, addresses.CRV_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.CRV_WHALE_ADDRESS])
    return topUpMain(addresses.CRV_ADDRESS, addresses.CRV_WHALE_ADDRESS, to, amount)
}
/**
 * Top up a certain amount of CVX for a certain address(default 10 ** 18)
 */
async function topUpCvxByAddress (amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const accounts = await ethers.getSigners()
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await send.ether(accounts[0].address, addresses.CVX_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.CVX_WHALE_ADDRESS])
    return topUpMain(addresses.CVX_ADDRESS, addresses.CVX_WHALE_ADDRESS, to, amount)
}

/**
 * Top up a certain amount of BAL for a certain address(default 10 ** 18)
 */
async function topUpBalByAddress (amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const accounts = await ethers.getSigners()
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await send.ether(accounts[0].address, addresses.BAL_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.BAL_WHALE_ADDRESS])
    return topUpMain(addresses.BAL_ADDRESS, addresses.BAL_WHALE_ADDRESS, to, amount)
}

/**
 *  Top up a certain amount of ETH for a certain address(default 10 ** 18)
 */
 async function topUpEthByAddress(amount = new BigNumber(10 * 18), to) {
    if (isEmpty(to)) return 0
    const tokenName = "ETH"
    const nextAmount = new BigNumber(amount)
    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())
    const beforeBalance = await balance.current(to)
    await sendEthers(to, nextAmount.plus(beforeBalance).toFormat())
    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await await balance.current(to)).toFormat())
    console.log(`${tokenName} recharge completed`)
}


/**
 * Top up a certain amount of WETH for a certain address(default 10 ** 18)
 */
 async function topUpWETHByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const TOKEN = await IERC20_WETH.at(addresses.WETH_ADDRESS)
    const tokenName = await TOKEN.name()
    const tokenSymbol = await TOKEN.symbol()
    const accounts = await ethers.getSigners()
    const account0 = accounts[0].address

    const nextAmount = new BigNumber(amount)

    await topUpEthByAddress(nextAmount, account0)

    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())

    await TOKEN.deposit({ from: account0, value: nextAmount })

    await TOKEN.transfer(to, nextAmount, {
        from: account0,
    })

    console.log(`${tokenName},${tokenSymbol} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(to)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 * Top up a certain amount of stETH for a certain address(default 10 ** 18)
 */
 async function topUpSTETHByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const TOKEN = await IERC20_STETH.at(addresses.stETH_ADDRESS)
    const tokenName = await TOKEN.name()
    const tokenSymbol = await TOKEN.symbol()
    const accounts = await ethers.getSigners()
    const account0 = accounts[0].address

    // mint more
    const nextAmount = new BigNumber(new BigNumber(amount).multipliedBy(101).div(100).toFixed(0,1));

    await topUpEthByAddress(nextAmount, account0)

    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())

    await removeSTETHStakeLimit()

    await TOKEN.submit(account0, { from: account0, value: nextAmount })
    await TOKEN.transfer(to, amount, {
        from: account0,
    })

    console.log(`${tokenName},${tokenSymbol} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(to)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 * Top up a certain amount of wstETH for a certain address(default 10 ** 18)
 */
async function topUpWstEthByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const TOKEN = await IERC20_WSTETH.at(addresses.wstETH_ADDRESS)
    const tokenName = await TOKEN.name()
    const tokenSymbol = await TOKEN.symbol()
    const stEthPerToken = await TOKEN.stEthPerToken()
    const accounts = await ethers.getSigners()
    const account0 = accounts[0].address
    const nextAmount = new BigNumber(amount)
    const stEthAmount = nextAmount.multipliedBy(stEthPerToken).div(1e18)

    await topUpSTETHByAddress(stEthAmount, account0)

    console.log(`[Mint]Start recharge ${tokenName}，recharge amount：%s`, nextAmount.toFormat())

    const stETHTOKEN = await IERC20_STETH.at(addresses.stETH_ADDRESS)
    const balanceOfSTETH = await stETHTOKEN.balanceOf(account0)
    await stETHTOKEN.approve(addresses.wstETH_ADDRESS, 0, { from: account0 })
    await stETHTOKEN.approve(addresses.wstETH_ADDRESS, balanceOfSTETH, { from: account0 })
    await TOKEN.wrap(balanceOfSTETH, { from: account0 })

    await TOKEN.transfer(to, amount, {
        from: account0,
    })

    console.log(`${tokenName},${tokenSymbol} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(to)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 * Top up a certain amount of rocketPoolETH for a certain address(default 10 ** 18)
 */
async function topUpRocketPoolEthByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0

    const TOKEN = await IERC20_ROCKET_POOL_ETH.at(addresses.rocketPoolETH_ADDRESS)
    const tokenName = await TOKEN.name()
    const tokenSymbol = await TOKEN.symbol()
    const accounts = await ethers.getSigners()
    const account0 = accounts[0].address
    const nextAmount = new BigNumber(new BigNumber(amount).multipliedBy(12).dividedBy(10).toFixed(0,1));

    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await topUpEthByAddress(nextAmount, account0);
    console.log(`[Stake] Start recharge ${tokenSymbol}，recharge amount：%s`, amount.toString())
    const rocketPool  = await RocketDepositPoolInterface.at('0x2cac916b2A963Bf162f076C0a8a4a8200BCFBfb4');
    await rocketPool.deposit({value: nextAmount,from:account0});
    await TOKEN.transfer(to, amount, {
        from: account0,
    })
    console.log(`${tokenName},${tokenSymbol} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(to)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount;
}

/**
 * Top up a certain amount of sETH for a certain address(default 10 ** 18)
 */
async function topUpSEthByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await topUpEthByAddress(addresses.sETH_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.sETH_WHALE_ADDRESS])
    return topUpMain(addresses.sETH_ADDRESS, addresses.sETH_WHALE_ADDRESS, to, amount)
}

/**
 * Top up a certain amount of sETH2 for a certain address(default 10 ** 18)
 */
async function topUpSEth2ByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    const TOKEN = await IEREC20Mint.at(addresses.sETH2_ADDRESS)
    const tokenName = await TOKEN.name()
    const tokenSymbol = await TOKEN.symbol()

    const accounts = await ethers.getSigners()
    const account0 = accounts[0].address
    const nextAmount = new BigNumber(new BigNumber(amount).multipliedBy(12).dividedBy(10).toFixed(0,1));
    await topUpEthByAddress(nextAmount, account0);

    console.log(`[Stake] Start recharge ${tokenSymbol}，recharge amount：%s`, amount.toString())
    const stakePool = await IPool.at('0xC874b064f465bdD6411D45734b56fac750Cda29A');
    await stakePool.stake({value: nextAmount,from:account0});
    await TOKEN.transfer(to, amount, {
        from: account0,
    });

    console.log(`${tokenName},${tokenSymbol} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(to)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 * Top up a certain amount of rETH2 for a certain address(default 10 ** 18)
 */
async function topUpREth2ByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await topUpEthByAddress(addresses.rETH2_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.rETH2_WHALE_ADDRESS])
    return topUpMain(addresses.rETH2_ADDRESS, addresses.rETH2_WHALE_ADDRESS, to, amount)
}

/**
 * Top up a certain amount of swise for a certain address(default 10 ** 18)
 */
async function topUpSwiseByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0;
    const accounts = await ethers.getSigners();
    await send.ether(accounts[0].address, addresses.SWISE_WHALE_ADDRESS, 10 ** 18);
    await impersonates([addresses.SWISE_WHALE_ADDRESS]);
    return topUpMain(addresses.SWISE_ADDRESS, addresses.SWISE_WHALE_ADDRESS, to, amount);
}

async function topUpGusdByAddress(amount = new BigNumber(10 ** 2), to) {
    if (isEmpty(to)) return 0
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await topUpEthByAddress(addresses.GUSD_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.GUSD_WHALE_ADDRESS])
    return topUpMain(addresses.GUSD_ADDRESS, addresses.GUSD_WHALE_ADDRESS, to, amount)
}

async function topUpSusdByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await topUpEthByAddress(addresses.SUSD_WHALE_ADDRESS, 10 ** 18)
    await impersonates([addresses.SUSD_WHALE_ADDRESS])
    return topUpMain(addresses.SUSD_ADDRESS, addresses.SUSD_WHALE_ADDRESS, to, amount)
}

/**
 * tranfer Back Dai
 * @param {*} address
 */
const tranferBackDai = async address => {
    const underlying = await IEREC20Mint.at(addresses.DAI_ADDRESS)
    const tokenName = await underlying.name()
    const underlyingWhale = addresses.DAI_WHALE_ADDRESS
    await impersonates([underlyingWhale])
    const farmerBalance = await underlying.balanceOf(address)
    await underlying.transfer(underlyingWhale, farmerBalance, {
        from: address,
    })
    console.log(
        `${tokenName} balance of the whale：` +
            new BigNumber(await underlying.balanceOf(underlyingWhale)).toFormat(),
    )
}

/**
 * tranfer Back Usdc
 * @param {*} address
 */
const tranferBackUsdc = async address => {
    const underlying = await IEREC20Mint.at(addresses.USDC_ADDRESS)
    const tokenName = await underlying.name()
    const underlyingWhale = addresses.USDC_WHALE_ADDRESS
    await impersonates([underlyingWhale])
    const farmerBalance = await underlying.balanceOf(address)
    await underlying.transfer(underlyingWhale, farmerBalance, {
        from: address,
    })
    console.log(
        `${tokenName} balance of the whale：` +
            new BigNumber(await underlying.balanceOf(underlyingWhale)).toFormat(),
    )
}

/**
 * tranfer Back Usdt
 * @param {*} address
 */
const tranferBackUsdt = async address => {
    const underlying = await IEREC20Mint.at(addresses.USDT_ADDRESS)
    const tokenName = await underlying.name()
    const underlyingWhale = addresses.USDT_WHALE_ADDRESS
    await impersonates([underlyingWhale])
    const farmerBalance = await underlying.balanceOf(address)
    await underlying.transfer(underlyingWhale, farmerBalance, {
        from: address,
    })
    console.log(
        `${tokenName} balance of the whale：` +
            new BigNumber(await underlying.balanceOf(underlyingWhale)).toFormat(),
    )
}

module.exports = {
    topUpMain,
    topUpUsdtByAddress,
    topUpDaiByAddress,
    topUpBusdByAddress,
    topUpUsdcByAddress,
    topUpUstByAddress,
    topUpLusdByAddress,
    topUpTusdByAddress,
    topUpMimByAddress,
    topUpUsdpByAddress,
    topUpDodoCoinByAddress,
    topUpSushiByAddress,
    topUpCrvByAddress,
    topUpCvxByAddress,
    topUpBalByAddress,
    topUpEthByAddress,
    topUpWETHByAddress,
    topUpSTETHByAddress,
    topUpWstEthByAddress,
    topUpRocketPoolEthByAddress,
    topUpSEthByAddress,
    topUpSEth2ByAddress,
    topUpREth2ByAddress,
    topUpSwiseByAddress,
    topUpGusdByAddress,
    topUpSusdByAddress,
    tranferBackUsdc,
    tranferBackDai,
    tranferBackUsdt,
    impersonates,
    topUpMainV2,
    topUpMainV2_1,
    topUpMainV2_2,
    sendEthers,
}
