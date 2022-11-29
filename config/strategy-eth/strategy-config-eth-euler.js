const eulerStrategies = [
    {
        name: "EulerRevolvingLoanWETHStrategy",
        contract: "ETHEulerRevolvingLoanStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",//underlying
            0,//borrowCount
            7500,//borrowFactor
            7900,//borrowFactorMax
            7100,//borrowFactorMin
        ]
    },
    {
        name: "EulerRevolvingLoanWstETHStrategy",
        contract: "ETHEulerRevolvingLoanStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0",//underlying
            0,//borrowCount
            7400,//borrowFactor
            7800,//borrowFactorMax
            7000,//borrowFactorMin
        ]
    },
];

module.exports = {
    eulerStrategies
};
