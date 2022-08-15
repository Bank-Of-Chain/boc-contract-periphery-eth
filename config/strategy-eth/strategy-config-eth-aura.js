const auraStrategies = [
    {
        name: "AuraWstETHWETHStrategy",
        contract: "AuraWstETHWETHStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    },
    {
        name: "AuraREthWEthStrategy",
        contract: "AuraREthWEthStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    }
];

module.exports = {
    auraStrategies
};
