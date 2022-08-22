const { send } = require("@openzeppelin/test-helpers")

// === Constants === //
const addresses = require("./../config/address-config")

// === Utils === //
const BigNumber = require("bignumber.js")
const { isEmpty, isArray } = require("lodash")

// === Contracts === //
const IERC20_DAI = artifacts.require("IERC20_DAI")
const IERC20_USDT = artifacts.require("IERC20_USDT")
const IERC20_USDC = artifacts.require("IERC20_USDC")
const IERC20_TUSD = artifacts.require("IERC20_TUSD")
const IERC20_LUSD = artifacts.require("IERC20_LUSD")
const IEREC20Mint = artifacts.require("IEREC20Mint")

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
    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return nextAmount
}

/**
 * The core method of recharging, implemented through mint, enables the maximum amount of currency to be recharged
 */
async function topUpMainV2 (token, toAddress, amount) {
    const TOKEN = await IEREC20Mint.at(token)
    const tokenName = await TOKEN.name()
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
    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 * New currency recharge core method, implemented through mint, adapted to owner and mint methods, same level as v2
 */
async function topUpMainV2_1 (token, toAddress, amount) {
    const TOKEN = await IEREC20Mint.at(token)
    const tokenName = await TOKEN.name()
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
    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
    console.log(`${tokenName} recharge completed`)
    return amount
}

/**
 *  New currency recharge core method, implemented through mint, adapted to owner and mint methods, same level as v2
 */
async function topUpMainV2_2 (token, toAddress, amount) {
    const TOKEN = await IEREC20Mint.at(token)
    const tokenName = await TOKEN.name()
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
    console.log(`${tokenName} Balance of toAddress：` + new BigNumber(await TOKEN.balanceOf(toAddress)).toFormat())
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
    if (isEmpty(to)) return 0;
    const accounts = await ethers.getSigners();
    // send ETH to the account
    await send.ether(accounts[0].address, to, 100 * (10 ** 18));
}


/**
 * Top up a certain amount of WETH for a certain address(default 10 ** 18)
 */
 async function topUpWETHByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0;
    const accounts = await ethers.getSigners();
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await send.ether(accounts[0].address, addresses.WETH_WHALE_ADDRESS, 10 ** 18);
    await impersonates([addresses.WETH_WHALE_ADDRESS]);

    return topUpMain(addresses.WETH_ADDRESS, addresses.WETH_WHALE_ADDRESS, to, amount);
}

/**
 * Top up a certain amount of stETH for a certain address(default 10 ** 18)
 */
 async function topUpSTETHByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0;
    const accounts = await ethers.getSigners();
    // Send 10 ETH to the wallet account to make sure the transaction of withdrawing money from it works.
    await send.ether(accounts[0].address, addresses.stETH_WHALE_ADDRESS, 10 ** 18);
    await impersonates([addresses.stETH_WHALE_ADDRESS]);

    return topUpMain(addresses.stETH_ADDRESS, addresses.stETH_WHALE_ADDRESS, to, amount);
}

/**
 * Top up a certain amount of wstETH for a certain address(default 10 ** 18)
 */
async function topUpWstEthByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0;
    const accounts = await ethers.getSigners();
    await send.ether(accounts[0].address, addresses.wstETH_WHALE_ADDRESS, 10 ** 18);
    await impersonates([addresses.wstETH_WHALE_ADDRESS]);
    return topUpMain(addresses.wstETH_ADDRESS, addresses.wstETH_WHALE_ADDRESS, to, amount);
}

/**
 * Top up a certain amount of rocketPoolETH for a certain address(default 10 ** 18)
 */
async function topUpRocketPoolEthByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0;
    const accounts = await ethers.getSigners();
    await send.ether(accounts[0].address, addresses.rocketPoolETH_WHALE_ADDRESS, 10 ** 18);
    await impersonates([addresses.rocketPoolETH_WHALE_ADDRESS]);
    return topUpMain(addresses.rocketPoolETH_ADDRESS, addresses.rocketPoolETH_WHALE_ADDRESS, to, amount);
}

/**
 * Top up a certain amount of sETH for a certain address(default 10 ** 18)
 */
async function topUpSEthByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0;
    const accounts = await ethers.getSigners();
    await send.ether(accounts[0].address, addresses.sETH_WHALE_ADDRESS, 10 ** 18);
    await impersonates([addresses.sETH_WHALE_ADDRESS]);
    return topUpMain(addresses.sETH_ADDRESS, addresses.sETH_WHALE_ADDRESS, to, amount);
}

/**
 * Top up a certain amount of sETH2 for a certain address(default 10 ** 18)
 */
async function topUpSEth2ByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0;
    const accounts = await ethers.getSigners();
    await send.ether(accounts[0].address, addresses.sETH2_WHALE_ADDRESS, 10 ** 18);
    await impersonates([addresses.sETH2_WHALE_ADDRESS]);
    return topUpMain(addresses.sETH2_ADDRESS, addresses.sETH2_WHALE_ADDRESS, to, amount);
}

/**
 * Top up a certain amount of rETH2 for a certain address(default 10 ** 18)
 */
async function topUpREth2ByAddress(amount = new BigNumber(10 ** 18), to) {
    if (isEmpty(to)) return 0;
    const accounts = await ethers.getSigners();
    await send.ether(accounts[0].address, addresses.rETH2_WHALE_ADDRESS, 10 ** 18);
    await impersonates([addresses.rETH2_WHALE_ADDRESS]);
    return topUpMain(addresses.rETH2_ADDRESS, addresses.rETH2_WHALE_ADDRESS, to, amount);
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
    tranferBackUsdc,
    tranferBackDai,
    tranferBackUsdt,
    impersonates,
    topUpMainV2,
    topUpMainV2_1,
    topUpMainV2_2,
    sendEthers,
}
