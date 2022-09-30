const checker = require('../strategy-checker');
const { send } = require("@openzeppelin/test-helpers")
const { ethers } = require('hardhat');
const { default: BigNumber } = require('bignumber.js');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const topUp = require('../../../utils/top-up-utils');
const MFC = require('../../../config/mainnet-fork-test-config');

const { advanceBlock } = require('../../../utils/block-utils');
const MockUniswapV3Router = hre.artifacts.require('MockUniswapV3Router');
const UniswapV3EthUsdc500Strategy = hre.artifacts.require("ETHUniswapV3Strategy");
const MockAavePriceOracleConsumer = hre.artifacts.require('MockAavePriceOracleConsumer');
const ILendingPoolAddressesProvider = hre.artifacts.require('ILendingPoolAddressesProvider');

describe('uniswapv3-eth-usdc-500-checker', function () {
    checker.check('UniswapV3EthUsdc500Strategy', async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const uniswapV3EthUsdc500Strategy = await UniswapV3EthUsdc500Strategy.at(strategy.address);


        let borrowInfo = await uniswapV3EthUsdc500Strategy.borrowInfo();
        console.log('===========borrow info one===========');
        console.log('totalCollateralETH:%s',borrowInfo._totalCollateralETH,);
        console.log('totalDebtETH:%s',borrowInfo._totalDebtETH,);
        console.log('availableBorrowsETH:%s',borrowInfo._availableBorrowsETH,);
        console.log('currentLiquidationThreshol:%s',borrowInfo._currentLiquidationThreshold);
        console.log('ltv:%s',borrowInfo._ltv,);
        console.log('healthFactor:%s',borrowInfo._healthFactor);
        console.log('currentBorrow:%s',await uniswapV3EthUsdc500Strategy.getCurrentBorrow());

        const mockPriceOracle = await MockAavePriceOracleConsumer.new();
        console.log('mockPriceOracle address:%s',mockPriceOracle.address);
        //set
        const addressProvider = await ILendingPoolAddressesProvider.at('0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5');
        const addressPrividerOwner = '0xEE56e2B3D491590B5b31738cC34d5232F378a8D5';
        await impersonates([addressPrividerOwner]);
        const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';

        const originPriceOracleConsumer = await MockAavePriceOracleConsumer.at(await addressProvider.getPriceOracle());
        console.log('USDC price0:%s',await originPriceOracleConsumer.getAssetPrice(USDC));

        await send.ether(accounts[0].address, addressPrividerOwner, 10 * 10 ** 18)
        await addressProvider.setPriceOracle(mockPriceOracle.address,{from:addressPrividerOwner});
        console.log('AaveAddressProvider oracle:%s',await addressProvider.getPriceOracle());

        console.log('USDC price1:%s',await mockPriceOracle.getAssetPrice(USDC));
        await mockPriceOracle.setAssetPrice(USDC, new BigNumber(await mockPriceOracle.getAssetPrice(USDC)).multipliedBy(4).dividedBy(2).toFixed(0,1));
        console.log('USDC price2:%s',await mockPriceOracle.getAssetPrice(USDC));


        borrowInfo = await uniswapV3EthUsdc500Strategy.borrowInfo();
        console.log('===========borrow info two===========');
        console.log('totalCollateralETH:%s',borrowInfo._totalCollateralETH,);
        console.log('totalDebtETH:%s',borrowInfo._totalDebtETH,);
        console.log('availableBorrowsETH:%s',borrowInfo._availableBorrowsETH,);
        console.log('currentLiquidationThreshol:%s',borrowInfo._currentLiquidationThreshold);
        console.log('ltv:%s',borrowInfo._ltv,);
        console.log('healthFactor:%s',borrowInfo._healthFactor);
        console.log('currentBorrow:%s',await uniswapV3EthUsdc500Strategy.getCurrentBorrow());

        await uniswapV3EthUsdc500Strategy.borrowRebalance();

        borrowInfo = await uniswapV3EthUsdc500Strategy.borrowInfo();
        console.log('===========borrow info three===========');
        console.log('totalCollateralETH:%s',borrowInfo._totalCollateralETH,);
        console.log('totalDebtETH:%s',borrowInfo._totalDebtETH,);
        console.log('availableBorrowsETH:%s',borrowInfo._availableBorrowsETH,);
        console.log('currentLiquidationThreshol:%s',borrowInfo._currentLiquidationThreshold);
        console.log('ltv:%s',borrowInfo._ltv,);
        console.log('healthFactor:%s',borrowInfo._healthFactor);
        console.log('currentBorrow:%s',await uniswapV3EthUsdc500Strategy.getCurrentBorrow());


        const wantsInfo = await uniswapV3EthUsdc500Strategy.getWantsInfo();
        const wants = wantsInfo._assets;
        for (let i = 0; i < wants.length; i++) {
            let wantToken = await ERC20.at(wants[i]);
            let wantTokenDecimals = await wantToken.decimals();
            // await topUpWant(wants[i], investor);
            let wantBalance = new BigNumber(await balanceOf(wants[i], investor));
            console.log('UniswapV3EthUsdc500Strategy before callback wantBalance: %d', wantBalance);
            wantToken.approve(mockUniswapV3Router.address, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});
            await mockUniswapV3Router.swap('0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640', i === 1 ? true : false, new BigNumber(2).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});
        }
    }, async function(strategy){}, async function (strategy) {
        const accounts = await ethers.getSigners();
        const investor = accounts[1].address;
        keeper = accounts[19].address;
        const mockUniswapV3Router = await MockUniswapV3Router.new();
        const uniswapV3EthUsdc500Strategy = await UniswapV3EthUsdc500Strategy.at(strategy);

        let twap = new BigNumber(await uniswapV3EthUsdc500Strategy.getTwap());
        console.log('before swap twap: %s', twap.toFixed());

        const wantsInfo = await uniswapV3EthUsdc500Strategy.getWantsInfo();
        const wants = wantsInfo._assets;

        let wantToken = await ERC20.at(wants[0]);
        let wantTokenDecimals = await wantToken.decimals();
        // await topUpWant(wants[1], investor);
        let wantBalance = new BigNumber(await balanceOf(wants[0], investor));
        console.log('UniswapV3EthUsdc500Strategy uniswapV3RebalanceCallback wantBalance: %d', wantBalance);
        wantToken.approve(mockUniswapV3Router.address, new BigNumber(50).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), { from: investor });
        await mockUniswapV3Router.swap("0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640", false, new BigNumber(50).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});

        await advanceBlock(1);
        twap = new BigNumber(await uniswapV3EthUsdc500Strategy.getTwap());
        console.log('after swap twap: %s', twap.toFixed());

        const beforeBaseMintInfo = await uniswapV3EthUsdc500Strategy.getMintInfo();
        console.log('before rebalance beforeBaseMintInfo.tokenId: ', beforeBaseMintInfo.baseTokenId);
        await uniswapV3EthUsdc500Strategy.rebalanceByKeeper({"from": keeper});
        const afterBaseMintInfo = await uniswapV3EthUsdc500Strategy.getMintInfo();
        console.log('after rebalance afterBaseMintInfo.tokenId: ', afterBaseMintInfo.baseTokenId);
        assert(beforeBaseMintInfo.baseTokenId !== afterBaseMintInfo.baseTokenId, 'rebalance fail');
        wantBalance = new BigNumber(await balanceOf(wants[0], investor));
        console.log('UniswapV3RethEth3000Strategy uniswapV3RebalanceCallback 2 wantBalance: %d', wantBalance);
        wantToken.approve(mockUniswapV3Router.address, new BigNumber(50).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), { from: investor });
        await mockUniswapV3Router.swap("0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640", false, new BigNumber(50).multipliedBy(new BigNumber(10).pow(wantTokenDecimals)), {"from": investor});

        await advanceBlock(1);

        twap = new BigNumber(await uniswapV3EthUsdc500Strategy.getTwap());
        console.log('after rebalance swap twap: %s', twap.toFixed());

        pendingRewards = await uniswapV3EthUsdc500Strategy.harvest.call({
            from: keeper,
        });
        await uniswapV3EthUsdc500Strategy.harvest({ from: keeper });
    });
});

async function topUpWant(want, investor) {
    console.log('want:', want);
    const amount = new BigNumber(10).pow(6);
    // ETH
    if (want === MFC.ETH_ADDRESS) {
        console.log('top up ETH');
        await topUp.impersonates([MFC.ETH_WHALE_ADDRESS]);
        await send.ether(MFC.ETH_WHALE_ADDRESS, investor, '200000000000000000000');
    }
    // wETH
    if (want === MFC.WETH_ADDRESS) {
        console.log('top up wETH');
        await topUp.topUpWETHByAddress(amount.multipliedBy(1e18), investor);
    }
    // stETH
    if (want === MFC.stETH_ADDRESS) {
        console.log('top up stETH');
        await topUp.topUpStEthByAddress(amount.multipliedBy(1e18), investor);
    }
    // wstETH
    if (want === MFC.wstETH_ADDRESS) {
        console.log('top up wstETH');
        await topUp.topUpWstEthByAddress(amount.multipliedBy(1e18), investor);
    }
    // rocketPoolETH
    if (want === MFC.rocketPoolETH_ADDRESS) {
        console.log('top up rocketPoolETH');
        await topUp.topUpRocketPoolEthByAddress(amount.multipliedBy(1e18), investor);
    }
}

async function balanceOf(asset, address) {
    if (asset === MFC.ETH_ADDRESS) {
        const provider = ethers.provider;
        console.log('balance=', (await provider.getBalance(address)).toString());
        return (await provider.getBalance(address)).toString();
    } else {
        const tokenContract = await ERC20.at(asset);
        return await tokenContract.balanceOf(address);
    }
}

//async function logBorrowInfo(aaveLendAction){
//    const borrowInfo = await aaveLendAction.borrowInfo();
//    console.log('===========borrow info===========');
//    console.log('totalCollateralETH:%s',borrowInfo._totalCollateralETH,);
//    console.log('totalDebtETH:%s',borrowInfo._totalDebtETH,);
//    console.log('availableBorrowsETH:%s',borrowInfo._availableBorrowsETH,);
//    console.log('currentLiquidationThreshol:%s',borrowInfo._currentLiquidationThreshold);
//    console.log('ltv:%s',borrowInfo._ltv,);
//    console.log('healthFactor:%s',borrowInfo._healthFactor);
//    console.log('currentBorrow:%s',await aaveLendAction.getCurrentBorrow());
//}

/**
* impersonates
* @param {*} targetAccounts
* @returns
*/
async function impersonates (targetAccounts) {
  await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: targetAccounts,
  })
  return async () => {
      await hre.network.provider.request({
          method: "hardhat_stopImpersonatingAccount",
          params: targetAccounts,
      })
  }
}
