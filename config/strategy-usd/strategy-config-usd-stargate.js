const stargateStrategies = [
    {
        name: "StargateUsdcStrategy",
        contract: "StargateSingleStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0x8731d54E9D02c286767d56ac03e8037C07e01e98",//router
            "0xdf0770dF86a8034b3EFEf0A1Bb3c889B8332FF56",//lpToken
            1,//poolId
            0//stakePoolId
        ]
    },
    {
        name: "StargateUsdtStrategy",
        contract: "StargateSingleStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7",//underlying
            "0x8731d54E9D02c286767d56ac03e8037C07e01e98",//router
            "0x38EA452219524Bb87e18dE1C24D3bB59510BD783",//lpToken
            2,//poolId
            1//stakePoolId
        ]
    }
];

module.exports = {
    stargateStrategies
};
