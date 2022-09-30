const topUp = require('../utils/top-up-utils');
const MFC = require('../config/mainnet-fork-test-config');
const {ethers} = require("hardhat");
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const IAaveLendingPool = hre.artifacts.require('IAaveLendingPool');

const main = async () => {
    const aTokenContract = await ERC20.at('0x1982b2F5814301d4e9a8b0201555376e62F82428');
    //AaveWETHstETHStrategy address
    const strategyAddress = '';
    const astETHAmount = new BigNumber(await aTokenContract.balanceOf(strategyAddress));
    const lidoApr = 531; //x/10000
    const growDays = 8;
    const increaseAstEthAmount = new BigNumber(astETHAmount.multipliedBy(growDays).multipliedBy(lidoApr).dividedBy(365).dividedBy(10000).toFixed(0,2));
    const accounts = await ethers.getSigners();
    const keeper = accounts[19].address;
    await topUp.topUpSTETHByAddress(increaseAstEthAmount,keeper);

    const _lendingPoolAddress = '0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9';
    const _aaveLendingPool =  await IAaveLendingPool.at(_lendingPoolAddress);

    const tokenContract = await ERC20.at(MFC.stETH_ADDRESS);
    await tokenContract.approve(_lendingPoolAddress, increaseAstEthAmount,{from:keeper});
    await _aaveLendingPool.deposit(MFC.stETH_ADDRESS, increaseAstEthAmount.toFixed(), keeper, 0,{from: keeper});

    const receivedAstETHAmount = await aTokenContract.balanceOf(keeper);
    console.log("increase astETH:",receivedAstETHAmount.toString());

    await aTokenContract.transfer(strategyAddress,receivedAstETHAmount.toString(),{from:keeper});
    
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });