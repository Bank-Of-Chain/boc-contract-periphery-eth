const Vault = hre.artifacts.require("Vault");
const TestAdapter = hre.artifacts.require("TestAdapter");
const ExchangeAggregator = hre.artifacts.require("ExchangeAggregator");
const ERC20 = hre.artifacts.require("@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20");

// === Utils === //
const BigNumber = require("bignumber.js");
const { getStrategiesWants } = require("../utils/strategy-utils");
const { findIndex } = require("lodash");
const {
    topUpDaiByAddress,
    topUpTusdByAddress,
    topUpUsdcByAddress,
    topUpUsdtByAddress,
    topUpBusdByAddress,
    topUpLusdByAddress,
    topUpUsdpByAddress,
    topUpGusdByAddress,
    topUpSusdByAddress,
} = require("../utils/top-up-utils");

// === Constants === //
const MFC = require("../config/mainnet-fork-test-config");

// Set the vault_address in chain-1 which should add testAdapter
const VAULT_ADDRESS = "0xCa1D199b6F53Af7387ac543Af8e8a34455BBe5E0";

const main = async () => {
    const vault = await Vault.at(VAULT_ADDRESS);

    const exchangeAggregatorAddress = await vault.exchangeManager();
    const exchangeAggregator = await ExchangeAggregator.at(exchangeAggregatorAddress);
    const {
        "0": adapterArray,
        "1": adapterIdentifier,
    } = await exchangeAggregator.getExchangeAdapters();

    const index = findIndex(adapterIdentifier, i => i === "testAdapter");

    if (index !== -1) {
        console.log(`already has testAdapter in ExchangeAdapters array! ${adapterArray[index]}`);
        return;
    }

    // create new testAdapter
    const valueInterpreterAddress = await vault.valueInterpreter();
    const testAdapter = await TestAdapter.new(valueInterpreterAddress);
    const wants = await getStrategiesWants(VAULT_ADDRESS);
    if (!wants.includes(MFC.USDT_ADDRESS)) {
        // mint 10^10
        const amount = new BigNumber(10).pow(6 + 10);
        await topUpUsdtByAddress(amount, testAdapter.address);
    }
    for (const want of wants) {
        const token = await ERC20.at(want);
        const decimals = await token.decimals();

        // mint 10^10
        const amount = new BigNumber(10).pow(decimals).multipliedBy(new BigNumber(10).pow(10));
        switch (want) {
            case MFC.USDT_ADDRESS:
                await topUpUsdtByAddress(amount, testAdapter.address);
                break;
            case MFC.DAI_ADDRESS:
                await topUpDaiByAddress(amount, testAdapter.address);
                break;
            case MFC.TUSD_ADDRESS:
                await topUpTusdByAddress(amount, testAdapter.address);
                break;
            case MFC.USDC_ADDRESS:
                await topUpUsdcByAddress(amount, testAdapter.address);
                break;
            case MFC.BUSD_ADDRESS:
                await topUpBusdByAddress(amount, testAdapter.address);
                break;
            case MFC.GUSD_ADDRESS:
                await topUpGusdByAddress(amount, testAdapter.address);
                break;
            case MFC.LUSD_ADDRESS:
                await topUpLusdByAddress(amount, testAdapter.address);
                break;
            case MFC.USDP_ADDRESS:
                await topUpUsdpByAddress(amount, testAdapter.address);
                break;
            case MFC.SUSD_ADDRESS:
                await topUpSusdByAddress(amount, testAdapter.address);
                break;
            default:
                console.log(`WARN: missing mint for ${want}`);
        }
    }
    await exchangeAggregator.addExchangeAdapters([testAdapter.address]);
    console.log(await exchangeAggregator.getExchangeAdapters());
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
