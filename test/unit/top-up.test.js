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

    it("topUpGusdByAddress", async function () {
        const contract = await ERC20.at(addresses.GUSD_ADDRESS)
        const topUpAmount = 1e9 * 1e2
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpGusdByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpSusdByAddress", async function () {
        const contract = await ERC20.at(addresses.SUSD_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpSusdByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpREth2ByAddress", async function () {
        const contract = await ERC20.at(addresses.rETH2_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpREth2ByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpSEth2ByAddress", async function () {
        const contract = await ERC20.at(addresses.sETH2_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpSEth2ByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })

    it("topUpSEthByAddress", async function () {
        const contract = await ERC20.at(addresses.sETH_ADDRESS)
        const topUpAmount = 1e9 * 1e18
        Utils.assertBNEq(await contract.balanceOf(farmer1), 0)
        await topUpSEthByAddress(topUpAmount, farmer1)
        Utils.assertBNEq(await contract.balanceOf(farmer1), topUpAmount)
    })
})
