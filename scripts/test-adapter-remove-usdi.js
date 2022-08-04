const Vault = hre.artifacts.require("ETHVault");
const ExchangeAggregator = hre.artifacts.require("ExchangeAggregator");

// === Utils === //
const { findIndex } = require("lodash");

const VAULT_ADDRESS = "0x5e6CB7E728E1C320855587E1D9C6F7972ebdD6D5";

const main = async () => {
    const vault = await Vault.at(VAULT_ADDRESS);

    const exchangeAggregatorAddress = await vault.exchangeManager();
    const exchangeAggregator = await ExchangeAggregator.at(exchangeAggregatorAddress);
    const {
        "0": adapterArray,
        "1": adapterIdentifier,
    } = await exchangeAggregator.getExchangeAdapters();

    const index = findIndex(adapterIdentifier, i => i === "testAdapter");

    if (index === -1) {
        console.log("has no testAdapter in ExchangeAdapters array");
        return;
    }
    // remove testAdapter
    await exchangeAggregator.removeExchangeAdapters([adapterArray[index]]);
    console.log(await exchangeAggregator.getExchangeAdapters());
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
