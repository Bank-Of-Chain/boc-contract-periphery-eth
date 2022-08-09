const dForceStrategies = [
    {
        name: "DForceLendDaiStrategy",
        contract: "DForceLendStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//underlying
            "0x298f243aD592b6027d4717fBe9DeCda668E3c3A8"//iToken
        ]
    },
    {
        name: "DForceLendUsdcStrategy",
        contract: "DForceLendStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0x2f956b2f801c6dad74E87E7f45c94f6283BF0f45"//iToken
        ]
    },
    {
        name: "DForceLendUsdtStrategy",
        contract: "DForceLendStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7",//underlying
            "0x1180c114f7fAdCB6957670432a3Cf8Ef08Ab5354"//iToken
        ]
    },
];

module.exports = {
    dForceStrategies
};
