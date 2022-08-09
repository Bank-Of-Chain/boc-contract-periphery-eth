const sushiStrategies = [
    {
        name: "SushiKashiDaiAaveStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//underlying
            "0x0EA032DEcBfbeA581d77D4A9B9c5E9dB7C102a7c",//kashiPair
            266
        ]
    },
    {
        name: "SushiKashiDaiLinkStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//underlying
            "0x561770B93D0530390eb70e17AcBbD6E5d2f52A31",//kashiPair
            197
        ]
    },
    {
        name: "SushiKashiDaiSushiStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//underlying
            "0x05AD6d7dB640F4382184e2d82dD76b4581F8F8f4",//kashiPair
            220
        ]
    },
    {
        name: "SushiKashiDaiUniStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//underlying
            "0x651c7E8FA0aDd8c4531440650369533105113282",//kashiPair
            267
        ]
    },
    {
        name: "SushiKashiDaiWbtcStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//underlying
            "0x418BC3ff0Ba33AD64931160A91C92fA26b35aCB0",//kashiPair
            194
        ]
    },
    {
        name: "SushiKashiDaiWethStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//underlying
            "0x5F92e4300024c447A103c161614E6918E794c764",//kashiPair
            192
        ]
    },
    {
        name: "SushiKashiDaiXsushiStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//underlying
            "0x77F3A4Fa35BaC0EA6CfaC69037Ac4d3a757240A1",//kashiPair
            246
        ]
    },
    {
        name: "SushiKashiUsdcAaveStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0x40a12179260997c55619DE3290c5b9918588E791",//kashiPair
            223
        ]
    },
    {
        name: "SushiKashiUsdcCompStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0x0d2606158fA76b38C5d58dB94B223C3BdCBbf57C",//kashiPair
            261
        ]
    },
    {
        name: "SushiKashiUsdcLinkStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0x4f68e70e3a5308d759961643AfcadfC6f74B30f4",//kashiPair
            198
        ]
    },
    {
        name: "SushiKashiUsdcSushiStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0x263716dEe5b74C5Baed665Cb19c6017e51296fa2",//kashiPair
            218
        ]
    },
    {
        name: "SushiKashiUsdcWbtcStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0x668edab8A38A962D30602d6Fa7CA489484eE3224",//kashiPair
            195
        ]
    },
    {
        name: "SushiKashiUsdcWethStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0xB7b45754167d65347C93F3B28797887b4b6cd2F3",//kashiPair
            191
        ]
    },
    {
        name: "SushiKashiUsdcXsushiStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0x6EAFe077df3AD19Ade1CE1abDf8bdf2133704f89",//kashiPair
            247
        ]
    },
    {
        name: "SushiKashiUsdcYfiStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//underlying
            "0x65089e337109CA4caFF78b97d40453D37F9d23f8",//kashiPair
            222
        ]
    },
    {
        name: "SushiKashiUsdtLinkStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7",//underlying
            "0xC84Fb1F76cbdd3b3491E81FE3ff811248d0407e9",//kashiPair
            196
        ]
    },
    {
        name: "SushiKashiUsdtSushiStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7",//underlying
            "0xF9a4e1e117818Fc98F9808f3DF4d7b72C0Df4160",//kashiPair
            219
        ]
    },
    {
        name: "SushiKashiUsdtWbtcStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7",//underlying
            "0xf678B4A096bB49309b81B2a1c8a966Ef5F9756BA",//kashiPair
            193
        ]
    },
    {
        name: "SushiKashiUsdtWethStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7",//underlying
            "0xfF7D29c7277D8A8850c473f0b71d7e5c4Af45A50",//kashiPair
            190
        ]
    },
    {
        name: "SushiKashiUsdtXsushiStrategy",
        contract: "SushiKashiStakeStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xdAC17F958D2ee523a2206206994597C13D831ec7",//underlying
            "0x17Fb5f39C55903DE60E63543067031cE2B2659EE",//kashiPair
            249
        ]
    },
];

module.exports = {
    sushiStrategies
};
