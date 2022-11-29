const { upgrades, ethers } = require("hardhat");

const uniswapV3BusdUsdc500StrategyProxyAddr = "0xBB470de15a5433557F9348C807258a762301E313";
const uniswapV3DaiUsdc100StrategyProxyAddr = "0x0760e5A243c780f3Bd728AA02CdF2Cc1a5D18C8e";
const uniswapV3DaiUsdc500StrategyProxyAddr = "0x11e419023b1E5ea1D8F39b797C7Fe16F81958435";
const uniswapV3DaiUsdt500StrategyProxyAddr = "0x328cE902198aDc5B332363bBb33b37E0c7D71F1d";
const uniswapV3GusdUsdc3000StrategyProxyAddr = "0x525Ed827c849857898A4774D5fB55ca2c4812E73";
const uniswapV3TusdUsdc100StrategyProxyAddr = "0x013FDa6c5e93A6fED6f35F2CEb1c0c3Be6AcEc9b";
const uniswapV3UsdcUsdt100StrategyProxyAddr = "0x22674Ea1a299d3Ff2E93A917f91f2Ecf07e01D5c";
const uniswapV3UsdcUsdt500StrategyProxyAddr = "0x10225A8e2D89841FF0B65c295D5a6627Bb736a05";

const main = async () => {
    let network = hre.network.name;
    console.log("upgrade contract on network-%s", network);

    const uniswapV3StrategyArtifacts = await ethers.getContractFactory("UniswapV3Strategy");
    await upgrades.upgradeProxy(uniswapV3BusdUsdc500StrategyProxyAddr, uniswapV3StrategyArtifacts);
    console.log("=========upgrade uniswapV3BusdUsdc500Strategy success==========");

    await upgrades.upgradeProxy(uniswapV3DaiUsdc100StrategyProxyAddr, uniswapV3StrategyArtifacts);
    console.log("=========upgrade uniswapV3DaiUsdc100Strategy success==========");

    await upgrades.upgradeProxy(uniswapV3DaiUsdc500StrategyProxyAddr, uniswapV3StrategyArtifacts);
    console.log("=========upgrade uniswapV3DaiUsdc500Strategy success==========");

    await upgrades.upgradeProxy(uniswapV3DaiUsdt500StrategyProxyAddr, uniswapV3StrategyArtifacts);
    console.log("=========upgrade uniswapV3DaiUsdt500Strategy success==========");

    await upgrades.upgradeProxy(uniswapV3GusdUsdc3000StrategyProxyAddr, uniswapV3StrategyArtifacts);
    console.log("=========upgrade uniswapV3GusdUsdc3000Strategy success==========");

    await upgrades.upgradeProxy(uniswapV3TusdUsdc100StrategyProxyAddr, uniswapV3StrategyArtifacts);
    console.log("=========upgrade uniswapV3TusdUsdc100Strategy success==========");

    await upgrades.upgradeProxy(uniswapV3UsdcUsdt100StrategyProxyAddr, uniswapV3StrategyArtifacts);
    console.log("=========upgrade uniswapV3UsdcUsdt100Strategy success==========");

    await upgrades.upgradeProxy(uniswapV3UsdcUsdt500StrategyProxyAddr, uniswapV3StrategyArtifacts);
    console.log("=========upgrade uniswapV3UsdcUsdt500Strategy success==========");

    console.log("=========upgrade UniswapV3Strategy end==========");
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
