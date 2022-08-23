const {
    topUpUsdtByAddress,
    topUpDaiByAddress,
    topUpUsdcByAddress,
    topUpLusdByAddress,
    topUpTusdByAddress,
    topUpUsdpByAddress,
    topUpBusdByAddress,
    topUpGusdByAddress,
    topUpSusdByAddress,
    topUpWETHByAddress,
    topUpSTETHByAddress,
    topUpWstEthByAddress,
    topUpRocketPoolEthByAddress,
    topUpSEthByAddress,
    topUpSEth2ByAddress,
    topUpREth2ByAddress,
    topUpEthByAddress
} = require("../../utils/top-up-utils")
const Utils = require("../../utils/assert-utils")
const addresses = require("../../config/address-config")
const ERC20 = hre.artifacts.require("@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20")
const { balance } = require("@openzeppelin/test-helpers")

let accounts
let farmer1
describe("【Verify】Recharge Script", function () {
    before(async function () {
        await ethers.getSigners().then(resp => {
            accounts = resp
            farmer1 = accounts[19].address
        })
    })

    it("topUpUsdtByAddress", async function () {
        const contract = await ERC20.at(addresses.USDT_ADDRESS)
        const topUpAmount = 1e9 * 1e6
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpUsdtByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpDaiByAddress", async function () {
        const contract = await ERC20.at(addresses.DAI_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpDaiByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpUsdcByAddress", async function () {
        const contract = await ERC20.at(addresses.USDC_ADDRESS)
        const topUpAmount = 1e9 * 1e6
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpUsdcByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpTusdByAddress", async function () {
        const contract = await ERC20.at(addresses.TUSD_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpTusdByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpLusdByAddress", async function () {
        const contract = await ERC20.at(addresses.LUSD_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpLusdByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpUsdpByAddress", async function () {
        const contract = await ERC20.at(addresses.USDP_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpUsdpByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpBusdByAddress", async function () {
        const contract = await ERC20.at(addresses.BUSD_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpBusdByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpGusdByAddress", async function () {
        const contract = await ERC20.at(addresses.GUSD_ADDRESS)
        const topUpAmount = 1e9 * 1e2
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpGusdByAddress(topUpAmount, farmer1)
        // TODO: build more
        // Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpSusdByAddress", async function () {
        const contract = await ERC20.at(addresses.SUSD_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpSusdByAddress(topUpAmount, farmer1)
        // TODO: build more
        // Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpREth2ByAddress", async function () {
        const contract = await ERC20.at(addresses.rETH2_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpREth2ByAddress(topUpAmount, farmer1)
        // TODO: build more
        // Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpSEth2ByAddress", async function () {
        const contract = await ERC20.at(addresses.sETH2_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpSEth2ByAddress(topUpAmount, farmer1)
        // TODO: build more
        // Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpSEthByAddress", async function () {
        const contract = await ERC20.at(addresses.sETH_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpSEthByAddress(topUpAmount, farmer1)
        // TODO: build more
        // Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpRocketPoolEthByAddress", async function () {
        const contract = await ERC20.at(addresses.rocketPoolETH_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpRocketPoolEthByAddress(topUpAmount, farmer1)
        Utils.assertBNGte(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpWstEthByAddress", async function () {
        const contract = await ERC20.at(addresses.wstETH_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpWstEthByAddress(topUpAmount, farmer1)
        Utils.assertBNGte(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpSTETHByAddress", async function () {
        const contract = await ERC20.at(addresses.stETH_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpSTETHByAddress(topUpAmount, farmer1)
        Utils.assertBNGte(await contract.balanceOf(farmer1), topUpAmount)
    })
    
    it("topUpWETHByAddress", async function () {
        const contract = await ERC20.at(addresses.WETH_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpWETHByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpEthByAddress", async function () {
        const balanceBefore = await balance.current(farmer1)
        const topUpAmount =  1e9 * 1e18
        await topUpEthByAddress(topUpAmount, farmer1)
        const balanceAfter = await balance.current(farmer1)
        Utils.assertBNEq(balanceAfter.sub(balanceBefore), topUpAmount)
    })
})
