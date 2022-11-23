const dForceStrategies = [
    {
        name: "DForceRevolvingLoanETHStrategy",
        contract: "ETHDForceRevolvingLoanStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",//underlying
            "0x5ACD75f21659a59fFaB9AEBAf350351a8bfaAbc0",//iToken
            "0x8B53Ab2c0Df3230EA327017C91Eb909f815Ad113",//_iController
            "0xb4De37b03f7AcE98FB795572B18aE3CFae85A628",//_priceOracle
            "0x8fAeF85e436a8dd85D8E636Ea22E3b90f1819564",//_rewardDistributorV3
            "0x62e28f054efc24b26A794F5C1249B6349454352C"//_eulerDToken
        ]
    },
];

module.exports = {
    dForceStrategies
};
