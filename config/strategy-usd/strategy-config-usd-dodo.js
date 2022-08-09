const dodoStrategies = [
    {
        name: "DodoDaiUsdtStrategy",
        contract: "DodoStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x3058EF90929cb8180174D74C507176ccA6835D73",//lpToken
            "0x1A4F8705E1C0428D020e1558A371b7E6134455A2"//stakingPool
        ]
    },
    {
        name: "DodoUsdtUsdcStrategy",
        contract: "DodoV1Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xC9f93163c99695c6526b799EbcA2207Fdf7D61aD",//lpToken
            "0xaeD7384F03844Af886b830862FF0a7AFce0a632C"//stakingPool
        ]
    }
];

module.exports = {
    dodoStrategies
};
