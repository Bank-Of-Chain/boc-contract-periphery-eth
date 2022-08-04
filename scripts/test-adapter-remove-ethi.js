const Vault = hre.artifacts.require("ETHVault");
const ExchangeAggregator = hre.artifacts.require("ExchangeAggregator");

// === Utils === //
const { findIndex } = require("lodash");

// Set the vault_address in chain-1 which should remove testAdapter
const VAULT_ADDRESS = "0x3a622DB2db50f463dF562Dc5F341545A64C580fc";

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
