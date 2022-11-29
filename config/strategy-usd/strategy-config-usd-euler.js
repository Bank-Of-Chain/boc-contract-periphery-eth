const eulerStrategies = [
    {
        name: "EulerRevolvingLoanDaiStrategy",
        contract: "EulerRevolvingLoanStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//underlying
            0,//borrowCount
            7400,//borrowFactor
            7800,//borrowFactorMax
            7000,//borrowFactorMin
        ]
    },
    {
        name: "EulerRevolvingLoanUsdtStrategy",
        contract: "EulerRevolvingLoanStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7",//underlying
            0,//borrowCount
            7600,//borrowFactor
            8000,//borrowFactorMax
            7200,//borrowFactorMin
        ]
    },
    {
        name: "EulerRevolvingLoanUsdcStrategy",
        contract: "EulerRevolvingLoanStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            0,//borrowCount
            7600,//borrowFactor
            8000,//borrowFactorMax
            7200,//borrowFactorMin
        ]
    },
];

module.exports = {
    eulerStrategies
};
