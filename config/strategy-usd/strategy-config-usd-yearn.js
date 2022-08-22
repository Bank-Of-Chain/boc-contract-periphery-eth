const yearnStrategies = [
    {
        name: "YearnEarnBusdStrategy",
        contract: "YearnEarnStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE",//yVault
            "0x4Fabb145d64652a948d72533023f6E7A623C7C53"//underlyging
        ]
    },
    {
        name: "YearnEarnDaiStrategy",
        contract: "YearnEarnStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01",//yVault
            "0x6B175474E89094C44Da98b954EedeAC495271d0F"//underlyging
        ]
    },
    {
        name: "YearnEarnTusdStrategy",
        contract: "YearnEarnStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x73a052500105205d34Daf004eAb301916DA8190f",//yVault
            "0x0000000000085d4780B73119b644AE5ecd22b376"//underlyging
        ]
    },
    {
        name: "YearnEarnUsdcStrategy",
        contract: "YearnEarnStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xd6aD7a6750A7593E092a9B218d66C0A814a3436e",//yVault
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"//underlyging
        ]
    },
    {
        name: "YearnEarnUsdtStrategy",
        contract: "YearnEarnStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x83f798e925BcD4017Eb265844FDDAbb448f1707D",//yVault
            "0xdAC17F958D2ee523a2206206994597C13D831ec7"//underlyging
        ]
    }
];

module.exports = {
    yearnStrategies
};
