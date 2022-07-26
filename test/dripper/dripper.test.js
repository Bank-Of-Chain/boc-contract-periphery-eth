/**
 * Dripper validation:
 * 1. Set Dripper dripDuration to 0
 * 2. Multiple release
 * 3. One-time release
 * 4. Change funds before collect
 * 5. Change funds after collect
 */
const BigNumber = require('bignumber.js');
const {
  ethers,
} = require('hardhat');
const Utils = require('../../utils/assert-utils');
const {
  getVaultDetails,
} = require("../../utils/vault-utils");
const {
  setupCoreProtocol,
} = require('../../utils/contract-utils');
const {
  topUpUsdtByAddress,
} = require('../../utils/top-up-utils');
const {
  advanceBlockV2,
} = require('../../utils/block-utils');

// === Constants === //
const MFC = require('../../config/mainnet-fork-test-config');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');

describe('【Dripper unit test-Dripper validation】', function () {
  // parties in the protocol
  let accounts;
  let governance;
  let keeper;
  let token;
  let tokenDecimals;
  let depositAmount;

  // Core protocol contracts
  let vault;
  let usdi;
  let harvester;
  let treasury;
  let dripper;
  let underlying;
  let underlyingDecimals;
  let underlyingAddress;
  let valueInterpreter;
  let exchangePlatformAdapters;

  before(async function () {
    token = await ERC20.at(MFC.USDT_ADDRESS);
    tokenDecimals = new BigNumber(await token.decimals());
    underlyingDecimals = tokenDecimals;
    underlyingAddress = MFC.USDT_ADDRESS;
    depositAmount = new BigNumber(10).pow(tokenDecimals).multipliedBy(1000);

    await ethers.getSigners().then((resp) => {
      accounts = resp;
      governance = accounts[0].address;
      keeper = accounts[19].address;
    });

    await setupCoreProtocol(MFC.USDT_ADDRESS, governance, keeper).then((resp) => {
      vault = resp.vault;
      usdi = resp.usdi;
      harvester = resp.harvester;
      treasury = resp.treasury;
      dripper = resp.dripper;
      underlying = resp.underlying;
      valueInterpreter = resp.valueInterpreter;
      exchangePlatformAdapters = resp.exchangePlatformAdapters;

    });
  });

  after(async function () {
    const beforeTransferTokenAmount = await token.balanceOf(dripper.address);
    await dripper.transferToken(token.address, new BigNumber(beforeTransferTokenAmount));
    const afterTransferTokenAmount = await token.balanceOf(dripper.address);
    console.log("Empty dripper, tokenAmount in dripper is ", new BigNumber(afterTransferTokenAmount).toFixed());
  });

  // ========= Validation One -- 【Set Dripper dripDuration to 0】 ========= //

  it('Validation One -- 【Set Dripper dripDuration to 0】: report an error - duration must be non-zero',
      async function () {
        let result = 0;
        try {
          await dripper.setDripDuration(0);
        } catch (error) {
          console.log(error.message);
          if (error.message=='VM Exception while processing transaction: reverted with reason string \'duration must be non-zero\'') {
            result = 1;
          }
        }
        Utils.assertBNEq(1, result);
      });

  // ========= Validation Two -- 【Multiple release】 ========= //

  it('Validation Two -- 【Multiple release】 STEP1: 0U added to vault', async function () {
    const {
      result: resultBefore
    } = await getVaultDetails(vault.address);

    await dripper.setDripDuration(172800);
    await topUpUsdtByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(100), dripper.address);
    await dripper.collect();

    const {
      result: resultAfter
    } = await getVaultDetails(vault.address);

    console.log("before collect vault totalAssets = ", resultBefore.totalAssets);
    console.log("after collect vault totalAssets = ", resultAfter.totalAssets);

    Utils.assertBNEq(resultBefore.totalAssets, resultAfter.totalAssets);
  });

  it('Validation Two -- 【Multiple release】 STEP2: Simulated block growth of 1 day, 50U(+-5%) added to vault',
      async function () {
        await advanceBlockV2(1);

        const {
          result: resultBefore
        } = await getVaultDetails(vault.address);

        await dripper.collect();

        const {
          result: resultAfter
        } = await getVaultDetails(vault.address);

        let correctAmout = new BigNumber(10).pow(tokenDecimals).multipliedBy(50);
        const correctAmoutInUsd = new BigNumber(
            await valueInterpreter.calcCanonicalAssetValueInUsd(token.address, correctAmout));
        let actualAmout = resultAfter.totalAssets - resultBefore.totalAssets;

        console.log("actualAmout = ", actualAmout);
        console.log("correctAmout = ", correctAmoutInUsd.toFixed());

        Utils.assertBNBt(
            correctAmoutInUsd.multipliedBy(95).div(100),
            actualAmout,
            correctAmoutInUsd.multipliedBy(105).div(100)
        );
      });

  it('Validation Two -- 【Multiple release】 STEP3: Simulated block growth of 1 day, 25U(+-5%) added to vault',
      async function () {
        await advanceBlockV2(1);

        const {
          result: resultBefore
        } = await getVaultDetails(vault.address);

        await dripper.collect();

        const {
          result: resultAfter
        } = await getVaultDetails(vault.address);

        let correctAmout = new BigNumber(10).pow(tokenDecimals).multipliedBy(25);
        const correctAmoutInUsd = new BigNumber(
            await valueInterpreter.calcCanonicalAssetValueInUsd(token.address, correctAmout));
        let actualAmout = resultAfter.totalAssets - resultBefore.totalAssets;

        console.log("actualAmout = ", actualAmout);
        console.log("correctAmout = ", correctAmoutInUsd.toFixed());

        const beforeTransferTokenAmount = await token.balanceOf(dripper.address);
        await dripper.transferToken(token.address, new BigNumber(beforeTransferTokenAmount));
        const afterTransferTokenAmount = await token.balanceOf(dripper.address);
        console.log("Empty dripper, tokenAmount in dripper is ", new BigNumber(afterTransferTokenAmount).toFixed());

        Utils.assertBNBt(
            correctAmoutInUsd.multipliedBy(95).div(100),
            actualAmout,
            correctAmoutInUsd.multipliedBy(105).div(100)
        );
      });

  // ========= Validation Three -- 【One-time release】 ========= //

  it('Validation Three -- 【One-time release】 STEP1: 0U added to vault', async function () {
    const {
      result: resultBefore
    } = await getVaultDetails(vault.address);

    await dripper.setDripDuration(86400);
    await topUpUsdtByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(100), dripper.address);
    await dripper.collect();

    const {
      result: resultAfter
    } = await getVaultDetails(vault.address);

    console.log("before collect vault totalAssets = ", resultBefore.totalAssets);
    console.log("after collect vault totalAssets = ", resultAfter.totalAssets);

    Utils.assertBNEq(resultBefore.totalAssets, resultAfter.totalAssets);
  });

  it('Validation Three -- 【One-time release】 STEP2: Simulated block growth of 1 day, 100U added to vault',
      async function () {
        await advanceBlockV2(1);

        const {
          result: resultBefore
        } = await getVaultDetails(vault.address);

        await dripper.collect();

        const {
          result: resultAfter
        } = await getVaultDetails(vault.address);

        let correctAmout = new BigNumber(10).pow(tokenDecimals).multipliedBy(100);
        const correctAmoutInUsd = new BigNumber(
            await valueInterpreter.calcCanonicalAssetValueInUsd(token.address, correctAmout));
        let actualAmout = resultAfter.totalAssets - resultBefore.totalAssets;

        console.log("actualAmout = ", actualAmout);
        console.log("correctAmout = ", correctAmoutInUsd.toFixed());

        const beforeTransferTokenAmount = await token.balanceOf(dripper.address);
        await dripper.transferToken(token.address, new BigNumber(beforeTransferTokenAmount));
        const afterTransferTokenAmount = await token.balanceOf(dripper.address);
        console.log("Empty dripper, tokenAmount in dripper is ", new BigNumber(afterTransferTokenAmount).toFixed());

        Utils.assertBNBt(
            correctAmoutInUsd.multipliedBy(95).div(100),
            actualAmout,
            correctAmoutInUsd.multipliedBy(105).div(100)
        );
      });

  // ========= Validation Four -- 【Change funds before collect】 ========= //

  it('Validation Four -- 【Change funds before collect】 STEP1: 0U added to vault', async function () {
    const {
      result: resultBefore
    } = await getVaultDetails(vault.address);

    await dripper.setDripDuration(172800);
    await topUpUsdtByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(50), dripper.address);
    await dripper.collect();

    const {
      result: resultAfter
    } = await getVaultDetails(vault.address);

    console.log("before collect vault totalAssets = ", resultBefore.totalAssets);
    console.log("after collect vault totalAssets = ", resultAfter.totalAssets);

    Utils.assertBNEq(resultBefore.totalAssets, resultAfter.totalAssets);
  });

  it('Validation Four -- 【Change funds before collect】 STEP2: Simulated block growth of 1 day, 25U added to vault',
      async function () {
        await advanceBlockV2(1);

        const {
          result: resultBefore
        } = await getVaultDetails(vault.address);

        await topUpUsdtByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(50), dripper.address);
        await dripper.collect();

        const {
          result: resultAfter
        } = await getVaultDetails(vault.address);

        let correctAmout = new BigNumber(10).pow(tokenDecimals).multipliedBy(25);
        const correctAmoutInUsd = new BigNumber(
            await valueInterpreter.calcCanonicalAssetValueInUsd(token.address, correctAmout));
        let actualAmout = resultAfter.totalAssets - resultBefore.totalAssets;

        console.log("actualAmout = ", actualAmout);
        console.log("correctAmout = ", correctAmoutInUsd.toFixed());

        Utils.assertBNBt(
            correctAmoutInUsd.multipliedBy(95).div(100),
            actualAmout,
            correctAmoutInUsd.multipliedBy(105).div(100)
        );
      });

  it('Validation Four -- 【Change funds before collect】 STEP3: Simulated block growth of 1 day, 37.5U added to vault',
      async function () {
        await advanceBlockV2(1);

        const {
          result: resultBefore
        } = await getVaultDetails(vault.address);

        await dripper.collect();

        const {
          result: resultAfter
        } = await getVaultDetails(vault.address);

        let correctAmout = new BigNumber(10).pow(tokenDecimals).multipliedBy(37.5);
        const correctAmoutInUsd = new BigNumber(
            await valueInterpreter.calcCanonicalAssetValueInUsd(token.address, correctAmout));
        let actualAmout = resultAfter.totalAssets - resultBefore.totalAssets;

        console.log("actualAmout = ", actualAmout);
        console.log("correctAmout = ", correctAmoutInUsd.toFixed());

        const beforeTransferTokenAmount = await token.balanceOf(dripper.address);
        await dripper.transferToken(token.address, new BigNumber(beforeTransferTokenAmount));
        const afterTransferTokenAmount = await token.balanceOf(dripper.address);
        console.log("Empty dripper, tokenAmount in dripper is ", new BigNumber(afterTransferTokenAmount).toFixed());

        Utils.assertBNBt(
            correctAmoutInUsd.multipliedBy(95).div(100),
            actualAmout,
            correctAmoutInUsd.multipliedBy(105).div(100)
        );
      });

  // ========= Validation Five -- 【Change funds after collect】 ========= //

  it('Validation Five -- 【Change funds after collect】 STEP1: 0U added to vault', async function () {
    const {
      result: resultBefore
    } = await getVaultDetails(vault.address);

    await dripper.setDripDuration(172800);
    await topUpUsdtByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(50), dripper.address);
    await dripper.collect();

    const {
      result: resultAfter
    } = await getVaultDetails(vault.address);

    console.log("before collect vault totalAssets = ", resultBefore.totalAssets);
    console.log("after collect vault totalAssets = ", resultAfter.totalAssets);

    Utils.assertBNEq(resultBefore.totalAssets, resultAfter.totalAssets);
  });

  it('Validation Five -- 【Change funds after collect】 STEP2: Simulated block growth of 1 day, 25U added to vault',
      async function () {
        await advanceBlockV2(1);

        const {
          result: resultBefore
        } = await getVaultDetails(vault.address);

        await dripper.collect();

        const {
          result: resultAfter
        } = await getVaultDetails(vault.address);

        let correctAmout = new BigNumber(10).pow(tokenDecimals).multipliedBy(25);
        const correctAmoutInUsd = new BigNumber(
            await valueInterpreter.calcCanonicalAssetValueInUsd(token.address, correctAmout));
        let actualAmout = resultAfter.totalAssets - resultBefore.totalAssets;

        console.log("actualAmout = ", actualAmout);
        console.log("correctAmout = ", correctAmoutInUsd.toFixed());

        Utils.assertBNBt(
            correctAmoutInUsd.multipliedBy(95).div(100),
            actualAmout,
            correctAmoutInUsd.multipliedBy(105).div(100)
        );
      });

  it('Validation Five -- 【Change funds after collect】 STEP3: Simulated block growth of 1 day, 12.5U added to vault',
      async function () {
        await topUpUsdtByAddress(new BigNumber(10).pow(tokenDecimals).multipliedBy(50), dripper.address);
        await advanceBlockV2(1);

        const {
          result: resultBefore
        } = await getVaultDetails(vault.address);

        await dripper.collect();

        const {
          result: resultAfter
        } = await getVaultDetails(vault.address);

        let correctAmout = new BigNumber(10).pow(tokenDecimals).multipliedBy(12.5);
        const correctAmoutInUsd = new BigNumber(
            await valueInterpreter.calcCanonicalAssetValueInUsd(token.address, correctAmout));
        let actualAmout = resultAfter.totalAssets - resultBefore.totalAssets;

        console.log("actualAmout = ", actualAmout);
        console.log("correctAmout = ", correctAmoutInUsd.toFixed());

        Utils.assertBNBt(
            correctAmoutInUsd.multipliedBy(95).div(100),
            actualAmout,
            correctAmoutInUsd.multipliedBy(105).div(100)
        );
      });
});

