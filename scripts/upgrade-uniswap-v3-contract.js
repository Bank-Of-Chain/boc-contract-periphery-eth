const { upgrades, ethers } = require("hardhat");
const uniswapV3UsdcUsdt100StrategyProxyAddr = "0x22674Ea1a299d3Ff2E93A917f91f2Ecf07e01D5c";

const main = async () => {
    let network = hre.network.name;
    console.log("upgrade contract on network-%s", network);

    const uniswapV3UsdcUsdt100StrategyArtifacts = await ethers.getContractFactory("UniswapV3Strategy");
    await upgrades.upgradeProxy(uniswapV3UsdcUsdt100StrategyProxyAddr, uniswapV3UsdcUsdt100StrategyArtifacts);
    console.log("=========upgrades UniswapV3Strategy==========");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
