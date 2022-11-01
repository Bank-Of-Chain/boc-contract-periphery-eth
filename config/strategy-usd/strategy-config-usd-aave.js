const aaveStrategies = [
    {
        name: "AaveDaiLendingStEthStrategy",
        contract: "AaveLendingStEthStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6B175474E89094C44Da98b954EedeAC495271d0F",//_wantToken
            "0x028171bCA77440897B824Ca71D1c56caC55b68A3",//_wantAToken
            9,//_reserveIdOfToken
            "0x60594a405d53811d3BC4766596EFD80fd545A270"//_uniswapV3Pool
        ]
    },
    {
        name: "AaveUSDCLendingStEthStrategy",
        contract: "AaveLendingStEthStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",//_wantToken
            "0xBcca60bB61934080951369a648Fb03DF4F96263C",//_wantAToken
            19,//_reserveIdOfToken
            "0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640"//_uniswapV3Pool
        ]
    }
];

module.exports = {
    aaveStrategies
};
