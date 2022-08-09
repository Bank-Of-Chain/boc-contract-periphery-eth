const yearnStrategies = [
    {
        name: "YearnV2YETHStrategy",
        contract: "YearnV2Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xa258C4606Ca8206D8aA700cE2143D7db854D168c",//yVault
            "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"//underlyging
        ]
    },
   
];

module.exports = {
    yearnStrategies
};
