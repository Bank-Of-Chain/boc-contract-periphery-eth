const Vault = hre.artifacts.require("ETHVault");
const TestAdapter = hre.artifacts.require("TestAdapter");
const ExchangeAggregator = hre.artifacts.require("ExchangeAggregator");
const ERC20 = hre.artifacts.require("@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20");

// === Utils === //
const BigNumber = require("bignumber.js");
const { getStrategiesWants } = require("../utils/strategy-utils");
const { findIndex } = require("lodash");
const {
    topUpEthByAddress,
    topUpWstEthByAddress,
    topUpWETHByAddress,
    topUpSTETHByAddress,
    topUpRocketPoolEthByAddress,
    topUpSEth2ByAddress,
    topUpREth2ByAddress,
    topUpSEthByAddress,
} = require("../utils/top-up-utils");

// === Constants === //
const MFC = require("../config/mainnet-fork-test-config");

// Set the vault_address in chain-1 which should add testAdapter
const VAULT_ADDRESS = "0xFC4EE541377F3b6641c23CBE82F6f04388290421";

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
    const valueInterpreterAddress = await vault.priceProvider();
    const testAdapter = await TestAdapter.new(valueInterpreterAddress);
    const wants = await getStrategiesWants(VAULT_ADDRESS);
    if (!wants.includes(MFC.ETH_ADDRESS)) {
        // mint 10^10
        const amount = new BigNumber(10).pow(18 + 10);
        await topUpEthByAddress(amount, testAdapter.address);
    }
    for (const want of wants) {
        if (want === MFC.ETH_ADDRESS) {
            const amount = new BigNumber(10).pow(18).multipliedBy(new BigNumber(10).pow(10));
            await topUpEthByAddress(amount, testAdapter.address);
            continue;
        }
        const token = await ERC20.at(want);
        const decimals = await token.decimals();

        // mint 10^10
        const amount = new BigNumber(10).pow(decimals).multipliedBy(new BigNumber(10).pow(10));
        switch (want) {
            case MFC.wstETH_ADDRESS:
                await topUpWstEthByAddress(amount, testAdapter.address);
                break;
            case MFC.WETH_ADDRESS:
                await topUpWETHByAddress(amount, testAdapter.address);
                break;
            case MFC.stETH_ADDRESS:
                await topUpSTETHByAddress(amount, testAdapter.address);
                break;
            case MFC.rocketPoolETH_ADDRESS:
                await topUpRocketPoolEthByAddress(amount, testAdapter.address);
                break;
            case MFC.sETH2_ADDRESS:
                await topUpSEth2ByAddress(amount, testAdapter.address);
                break;
            case MFC.rETH2_ADDRESS:
                await topUpREth2ByAddress(amount, testAdapter.address);
                break;
            case MFC.sETH_ADDRESS:
                await topUpSEthByAddress(amount, testAdapter.address);
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
