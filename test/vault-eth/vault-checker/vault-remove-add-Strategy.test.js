/**
 * Vault rule validation.
 * 1. remove policy
 * 2. Add Policy
 */

 const BigNumber = require('bignumber.js');
 const {
 ethers,
 } = require('hardhat');
 const Utils = require('../../../utils/assert-utils');
 const {
 getStrategyDetails,
 } = require('../../../utils/strategy-utils');

 const {
 setupCoreProtocol,
 } = require('../../../utils/contract-utils-eth');
 const {
     topUpEthByAddress,
 tranferBackUsdt,
 } = require('../../../utils/top-up-utils');

 // === Constants === //
 const MFC = require('../../../config/mainnet-fork-test-config');
 const {strategiesList} = require('../../../config/strategy-eth/strategy-config-eth');
 const IStrategy = hre.artifacts.require('IETHStrategy');
 const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
 

 describe('【Vault Unit Testing - Add/Remove Policy】', function () {
   // parties in the protocol
   let accounts;
   let governance;
   let farmer1;
   let keeper;
   let token;
   let tokenDecimals;
   let depositAmount
 
   // Core protocol contracts
   let vault;
   let underlying;
   let priceOracleConsumer;
   let exchangePlatformAdapters;
   let addToVaultStrategies;
   let farmer1Lp
 
   before(async function () {
       underlying = MFC.ETH_ADDRESS;
    tokenDecimals = new BigNumber(18);
    depositAmount = new BigNumber(10).pow(tokenDecimals).multipliedBy(1000);
     await ethers.getSigners().then((resp) => {
       accounts = resp;
       governance = accounts[0].address;
       farmer1 = accounts[1].address;
       keeper = accounts[19].address;
     });
     await topUpEthByAddress(depositAmount, farmer1);
     await setupCoreProtocol(MFC.ETH_ADDRESS, governance, keeper).then((resp) => {
       vault = resp.vault;
       priceOracleConsumer = resp.priceOracleConsumer;
       exchangePlatformAdapters = resp.exchangePlatformAdapters;
       addToVaultStrategies = resp.addToVaultStrategies;
     });
   });
   after(async function () {
     await tranferBackUsdt(farmer1);
   });

   it('Verify: Vault removes all policies properly', async function () {
    let strategyAddresses = await vault.getStrategies();
    await vault.removeStrategies(strategyAddresses,{from:governance});
    (await getStrategyDetails(vault.address)).log();
    const length = (await vault.getStrategies()).length
    console.log('length of strategies=', length);
    Utils.assertBNEq(length,0);
  });

  it('Verify: Vault can re-add policies', async function () {
    let _arr = new Array();
    for (let item of addToVaultStrategies){
      _arr.push({
        strategy: item['strategy'],
        profitLimitRatio: item['profitLimitRatio'],
        lossLimitRatio: item['lossLimitRatio']
    });
    }
    await vault.addStrategies(_arr,{from:governance});
    let strategyNum = (await vault.getStrategies()).length;
    console.log('strategyNum:%d,strategiesList.length',strategyNum,strategiesList.length);
    Utils.assertBNEq(strategyNum , strategiesList.length);
  });
  
});
