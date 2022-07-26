/**
 * Vault 规则验证：
 * 1. 移除策略
 * 2. 添加策略
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
 const {strategiesList} = require('../../../config/strategy-config-eth');
 const IStrategy = hre.artifacts.require('IETHStrategy');
 const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
 

 describe('【Vault单元测试-添加/移除策略】', function () {
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
   let priceOracle;
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
       priceOracle = resp.priceOracle;
       exchangePlatformAdapters = resp.exchangePlatformAdapters;
       addToVaultStrategies = resp.addToVaultStrategies;
     });
   });
   after(async function () {
     await tranferBackUsdt(farmer1);
   });

   it('验证：Vault可正常移除所有策略', async function () {
    let strategyAddresses = await vault.getStrategies();
    await vault.removeStrategy(strategyAddresses,{from:governance});
    (await getStrategyDetails(vault.address)).log();
    const length = (await vault.getStrategies()).length
    console.log('策略的个数=', length);
    Utils.assertBNEq(length,0);
  });

  it('验证：Vault可重新添加策略', async function () {
    let _arr = new Array();
    for (let item of addToVaultStrategies){
      _arr.push({
        strategy: item['strategy'],
        profitLimitRatio: item['profitLimitRatio'],
        lossLimitRatio: item['lossLimitRatio']
    });
    }
    await vault.addStrategy(_arr,{from:governance});
    let strategyNum = (await vault.getStrategies()).length;
    console.log('strategyNum:%d,strategiesList.length',strategyNum,strategiesList.length);
    Utils.assertBNEq(strategyNum , strategiesList.length);
  });
  
});
