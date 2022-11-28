const aaveStrategies = [
    {
        name: "AaveWETHstETHStrategy",
        contract: "AaveWETHstETHStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            6700,//_borrowFactor
            6900,//_borrowFactorMax
            6500 //_borrowFactorMin
        ]
    }
];

module.exports = {
    aaveStrategies
};
