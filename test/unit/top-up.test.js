const {
    topUpUsdtByAddress,
    topUpDaiByAddress,
    topUpUsdcByAddress,
    topUpLusdByAddress,
    topUpTusdByAddress,
    topUpUsdpByAddress,
    topUpBusdByAddress,
} = require("../../utils/top-up-utils")
const Utils = require("../../utils/assert-utils")
const addresses = require("../../config/address-config")
const ERC20 = hre.artifacts.require("@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20")

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
})
