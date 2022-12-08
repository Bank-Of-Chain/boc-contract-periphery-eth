/**
 * Two-user scenario: one deposit and one withdrawal
 * Operations involved.
 * Two-user investment, Vault's lend, strategy Harvest, position transfer, user redemption, treasury share to administrator account
 * Rules involved.
 * 1. Share calculation for non-1 net value
 * 2. Redemptions with proportional funds taken from buffer pool and strategy
 * 3. 20% of profit to treasury share will be collected when users redeem with profit
 */
const {
  map
} = require("lodash");
const BigNumber = require('bignumber.js');
const {
  ethers,
} = require('hardhat');
const Utils = require('../../utils/assert-utils');
const {
  getStrategyDetails,
} = require('../../utils/strategy-utils');

const {
  depositVault,
  depositMultCoinsToVault,
  getVaultDetails
} = require("../../utils/vault-utils");
const {
  impersonates,
  setupCoreProtocolWithMockValueInterpreter,
} = require('../../utils/contract-utils-usd');
const {
  topUpUsdtByAddress,
  topUpUsdcByAddress,
  topUpDaiByAddress,
  tranferBackUsdt,
} = require('../../utils/top-up-utils');
const {
  lend,
  withdraw
} = require('../../utils/vault-utils');
const {
  advanceBlock
} = require('../../utils/block-utils');

// === Constants === //
const MFC = require('../../config/mainnet-fork-test-config');
const {
  strategiesList
} = require('../../config/strategy-usd/strategy-config-usd');
const { removeConsoleLog } = require("hardhat-preprocessor");

const IStrategy = hre.artifacts.require('IStrategy');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const Treasury = hre.artifacts.require("Treasury");

const Wallet = require('ethereumjs-wallet');

describe('[Scenario Test] Two Users Investment (One Deposit and One Withdraw)', function () {

  // parties in the protocol
  let accounts;
  let governance;
  let keeper;
  let token;
  let tokenDecimals;
  let depositUSD = new BigNumber(0);//decamls = 18

  // Core protocol contracts
  let vault;
  let vaultBuffer;
  let pegToken;
  let underlying;
  let harvester;
  let treasury;
  let valueInterpreter;
  let exchangePlatformAdapters;
  let accounts1 = [];
  let accounts2 = [];
  let acountNumber = 5;
  let usdtAmount1 = new BigNumber(0);
  let usdtAmount2 = new BigNumber(0);
  let snapshot;
  let oneTokenAmount;

  const SMALL_AMOUNT = 10;
  const LARGE_AMOUNT = 100000;

  const sendEthers = async (reviver, amount = new BigNumber(1 * 10 ** 18)) => {
    if (!BigNumber.isBigNumber(amount)) return new Error("must be a bignumber.js object")
    await network.provider.send("hardhat_setBalance", [reviver, `0x${amount.toString(16)}`])
  }

  const calGasFee = async (tx) => {
    const gasUsed = new BigNumber(tx.receipt.gasUsed);
    const provider = ethers.provider;
    const txDetail = await provider.getTransaction(tx.tx);
    console.log("gasUsed=", gasUsed.toFixed());
    console.log("gasPrice=", new BigNumber(+txDetail.gasPrice).toFixed());
    const gasFee = gasUsed.multipliedBy(new BigNumber(+txDetail.gasPrice));
    return gasFee;
  }

  before(async function () {
    token = await ERC20.at(MFC.USDT_ADDRESS);
    tokenDecimals = new BigNumber(await token.decimals());
    // depositAmount = new BigNumber(10).pow(tokenDecimals).multipliedBy(5000).multipliedBy(strategiesList.length);
    // allcotionamount = new BigNumber(depositAmount.div(strategiesList.length));

    await ethers.getSigners().then((resp) => {
      accounts = resp;
      governance = accounts[0].address;
      farmer1 = accounts[1].address;
      farmer2 = accounts[2].address;
      keeper = accounts[19].address;
    });

    oneTokenAmount = new BigNumber(10).pow(tokenDecimals).multipliedBy(10000);
    //top up
    await topUpUsdtByAddress(oneTokenAmount, farmer1);
    await topUpUsdcByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(10000), farmer1);
    await topUpDaiByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(10000), farmer1);
    await topUpUsdtByAddress(oneTokenAmount, farmer2);
    await topUpUsdcByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(10000), farmer2);
    await topUpDaiByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(10000), farmer2);

    // Generate 100 accounts and top up each with 50 USDT and 10 eth
    for (let i = 0; i < acountNumber; i++) {
      let amountOnePerson = new BigNumber(10).pow(tokenDecimals).multipliedBy(SMALL_AMOUNT);
      const EthWallet = Wallet.generate(true);
      // const privateKey = EthWallet.getPrivateKeyString();
      const addressALL = EthWallet.getAddressString();
      console.log("addressALL=", addressALL);

      accounts1.push(addressALL);
      await sendEthers(addressALL);
      await topUpUsdtByAddress(amountOnePerson, addressALL);
    }

    for (let i = 0; i < acountNumber; i++) {
      let amountOnePerson = new BigNumber(10).pow(tokenDecimals).multipliedBy(LARGE_AMOUNT);
      const EthWallet = Wallet.generate(true);
      // const privateKey = EthWallet.getPrivateKeyString();
      const addressALL = EthWallet.getAddressString();
      console.log("addressALL=", addressALL);

      accounts2.push(addressALL);
      await sendEthers(addressALL);
      await topUpUsdtByAddress(amountOnePerson, addressALL);
    }

    await setupCoreProtocolWithMockValueInterpreter(MFC.USDT_ADDRESS, governance, keeper, true).then((resp) => {
      vault = resp.vault;
      vaultBuffer = resp.vaultBuffer;
      pegToken = resp.pegToken;
      underlying = resp.underlying;
      harvester = resp.harvester;
      treasury = resp.treasury;
      valueInterpreter = resp.valueInterpreter;
      exchangePlatformAdapters = resp.exchangePlatformAdapters;
    });
    //20%
    // await vault.setTrusteeFeeBps(0);
    await vault.setRedeemFeeBps(0);
    await vault.setRebaseThreshold(1);

    await valueInterpreter.setPrice(MFC.USDT_ADDRESS, new BigNumber(10).pow(18));
    await valueInterpreter.setPrice(MFC.USDC_ADDRESS, new BigNumber(10).pow(18));
    await valueInterpreter.setPrice(MFC.DAI_ADDRESS, new BigNumber(10).pow(18));
    await valueInterpreter.setPrice(MFC.BUSD_ADDRESS, new BigNumber(10).pow(18));
    await valueInterpreter.setPrice(MFC.TUSD_ADDRESS, new BigNumber(10).pow(18));
    await valueInterpreter.setPrice(MFC.LUSD_ADDRESS, new BigNumber(10).pow(18));
    await valueInterpreter.setPrice(MFC.USDP_ADDRESS, new BigNumber(10).pow(18));
    // await valueInterpreter.setPrice(MFC.BUSD_ADDRESS, new BigNumber(10).pow(18).minus(new BigNumber(10).pow(16)));
    // await valueInterpreter.setPrice(MFC.MAI_ADDRESS, new BigNumber(10).pow(18).minus(new BigNumber(10).pow(16)));
    // await valueInterpreter.setPrice(MFC.UST_ADDRESS, new BigNumber(10).pow(18).minus(new BigNumber(10).pow(16)));
    // await valueInterpreter.setPrice(MFC.MIM_ADDRESS, new BigNumber(10).pow(18).minus(new BigNumber(10).pow(16)));
    // await valueInterpreter.setPrice(MFC.TUSD_ADDRESS, new BigNumber(10).pow(18).minus(new BigNumber(10).pow(16)));
    // await valueInterpreter.setPrice(MFC.USDP_ADDRESS, new BigNumber(10).pow(18).minus(new BigNumber(10).pow(16)));
    // await valueInterpreter.setPrice(MFC.LUSD_ADDRESS, new BigNumber(10).pow(18).minus(new BigNumber(10).pow(16)));

    //mock mining coin pirce
    //0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd  (DODO) @$0.2889)
    await valueInterpreter.setPrice('0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd', new BigNumber(2889).multipliedBy(new BigNumber(10).pow(14)));
    //0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0  (DF) (@$0.0513)
    await valueInterpreter.setPrice('0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0', new BigNumber(513).multipliedBy(new BigNumber(10).pow(13)));
    //0x6B3595068778DD592e39A122f4f5a5cF09C90fE2  (SUSHI) (@$2.38)
    await valueInterpreter.setPrice('0x6B3595068778DD592e39A122f4f5a5cF09C90fE2', new BigNumber(238).multipliedBy(new BigNumber(10).pow(16)));
    //0xba100000625a3754423978a60c9317c58a424e3D  (BAL) @$13.03
    await valueInterpreter.setPrice('0xba100000625a3754423978a60c9317c58a424e3D', new BigNumber(1303).multipliedBy(new BigNumber(10).pow(15)));
    //0xD533a949740bb3306d119CC777fa900bA034cd52  (CRV) (@$2.2238)
    await valueInterpreter.setPrice('0xD533a949740bb3306d119CC777fa900bA034cd52', new BigNumber(22238).multipliedBy(new BigNumber(10).pow(14)));
    //0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B  (CVX) (@$23.1441)
    await valueInterpreter.setPrice('0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B', new BigNumber(231441).multipliedBy(new BigNumber(10).pow(13)));
    //0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6  (STG) (@$1.049)
    await valueInterpreter.setPrice('0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6', new BigNumber(1049).multipliedBy(new BigNumber(10).pow(15)));
    //0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb  (sETH) (@$2823.32)
    await valueInterpreter.setPrice('0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb', new BigNumber(282332).multipliedBy(new BigNumber(10).pow(16)));

    // const strategies = await vault.getStrategies();
    // pendingRewardTokens = new Map();
    // for (const strategyAddress of strategies) {
    //   const strategy = await IStrategy.at(strategyAddress);
    //   const wants = await strategy.getWants();
    //   for (const wantAddress of wants) {
    //     await valueInterpreter.setPrice(wantAddress, new BigNumber(10).pow(18).minus(new BigNumber(10).pow(16)));
    //   }
    // }


  });
  after(async function () {
    // await tranferBackUsdt(farmer1);
    // await tranferBackUsdt(farmer2);
  });


  it('5 small accounts to deposit asset into Vault', async function () {

    for (let i = 0; i < acountNumber; i++) {

      await impersonates([accounts1[i]]);
      let amountOnePerson = new BigNumber(10).pow(tokenDecimals).multipliedBy(SMALL_AMOUNT);
      await depositVault(accounts1[i], underlying, vault, amountOnePerson);
      let pendingShare = new BigNumber(await vaultBuffer.balanceOf(accounts1[i]));
      console.log('User get pendingShare:%d', ethers.utils.formatEther(pendingShare.toFixed()));
      usdtAmount1 = usdtAmount1.plus(amountOnePerson);
      Utils.assertBNEq(pendingShare, amountOnePerson.multipliedBy(new BigNumber(10).pow(18 - tokenDecimals)));
    }
    const vaultBufferHoldUsdt = await token.balanceOf(vaultBuffer.address);
    //All USDT transferred in by users should be held by VaultBuffer
    Utils.assertBNEq(vaultBufferHoldUsdt, usdtAmount1);

    await adjustPosition(usdtAmount1);
    depositUSD = depositUSD.plus(new BigNumber(10).pow(18 - tokenDecimals).multipliedBy(usdtAmount1));

    const vaultBufferHoldUSDi = await pegToken.balanceOf(vaultBuffer.address);
    console.log('vaultBufferHoldUSDi:%d', vaultBufferHoldUSDi);

    await destribute(accounts1);


    for (let i = 0; i < acountNumber; i++) {
      const account = accounts1[i];
      const balanceOfUSDi = await pegToken.balanceOf(account);
      console.log('micro account balanceOfUSDi:%d', ethers.utils.formatEther(balanceOfUSDi.toString()));
    }

    await logVaultInfo('After deposit by micro account');
    await assetVaultTotalAssets(depositUSD);


    let totalSupply = await pegToken.totalSupply();
    const totalAssetsAfterLend = new BigNumber(await vault.totalAssets());
    Utils.assertBNEq(totalSupply, totalAssetsAfterLend.toFixed());
  });


  it('5 large account deposit asset into Vault', async function () {

    const accounts1BalancesBackup = [];
    for (let i = 0; i < acountNumber; i++) {
      const account = accounts1[i];
      const balanceOfUSDi = await pegToken.balanceOf(account);
      accounts1BalancesBackup.push(balanceOfUSDi);
    }

    for (let i = 0; i < acountNumber; i++) {
      await impersonates([accounts2[i]]);
      let amountOnePerson = new BigNumber(10).pow(tokenDecimals).multipliedBy(LARGE_AMOUNT);
      await depositVault(accounts2[i], underlying, vault, amountOnePerson);
      let pendingShare = new BigNumber(await vaultBuffer.balanceOf(accounts2[i]));
      console.log('User get pendingShare:%d', ethers.utils.formatEther(pendingShare.toFixed()));
      usdtAmount2 = usdtAmount2.plus(amountOnePerson);
      Utils.assertBNEq(pendingShare, amountOnePerson.multipliedBy(new BigNumber(10).pow(18 - tokenDecimals)));
    }

    const vaultBufferHoldUsdt = await token.balanceOf(vaultBuffer.address);
    //All USDT transferred in by users should be held by VaultBuffer
    Utils.assertBNEq(vaultBufferHoldUsdt, usdtAmount2);

    await adjustPosition(usdtAmount2);
    depositUSD = depositUSD.plus(new BigNumber(10).pow(18 - tokenDecimals).multipliedBy(usdtAmount2));

    const vaultBufferHoldUSDi = await pegToken.balanceOf(vaultBuffer.address);
    console.log('vaultBufferHoldUSDi:%d', vaultBufferHoldUSDi);
    await destribute(accounts2);

    for (let i = 0; i < acountNumber; i++) {
      const account = accounts2[i];
      const balanceOfUSDi = await pegToken.balanceOf(account);
      console.log('large account balanceOfUSDi:%d', ethers.utils.formatEther(balanceOfUSDi.toString()));
    }
    await logVaultInfo('After large user deposits');
    await assetVaultTotalAssets(depositUSD);

    let totalSupply = await pegToken.totalSupply();
    const totalAssetsAfterLend = new BigNumber(await vault.totalAssets());
    Utils.assertBNEq(totalSupply, totalAssetsAfterLend.toFixed());

    //The entry of large funds should not have an impact on the original small fund account
    for (let i = 0; i < acountNumber; i++) {
      const account = accounts1[i];
      const balanceOfUSDi = await pegToken.balanceOf(account);
      console.log('micro account %s balanceOfUSDi:%d', account, ethers.utils.formatEther(balanceOfUSDi.toString()));
      Utils.assertBNEq(balanceOfUSDi, accounts1BalancesBackup[i]);
    }


    // harvest after 5days
    await advanceBlock(5);

    const strategies = await vault.getStrategies();
    for (const strategyAddress of strategies) {
      const strategy = await IStrategy.at(strategyAddress);
      await strategy.harvest({ from: keeper });
      console.log('Strategy %s after harvest,totalAssets:%d', await strategy.name(), await strategy.estimatedTotalAssets());
    }
    const totalAssetsAfterHarvest = new BigNumber(await vault.totalAssets());
    const gain = totalAssetsAfterHarvest.minus(totalAssetsAfterLend);
    console.log('totalAssets before harvest:%s,after harvest:%s, gain:%d',
        ethers.utils.formatEther(totalAssetsAfterLend.toFixed()),
        ethers.utils.formatEther(totalAssetsAfterHarvest.toFixed()),
        ethers.utils.formatEther(gain.toFixed()));
    Utils.assertBNGt(totalAssetsAfterHarvest, totalAssetsAfterLend.toFixed());

    let beforeTotalSupply = new BigNumber(await pegToken.totalSupply());

    let _trusteeFeeBps = await vault.trusteeFeeBps();
    await vault.rebase(_trusteeFeeBps);
    await logVaultInfo('after Harvest');

    totalSupply = new BigNumber(await pegToken.totalSupply());
    console.log('totalSupply:%s,beforeTotalSupply:%s,totalAssetsAfterHarvest:%s', totalSupply.toFixed(), beforeTotalSupply.toFixed(), totalAssetsAfterHarvest.toFixed());
    Utils.assertBNGt(totalSupply.toFixed(), beforeTotalSupply.toFixed());

    //save
    // snapshot = await ethers.provider.send('evm_snapshot', []);
  });

  it('Redeem all strategies', async function () {
    const strategies = await vault.getStrategies();
    for (const strategyAddress of strategies) {
      const strategy = await IStrategy.at(strategyAddress);
      const strategyName = await strategy.name();
      console.log('Strategy is redeeming:%s', strategyName);
      await logVaultInfo(`before redeem ${strategyName}`);
      const strategyParam = await vault.strategies(strategyAddress);
      console.log("strategyTotalDebt:%s",strategyParam.totalDebt);
      if(strategyParam.totalDebt > 0){
        console.log('start redeeming:%s', strategyName);
        await vault.redeem(strategyAddress, strategyParam.totalDebt,0);
      }

      await logVaultInfo(`after redeem ${strategyName}`);
    }
  });


  it('Large users withdraw their full usdi', async function () {
    //resume
    // await ethers.provider.send('evm_revert', [snapshot]);
    const valueOfTrackedTokensBeforeWithdraw = new BigNumber(await vault.valueOfTrackedTokens());
    console.log('valueOfTrackedTokensBeforeWithdraw:%d', ethers.utils.formatEther(valueOfTrackedTokensBeforeWithdraw.toFixed()));
    for (let i = 0; i < acountNumber; i++) {
      const vaultTotalAssetsBeforeWithdraw = new BigNumber(await vault.totalAssets());
      const account = accounts2[i];
      const balanceOfUSDi = new BigNumber(await pegToken.balanceOf(account));
      await withdraw(account, vault.address, balanceOfUSDi.toFixed());
      const vaultTotalAssetsAfterWithdraw = new BigNumber(await vault.totalAssets());
      const receiveUsdt = new BigNumber(await token.balanceOf(account));
      console.log('NO %d account %s receiveUsdt:%d', i + 1, account, receiveUsdt.toFixed());
      console.log('vaultTotalAssetsBeforeWithdraw:%d,vaultTotalAssetsAfterWithdraw:%d,delta:',
          ethers.utils.formatEther(vaultTotalAssetsBeforeWithdraw.toFixed()),
          ethers.utils.formatEther(vaultTotalAssetsAfterWithdraw.toFixed()),
          ethers.utils.formatEther(vaultTotalAssetsBeforeWithdraw.minus(vaultTotalAssetsAfterWithdraw).toFixed()));
      const valueOfTrackedTokens = new BigNumber(await vault.valueOfTrackedTokens());
      console.log('valueOfTrackedTokens:%d', ethers.utils.formatEther(valueOfTrackedTokens.toFixed()));
    }
    let _trusteeFeeBps = await vault.trusteeFeeBps();
    await vault.rebase(_trusteeFeeBps);
    await logVaultInfo('after large account redeem');

    for (let i = 0; i < acountNumber; i++) {
      const account = accounts1[i];
      const balanceOfUSDi = await pegToken.balanceOf(account);
      console.log('micro account balanceOfUSDi:%d', ethers.utils.formatEther(balanceOfUSDi.toString()));
    }

  });


  async function logVaultInfo(tag = '') {
    console.log(`======================[${tag}] Vault Info Start========================`);

    const totalAssets = new BigNumber(await vault.totalAssets());
    console.log(`Vault totalAssets：${ethers.utils.formatEther(totalAssets.toFixed())}`);
    const totalShares = new BigNumber(await pegToken.totalShares());
    console.log(`Vault totalShares：${ethers.utils.formatEther(totalShares.toFixed())}`);
    const totalSupply = new BigNumber(await pegToken.totalSupply());
    console.log(`Vault totalSupply：${ethers.utils.formatEther(totalSupply.toFixed())}`);
    const sharePrice = totalShares == 0 ? 0 : totalAssets.multipliedBy(1e27).div(totalShares);
    console.log(`Vault sharePrice：${ethers.utils.formatEther(sharePrice.toFixed())}`);
    const valueOfTrackedTokens = new BigNumber(await vault.valueOfTrackedTokens());
    console.log(`Vault Reserve：${ethers.utils.formatEther(valueOfTrackedTokens.toFixed())}`);

    console.log(`======================[${tag}] Vault Info End========================`);

  }

  async function adjustPosition(lendAmount) {
    await vault.startAdjustPosition();
    const strategies = await vault.getStrategies();
    let totalAssets = new BigNumber(await vault.totalAssets());
    const depositAmountInStrategy = new BigNumber(lendAmount / strategiesList.length);
    console.log('totalAssets:%d,depositAmountInStrategy:%d', totalAssets, depositAmountInStrategy);

    for (const strategyAddress of strategies) {
      const strategy = await IStrategy.at(strategyAddress);
      console.log('lend to strategy %s %s', await strategy.name(), depositAmountInStrategy.toFixed(0,1));
      await lend(strategyAddress, vault.address, depositAmountInStrategy.toFixed(0,1), exchangePlatformAdapters, keeper);
    }

    await vault.endAdjustPosition();
  }

  async function destribute(accounts) {
    let isDistributing = await vaultBuffer.isDistributing();
    if (!isDistributing) return;
    const balanceOfUSDi = new BigNumber(await pegToken.balanceOf(vaultBuffer.address));
    do {
      await vaultBuffer.distributeWhenDistributing({ from: keeper });
      // console.log("distribute gasFee=", gasFee.toFixed());
      isDistributing = await vaultBuffer.isDistributing();
    } while (isDistributing)
    console.log("balanceOfUSDi:%s",balanceOfUSDi);

    const avg = balanceOfUSDi.div(accounts.length);
    for (const account of accounts) {
      const userBalance = await pegToken.balanceOf(account);
      console.log("userBalance:%s",userBalance);
      //The user's share of USDi should be equal to the average of the total USDi
      Utils.assertBNGt(10,userBalance-avg);
    }
  }

  async function assetVaultTotalAssets(expectAmount) {
    const actualAmount = new BigNumber(await vault.totalAssets());
    const delta = expectAmount.minus(actualAmount);
    if (delta != 0) {
      console.log('Vault totalAssets expectAmount:%f,actualAmount:%f,delta:%f', expectAmount.toFixed(),
          actualAmount.toFixed(),
          ethers.utils.formatEther(delta.toFixed()));
      const deltaRatio = delta.multipliedBy(10000).dividedBy(expectAmount);
      console.log('delta ratio:%f', deltaRatio);
      // Calculation error is not allowed to exceed one thousandth
      Utils.assertBNGt(10, deltaRatio);
    }
  }

});
