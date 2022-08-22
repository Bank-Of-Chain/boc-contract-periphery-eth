const uniswapStrategies = [
    {
        name: "UniswapV2StEthWEthStrategy",
        contract: "ETHUniswapV2Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x4028DAAC072e492d34a3Afdbef0ba7e35D8b55C4",//pair
        ]
    },
    {
        name: "UniswapV3RethEth3000Strategy",
        contract: "ETHUniswapV3Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xf0E02Cf61b31260fd5AE527d58Be16312BDA59b1",
            60,
            60,
            41400,
            0,
            100,
            60,
            60
        ]
    },

];

module.exports = {
    uniswapStrategies
};
