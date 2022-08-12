const chai = require("chai");
const hre = require("hardhat");
const {ethers} = require("hardhat");
const {solidity} = require("ethereum-waffle");
const {utils} = require("ethers");
const MFC = require("../../config/mainnet-fork-test-config");
const {topUpUsdtByAddress, topUpUsdcByAddress, topUpDaiByAddress, topUpSTETHByAddress} = require('../../utils/top-up-utils');
const Utils = require('../../utils/assert-utils');
const {
    getBestSwapInfo
} = require('piggy-finance-utils');
// === Constants === //
const {address} = require("hardhat/internal/core/config/config-validation");
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const IEREC20Mint = hre.artifacts.require('IERC20Upgradeable');
const BigNumber = require('bignumber.js');
const {
    mapKeys,
    map,
    filter,
    isEmpty,
    every
} = require("lodash");
const addresses = require("../../config/address-config");
const {deployMockContract} = require("@ethereum-waffle/mock-contract");
const {
    send,
    balance
} = require('@openzeppelin/test-helpers');

// Support BigNumber and all that with ethereum-waffle
chai.use(solidity);
const expect = chai.expect;

const AccessControlProxy = hre.artifacts.require('AccessControlProxy');
const Treasury = hre.artifacts.require('Treasury');
const PriceOracle = hre.artifacts.require('PriceOracle');
const ETHi = hre.artifacts.require("ETHi");
const WETHi = hre.artifacts.require("WETHi");
const Vault = hre.artifacts.require('ETHVault');
const VaultBuffer = hre.artifacts.require('VaultBuffer');
const PegToken = hre.artifacts.require('PegToken');
const IETHVault = hre.artifacts.require('IETHVault');
const ETHExchanger = hre.artifacts.require('ETHExchanger');
const ExchangeAggregator = hre.artifacts.require('ExchangeAggregator');
const EthOneInchV4Adapter = hre.artifacts.require('OneInchV4Adapter');
const EthParaSwapV5Adapter = hre.artifacts.require('ParaSwapV5Adapter');

const VaultAdmin = hre.artifacts.require('ETHVaultAdmin');
const MockS3CoinStrategy = hre.artifacts.require('MockS3CoinStrategy');


const EXCHANGE_EXTRA_PARAMS = {
    oneInchV4: {
        useHttp: true,
        network: 1,
        protocols: 'CURVE_V2,SUSHI,CURVE,UNISWAP_V2,UNISWAP_V3'
    },
    paraswap: {
        network: 1,
        includeDEXS: 'UniswapV2,UniswapV3,SushiSwap,mStable,DODOV2,DODOV1,Curve,CurveV2,Compound,Bancor,BalancerV2,Aave2',
        excludeContractMethods: ['swapOnZeroXv2', 'swapOnZeroXv4']
    }
}


describe("Vault", function () {
    let accounts;
    let governance;
    let farmer1;
    let farmer2;
    let keeper;
    let token;
    let tokenDecimals;
    let ethiDecimals;
    let stethDecimals;
    let depositAmount
    let daiDepositAmount
    let daiDecimals;
    let usdcDepositAmount
    let stethDepositAmount
    let usdcDecimals;
    // let testAdapter;
    let mockS3CoinStrategy;

    // Core protocol contracts
    let treasury;
    let pegToken;
    let vault;
    let vaultBuffer;
    let iVault;
    let vaultAdmin;
    let underlying;
    let usdcToken;
    let stethToken;
    let underlyingAddress;
    let priceOracle;
    let ethExchanger;
    let treasuryAddress;
    let exchangePlatformAdapters;

    before(async function () {
        ethiDecimals = 18;
        underlyingAddress = MFC.USDT_ADDRESS;
        token = await ERC20.at(MFC.USDT_ADDRESS);
        underlying = await ERC20.at(underlyingAddress);
        usdcToken = await ERC20.at(MFC.USDC_ADDRESS);
        stethToken = await ERC20.at(MFC.DAI_ADDRESS);
        stethToken = await ERC20.at(MFC.stETH_ADDRESS);
        tokenDecimals = new BigNumber(await token.decimals());
        usdcDecimals = new BigNumber(await usdcToken.decimals());
        daiDecimals = new BigNumber(await stethToken.decimals());
        stethDecimals = new BigNumber(await stethToken.decimals());
        depositAmount = new BigNumber(10).pow(tokenDecimals).multipliedBy(1000);
        usdcDepositAmount = new BigNumber(10).pow(usdcDecimals).multipliedBy(1000);
        daiDepositAmount = new BigNumber(10).pow(daiDecimals).multipliedBy(1000);
        stethDepositAmount = new BigNumber(10).pow(stethDecimals).multipliedBy(1000);
        await ethers.getSigners().then((resp) => {
            accounts = resp;
            governance = accounts[0].address;
            farmer1 = accounts[1].address;
            farmer2 = accounts[2].address;
            keeper = accounts[19].address;
        });
       
        await topUpSTETHByAddress(stethDepositAmount, farmer1);
        await topUpSTETHByAddress(stethDepositAmount, farmer2);
        stethDepositAmount = new BigNumber(await stethToken.balanceOf(farmer1));
        console.log('stethDepositAmount:%s',stethDepositAmount);

        console.log('deploy Vault');
        vault = await Vault.new();

        console.log('deploy accessControlProxy');
        const accessControlProxy = await AccessControlProxy.new();
        accessControlProxy.initialize(governance, governance, vault.address, keeper);
        
        // PriceOracle
        console.log('deploy PriceOracle');
        priceOracle = await PriceOracle.new();
        // ETHExchanger
        console.log('deploy ETHExchanger');
        ethExchanger = await ETHExchanger.new();

        
        console.log('deploy EthOneInchV4Adapter');
        const ethOneInchV4Adapter = await EthOneInchV4Adapter.new();
                
        console.log('deploy EthParaSwapV5Adapter');
        const ethParaSwapV5Adapter = await EthParaSwapV5Adapter.new();

        console.log('deploy ExchangeAggregator');
        exchangeAggregator = await ExchangeAggregator.new([ethOneInchV4Adapter.address,ethParaSwapV5Adapter.address], accessControlProxy.address);
        const adapters = await exchangeAggregator.getExchangeAdapters();
        exchangePlatformAdapters = {};
        for (let i = 0; i < adapters.identifiers_.length; i++) {
            exchangePlatformAdapters[adapters.identifiers_[i]] = adapters.exchangeAdapters_[i];
        }

        treasury = await Treasury.new();
        await treasury.initialize(accessControlProxy.address);

        treasuryAddress = treasury.address;
             
        await vault.initialize(accessControlProxy.address, treasuryAddress, exchangeAggregator.address, priceOracle.address);
        vaultAdmin = await VaultAdmin.new();
        await vault.setAdminImpl(vaultAdmin.address, {from: governance});


        console.log('mockS3CoinStrategy');
        // mockS3CoinStrategy
        mockS3CoinStrategy = await MockS3CoinStrategy.new();
        await mockS3CoinStrategy.initialize(vault.address);

        console.log('deploy PegToken');
        pegToken = await PegToken.new();
        await pegToken.initialize('USDi', 'USDi', 18, vault.address, accessControlProxy.address);

        console.log('vault Buffer');
        vaultBuffer = await VaultBuffer.new();
        await vaultBuffer.initialize('Sharei', 'Sharei', vault.address, pegToken.address,accessControlProxy.address);

        iVault = await IETHVault.at(vault.address);
        await iVault.setVaultBufferAddress(vaultBuffer.address);
        await iVault.setPegTokenAddress(pegToken.address);
        await iVault.setRebaseThreshold(1);
        await iVault.setUnderlyingUnitsPerShare(new BigNumber(10).pow(18).toFixed());
        //20%
        await iVault.setTrusteeFeeBps(2000, {from: governance});
        await iVault.setRedeemFeeBps(0, {from: governance});
    });

    it('Verify: Vault can add and remove Assets normally', async function () {
        const preLength = (await iVault.getSupportAssets()).length
        console.log('Number of Assets before adding=', preLength);
        await iVault.addAsset(MFC.ETH_ADDRESS, {from: governance});
        const lastLength = (await iVault.getSupportAssets()).length
        console.log('Number of Assets after adding=', lastLength);
        Utils.assertBNGt(lastLength, preLength);
        await iVault.removeAsset(MFC.ETH_ADDRESS, {from: governance});
        const removeLastLength = (await iVault.getSupportAssets()).length
        console.log('Number of Assets after removal=', removeLastLength);
        Utils.assertBNGt(lastLength, removeLastLength);
    });

    it('Verify: Vault can add and remove all policies normally', async function () {
        let addToVaultStrategies = new Array();
        addToVaultStrategies.push({
            strategy: mockS3CoinStrategy.address,
            profitLimitRatio: 100,
            lossLimitRatio: 100
        });

        await iVault.addStrategy(addToVaultStrategies, {from: governance});
        let strategyAddresses = await iVault.getStrategies();
        console.log('Number of strategies before removal=', strategyAddresses.length);
        await iVault.removeStrategy(strategyAddresses, {from: governance});
        const length = (await iVault.getStrategies()).length;
        console.log('Number of strategies after removal=', length);
        Utils.assertBNEq(length, 0);
    });

    it('Verify: Vault can be invested normally', async function () {
        await iVault.addAsset(MFC.ETH_ADDRESS, {from: governance});
        console.log("Balance of ethi of farmer1 before investing:", new BigNumber(await pegToken.balanceOf(farmer1)).div(10 ** ethiDecimals).toFixed());
        console.log("Balance of eth of farmer1 before investing:",new BigNumber(await balance.current(farmer1)).toFixed());

        //deposit with ETH
        const ethAmount = new BigNumber(10).pow(18).multipliedBy(10).toFixed();
        const tx  = await iVault.mint(MFC.ETH_ADDRESS, ethAmount, 0, {from: farmer1,value: ethAmount});
        const gasUsed = tx.receipt.gasUsed;
        console.log('mint gasUsed: %d', gasUsed);
        const balanceOf = new BigNumber(await vaultBuffer.balanceOf(farmer1)).toFixed();
        
        console.log("Balance of eth of farmer1 after investing:",new BigNumber(await balance.current(farmer1)).toFixed());
        console.log("Balance of ethi of farmer1 after investing:", new BigNumber(await pegToken.balanceOf(farmer1)).toFixed());
        console.log("Balance of tETHi of farmer1 after investing:%s",new BigNumber(await vaultBuffer.balanceOf(farmer1)).toFixed());
        console.log("totalAssets after investment:%s,totalValue：%s", new BigNumber(await iVault.totalAssets()).toFixed(), new BigNumber(await iVault.totalValue()).toFixed());
        console.log("totalDebt after investment:%s,totalValueInStrategies：%s", new BigNumber(await iVault.totalDebt()).toFixed(), new BigNumber(await iVault.totalValueInStrategies()).toFixed());
        console.log("valueOfTrackedTokens after investment:%s,totalValueInVault：%s", new BigNumber(await iVault.valueOfTrackedTokens()).toFixed(), new BigNumber(await iVault.totalValueInVault()).toFixed());
        console.log("valueOfTrackedTokensIncludeVaultBuffer after investment:%s,totalAssetsIncludeVaultBuffer：%s", new BigNumber(await iVault.valueOfTrackedTokensIncludeVaultBuffer()).toFixed(), new BigNumber(await iVault.totalAssetsIncludeVaultBuffer()).toFixed());
       
        Utils.assertBNGt(balanceOf, 0);
    });


    it('Verify：Vault can be invested in other assets normally', async function () {
        await iVault.addAsset(MFC.stETH_ADDRESS, {from: governance});
       
        await stethToken.approve(iVault.address, 0, {
            from: farmer1
        });
        await stethToken.approve(iVault.address, stethDepositAmount, {
            from: farmer1
        });

       
        console.log("Balance of stETH of farmer1 before investing:", new BigNumber(await stethToken.balanceOf(farmer1)).toFixed());
        console.log("stethDepositAmount:", stethDepositAmount.toFixed());
        console.log("Balance of ETH of farmer1 before investing:",new BigNumber(await balance.current(farmer1)).toFixed());

        await iVault.mint(MFC.stETH_ADDRESS, stethDepositAmount, 0, {from: farmer1});
        console.log("Balance of stETH of farmer1 after investment:", new BigNumber(await stethToken.balanceOf(farmer1)).toFixed());
        const balanceOf = new BigNumber(await pegToken.balanceOf(farmer1)).toFixed();
        console.log("Balance of ETHi of farmer1 after investment", balanceOf);
        console.log("Balance of ETH of farmer1 after investment:",new BigNumber(await balance.current(farmer1)).toFixed());

        console.log("totalAssets after investment:%d,totalValue：%s", new BigNumber(await iVault.totalAssets()).toFixed(), new BigNumber(await iVault.totalValue()).toFixed());
        console.log("totalDebt after investment:%d,totalValueInStrategies：%s", new BigNumber(await iVault.totalDebt()).toFixed(), new BigNumber(await iVault.totalValueInStrategies()).toFixed());
        console.log("valueOfTrackedTokens after investment:%d,totalValueInVault：%s", new BigNumber(await iVault.valueOfTrackedTokens()).toFixed(), new BigNumber(await iVault.totalValueInVault()).toFixed());
        console.log("valueOfTrackedTokensIncludeVaultBuffer after investment:%s,totalAssetsIncludeVaultBuffer：%s", new BigNumber(await iVault.valueOfTrackedTokensIncludeVaultBuffer()).toFixed(), new BigNumber(await iVault.totalAssetsIncludeVaultBuffer()).toFixed());

        // await iVault.setTrusteeFeeBps(1000, {from: governance});

        await iVault.setRebaseThreshold(1, {from: governance});

        console.log('rebaseThreshold: %s', (await iVault.rebaseThreshold()).toString());

        //startAdjustPosition
        const tx = await iVault.startAdjustPosition({from: keeper});
        const gasUsed = tx.receipt.gasUsed;
        console.log('startAdjustPosition gasUsed: %d', gasUsed);

        console.log("Balance of stETH of vault after start adjust position:%s", new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed());
        console.log("Balance of ETH of vault after start adjust position:%s", new BigNumber(await balance.current(iVault.address)).toFixed());
        console.log("Balance of ETHi of farmer1 after start adjust position:%s", new BigNumber(await pegToken.balanceOf(farmer1)).toFixed());
        console.log("Balance of stETH of farmer1 after start adjust position:%s", new BigNumber(await stethToken.balanceOf(farmer1)).toFixed());
        console.log("Balance of ETH of farmer1 after start adjust position:%s", new BigNumber(await balance.current(farmer1)).toFixed());
        console.log("Balance of tETHi of farmer1 after start adjust position:%s", new BigNumber(await vaultBuffer.balanceOf(farmer1)).toFixed());
        console.log("valueOfTrackedTokensIncludeVaultBuffer after start adjust position:%s,totalAssetsIncludeVaultBuffer：%s", new BigNumber(await iVault.valueOfTrackedTokensIncludeVaultBuffer()).toFixed(), new BigNumber(await iVault.totalAssetsIncludeVaultBuffer()).toFixed());

    });

    it('Verify：Vault can be lend normally', async function () {
        let addToVaultStrategies = new Array();
        let withdrawQueque = new Array();
        addToVaultStrategies.push({
            strategy: mockS3CoinStrategy.address,
            profitLimitRatio: 100,
            lossLimitRatio: 100
        });
        withdrawQueque.push(mockS3CoinStrategy.address);
        await iVault.addStrategy(addToVaultStrategies, {from: governance});
        await iVault.setWithdrawalQueue(withdrawQueque, {from: governance});

        const beforeETH = new BigNumber(await balance.current(iVault.address)).toFixed();
        const beforestETH = new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed();
        console.log("Balance of ETH of vault before lend:", beforeETH);
        console.log("Balance of stETH of vault before lend:", beforestETH);
        console.log("totalAssets before lend:%d,totalValue：%s", new BigNumber(await iVault.totalAssets()).toFixed(), new BigNumber(await iVault.totalValue()).toFixed());
        console.log("totalDebt before lend:%d,totalValueInStrategies：%s", new BigNumber(await iVault.totalDebt()).toFixed(), new BigNumber(await iVault.totalValueInStrategies()).toFixed());
        console.log("valueOfTrackedTokens before lend:%d,totalValueInVault：%s", new BigNumber(await iVault.valueOfTrackedTokens()).toFixed(), new BigNumber(await iVault.totalValueInVault()).toFixed());
        
        let tokens = [MFC.stETH_ADDRESS, MFC.ETH_ADDRESS];
        let amounts = [beforestETH, beforeETH];
        let exchangeArray = await Promise.all(
            map(tokens, async (tokenItem, index) => {
                const exchangeAmounts = amounts[index].toString();

                // 根据key获取value，不可写错
                let platformAdapter = {
                    paraswap: exchangePlatformAdapters.paraswap,
                    oneInchV4: exchangePlatformAdapters.oneInchV4
                };
                const SWAP_INFO = await getBestSwapInfo({
                    address: tokenItem,
                    symbol: 'ETH',
                    decimals: 18
                }, {
                    address: tokenItem,
                    symbol: 'ETH',
                    decimals: 18
                }, exchangeAmounts, 100, 500, platformAdapter, EXCHANGE_EXTRA_PARAMS);

                return {
                    fromToken: tokenItem,
                    toToken: tokenItem,
                    fromAmount: exchangeAmounts,
                    exchangeParam: {                        
                        platform: SWAP_INFO.platform,
                        method: SWAP_INFO.method,
                        encodeExchangeArgs: SWAP_INFO.encodeExchangeArgs,
                        slippage: 100,
                        oracleAdditionalSlippage: 0
                    }
                }
            })
        );

        await iVault.lend(mockS3CoinStrategy.address, exchangeArray,{from: keeper});

        console.log("totalAssets after lend:%d,totalValue：%s", new BigNumber(await iVault.totalAssets()).toFixed(), new BigNumber(await iVault.totalValue()).toFixed());
        console.log("totalDebt after lend:%d,totalValueInStrategies：%s", new BigNumber(await iVault.totalDebt()).toFixed(), new BigNumber(await iVault.totalValueInStrategies()).toFixed());
        console.log("valueOfTrackedTokens after lend:%d,totalValueInVault：%s", new BigNumber(await iVault.valueOfTrackedTokens()).toFixed(), new BigNumber(await iVault.totalValueInVault()).toFixed());

        const afterstETH = new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed();
        console.log("Balance of stETH of vault after lend:", afterstETH);
        console.log("Balance of ETH of vault after lend:",new BigNumber(await balance.current(iVault.address)).toFixed());

        Utils.assertBNGt(beforestETH, afterstETH);

        const tx = await iVault.endAdjustPosition({from: keeper});
        const gasUsed = tx.receipt.gasUsed;
        console.log('endAdjustPosition gasUsed: %d', gasUsed);

        console.log('start distributeWhenDistributing');
        await vaultBuffer.distributeWhenDistributing({from: keeper});
        console.log('end distributeWhenDistributing');

        console.log("Balance of ETHi of farmer1 after end adjust position:%s", new BigNumber(await pegToken.balanceOf(farmer1)).toFixed());
        console.log("underlyingUnitsPerShare  after end adjust position:%s", new BigNumber(await iVault.underlyingUnitsPerShare()).toFixed());
        console.log("Balance of share of farmer1 after end adjust position:%s", new BigNumber(await pegToken.sharesOf(farmer1)).toFixed());
        console.log("valueOfTrackedTokensIncludeVaultBuffer after end adjust position:%s,totalAssetsIncludeVaultBuffer：%s", new BigNumber(await iVault.valueOfTrackedTokensIncludeVaultBuffer()).toFixed(), new BigNumber(await iVault.totalAssetsIncludeVaultBuffer()).toFixed());

        const _amount = new BigNumber(await pegToken.balanceOf(farmer1)).div(4).multipliedBy(1).toFixed();
        const _toAsset = MFC.ETH_ADDRESS;
        console.log("withdraw asset:ETH");
        console.log("Number of ETHi withdraw:%s", new BigNumber(_amount).toFixed());
        const resp = await iVault.burn.call(_amount, _toAsset, 0, false, [], {
            from: farmer1
        });

        tokens = resp[0];
        amounts = resp[1];

        console.log("---------tokens------amounts--------------");
        console.log(tokens);
        console.log(amounts[0].toString(),amounts[1].toString());
        exchangeArray = await Promise.all(
            map(tokens, async (tokenItem, index) => {
                const exchangeAmounts = amounts[index].toString();
                if (tokenItem === _toAsset) {
                    return;
                }
                let platformAdapter = {
                    paraswap: exchangePlatformAdapters.paraswap,
                    oneInchV4: exchangePlatformAdapters.oneInchV4
                };
                const SWAP_INFO = await getBestSwapInfo({
                    // platform: exchangePlatformAdapters.paraswap,
                    address: tokenItem,
                    symbol: 'ETH',
                    decimals: 18
                }, {
                    // platform: exchangePlatformAdapters.oneInchV4,
                    address: _toAsset,
                    symbol: 'stETH',
                    decimals: 18
                }, exchangeAmounts, 500, 500, platformAdapter, EXCHANGE_EXTRA_PARAMS);

                console.log("SWAP_INFO");
                console.log(SWAP_INFO);

                return {
                    fromToken: tokenItem,
                    toToken: _toAsset,
                    fromAmount: exchangeAmounts,
                    exchangeParam: {
                        platform: SWAP_INFO.platform,
                        method: SWAP_INFO.method,
                        encodeExchangeArgs: SWAP_INFO.encodeExchangeArgs,
                        slippage: 4999,
                        oracleAdditionalSlippage: 4999
                    }
                }
            })
        );

        const exchangeArrayNext = filter(exchangeArray, i => !isEmpty(i));
        const beforeBalance = new BigNumber(await balance.current(farmer1)).toFixed();
        await iVault.burn(_amount, _toAsset, 0, true, exchangeArrayNext, {from: farmer1});
        // await iVault.burn(_amount, _toAsset, 0, true, [], {from: farmer1});
        const afterBalance = new BigNumber(await balance.current(farmer1)).toFixed();

        console.log("Balance of stETH of vault after withdraw:%s", new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed());
        console.log("Balance of ETH of vault after withdraw:%s", new BigNumber(await balance.current(iVault.address)).toFixed());
        console.log("Balance of ETHi of farmer1 after withdraw:%s", new BigNumber(await pegToken.balanceOf(farmer1)).toFixed());
        console.log("Balance of stETH of farmer1 after withdraw:%s", new BigNumber(await stethToken.balanceOf(farmer1)).toFixed());
        console.log("Balance of ETH of farmer1 after withdraw:%s", afterBalance);
        Utils.assertBNGt(afterBalance, beforeBalance);

        console.log("valueOfTrackedTokensIncludeVaultBuffer after withdraw:%s,totalAssetsIncludeVaultBuffer：%s", new BigNumber(await iVault.valueOfTrackedTokensIncludeVaultBuffer()).toFixed(), new BigNumber(await iVault.totalAssetsIncludeVaultBuffer()).toFixed());

        console.log("valueOfTrackedTokensIncludeVaultBuffer after withdraw:%s,totalAssetsIncludeVaultBuffer：%s", new BigNumber(await iVault.valueOfTrackedTokensIncludeVaultBuffer()).toFixed(), new BigNumber(await iVault.totalAssetsIncludeVaultBuffer()).toFixed());
        console.log("Balance of stETH of mockS3CoinStrategy after withdraw:%s",new BigNumber(await stethToken.balanceOf(mockS3CoinStrategy.address)).toFixed());
        console.log("mockS3CoinStrategy's estimatedTotalAssets after withdraw:%s",new BigNumber(await mockS3CoinStrategy.estimatedTotalAssets()).toFixed());
        await stethToken.transfer(mockS3CoinStrategy.address, new BigNumber(await stethToken.balanceOf(farmer1)).div(1000).toFixed(), {
            from: farmer1,
        });
        console.log("Balance of stETH of mockS3CoinStrategy after transfer stETH to mockS3CoinStrategy:%s",new BigNumber(await stethToken.balanceOf(mockS3CoinStrategy.address)).toFixed());
        console.log("mockS3CoinStrategy's estimatedTotalAssets after transfer stETH to mockS3CoinStrategy:%s",new BigNumber(await mockS3CoinStrategy.estimatedTotalAssets()).toFixed());
        console.log("valueOfTrackedTokensIncludeVaultBuffer after transfer stETH to mockS3CoinStrategy:%s,totalAssetsIncludeVaultBuffer：%s", new BigNumber(await iVault.valueOfTrackedTokensIncludeVaultBuffer()).toFixed(), new BigNumber(await iVault.totalAssetsIncludeVaultBuffer()).toFixed());
    });

    it('Verify: Vault can be properly reported', async function () {
        const beforeETHI = new BigNumber(await pegToken.balanceOf(treasuryAddress)).toFixed();
        console.log("Balance of ETHi of treasury before report", new BigNumber(await pegToken.balanceOf(treasuryAddress)).toFixed());
        await mockS3CoinStrategy.harvest({from:keeper,value:2*(10**18)});
        await iVault.rebase({from:keeper});
        const afterETHI = new BigNumber(await pegToken.balanceOf(treasuryAddress)).toFixed();
        console.log("Balance of ETHi of treasury after report:", new BigNumber(await pegToken.balanceOf(treasuryAddress)).toFixed());
        Utils.assertBNGt(afterETHI, beforeETHI);
    });

    it('Verify：new funds deposit to vault', async function () {

        console.log("Balance of ETH of farmer2 before deposit:%s", new BigNumber(await balance.current(farmer2)).toFixed());
        console.log("Balance of stETH of farmer2 before deposit:%s", new BigNumber(await stethToken.balanceOf(farmer2)).toFixed());

        console.log("adjustPositionPeriod:%s",await iVault.adjustPositionPeriod());

        console.log("Balance of ETH of vault before deposit:%s", new BigNumber(await balance.current(iVault.address)).toFixed());
        console.log("Balance of stETH of vault before deposit:%s", new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed());
        //deposit with ETH
        const ethAmount = new BigNumber(10).pow(18).multipliedBy(10).toFixed();
        let tx  = await iVault.mint(MFC.ETH_ADDRESS, ethAmount,0, {from: farmer2,value: ethAmount});
        let gasUsed = tx.receipt.gasUsed;
        console.log('endAdjustPosition gasUsed: %d', gasUsed);

        console.log("Balance of ETH of vault after deposit:%s", new BigNumber(await balance.current(iVault.address)).toFixed());
        console.log("Balance of stETH of vault after deposit:%s", new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed());

        console.log("Balance of ETH of farmer2 after deposit:%s", new BigNumber(await balance.current(farmer2)).toFixed());
        console.log("Balance of stETH of farmer2 after deposit:%s", new BigNumber(await stethToken.balanceOf(farmer2)).toFixed());
        console.log("Balance of tETHi of farmer2 after deposit:%s", new BigNumber(await vaultBuffer.balanceOf(farmer2)).toFixed());

        console.log("totalAssets after deposit:%s,totalValue：%s", new BigNumber(await iVault.totalAssets()).toFixed(), new BigNumber(await iVault.totalValue()).toFixed());
        console.log("totalDebt after deposit:%s,totalValueInStrategies：%s", new BigNumber(await iVault.totalDebt()).toFixed(), new BigNumber(await iVault.totalValueInStrategies()).toFixed());
        console.log("valueOfTrackedTokens after deposit:%s,totalValueInVault：%s", new BigNumber(await iVault.valueOfTrackedTokens()).toFixed(), new BigNumber(await iVault.totalValueInVault()).toFixed());
        console.log("valueOfTrackedTokensIncludeVaultBuffer after deposit:%s,totalAssetsIncludeVaultBuffer：%s", new BigNumber(await iVault.valueOfTrackedTokensIncludeVaultBuffer()).toFixed(), new BigNumber(await iVault.totalAssetsIncludeVaultBuffer()).toFixed());

        //startAdjustPosition
        console.log("start Adjust Position");
         tx =  await iVault.startAdjustPosition({from: keeper});
         gasUsed = tx.receipt.gasUsed;
        console.log('startAdjustPosition gasUsed: %d', gasUsed);
        console.log("Balance of ETH of vault before redeem:%s", new BigNumber(await balance.current(iVault.address)).toFixed());
        console.log("Balance of stETH of vault before redeem:%s", new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed());
        console.log("(amount,totalDebt)=(%s,%s)", new BigNumber(await iVault.totalDebt()).div(5).toFixed(),new BigNumber(await iVault.totalDebt()).toFixed());
        let beforeETH = new BigNumber(await balance.current(iVault.address)).toFixed();
        console.log("redeem amount: %s",new BigNumber(await iVault.totalDebt()).div(5).toFixed())
        tx =  await iVault.redeem(mockS3CoinStrategy.address, new BigNumber(await iVault.totalDebt()).div(5).toFixed(), 0);
        gasUsed = tx.receipt.gasUsed;
        console.log('redeem gasUsed: %d', gasUsed);
        let afterETH = new BigNumber(await balance.current(iVault.address)).toFixed();

        console.log("Balance of ETH of vault after redeem:%s", new BigNumber(await balance.current(iVault.address)).toFixed());
        console.log("Balance of stETH of vault after redeem:%s", new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed());

        console.log("valueOfTrackedTokens after redeem:%s", new BigNumber(await iVault.valueOfTrackedTokens()).toFixed());
        console.log("totalAssets after redeem:%s", new BigNumber(await iVault.totalAssets()).toFixed());
        Utils.assertBNGt(afterETH, beforeETH);

        beforeETH = new BigNumber(await balance.current(iVault.address)).toFixed();
        console.log("(ETH,stETH)=(%s,%s)", new BigNumber(await balance.current(iVault.address)).toFixed(), new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed());
        let tokens = [MFC.ETH_ADDRESS, MFC.stETH_ADDRESS];
        let amounts = [new BigNumber(await balance.current(iVault.address)).toFixed(), new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed()];
        let exchangeArray = await Promise.all(
            map(tokens, async (tokenItem, index) => {
                const exchangeAmounts = amounts[index].toString();
                return {
                    fromToken: tokenItem,
                    toToken: tokenItem,
                    fromAmount: exchangeAmounts,
                    exchangeParam: {
                        platform: exchangePlatformAdapters.paraswap,
                        method: 0,
                        encodeExchangeArgs: '0x',
                        slippage: 0,
                        oracleAdditionalSlippage: 0
                    }
                }
            })
        );

        await iVault.lend(mockS3CoinStrategy.address, exchangeArray);

        console.log("totalAssets after lend:%s,totalValue：%s", new BigNumber(await iVault.totalAssets()).toFixed(), new BigNumber(await iVault.totalValue()).toFixed());
        console.log("totalDebt after lend:%s,totalValueInStrategies：%s", new BigNumber(await iVault.totalDebt()).toFixed(), new BigNumber(await iVault.totalValueInStrategies()).toFixed());
        console.log("valueOfTrackedTokens after lend:%s,totalValueInVault：%s", new BigNumber(await iVault.valueOfTrackedTokens()).toFixed(), new BigNumber(await iVault.totalValueInVault()).toFixed());

        afterETH = new BigNumber(await balance.current(iVault.address)).toFixed();
        console.log("Balance of ETH of vault after lend:%s", afterETH);
        console.log(" Balance of stETH of vault after lend:%s", new BigNumber(await stethToken.balanceOf(iVault.address)).toFixed());
        Utils.assertBNGt(beforeETH, afterETH);

        tx = await iVault.endAdjustPosition({from: keeper});
        gasUsed = tx.receipt.gasUsed;
        console.log('endAdjustPosition gasUsed: %d', gasUsed);

        console.log('start distributeWhenDistributing');
        await vaultBuffer.distributeWhenDistributing({from: keeper});
        console.log('end distributeWhenDistributing');

        console.log("Balance of ETHi of farmer1 after end Adjust Position:%s", new BigNumber(await pegToken.balanceOf(farmer1)).toFixed());
        console.log("Balance of ETHi of farmer2 after end Adjust Position:%s", new BigNumber(await pegToken.balanceOf(farmer2)).toFixed());
        console.log("valueOfTrackedTokensIncludeVaultBuffer after end Adjust Position:%s,totalAssetsIncludeVaultBuffer：%s", new BigNumber(await iVault.valueOfTrackedTokensIncludeVaultBuffer()).toFixed(), new BigNumber(await iVault.totalAssetsIncludeVaultBuffer()).toFixed());
    });

    it('Verify：burn from strategy', async function (){
        await iVault.rebase();
        const treasuryLp =  new BigNumber(await pegToken.balanceOf(treasuryAddress)).toFixed();
        await treasury.withdraw(pegToken.address, governance, new BigNumber(treasuryLp).toFixed(), {from: governance});

        console.log("totalValueInStrategies before withdraw: %s",new BigNumber(await iVault.totalAssets()).minus(new BigNumber(await iVault.valueOfTrackedTokens())).toFixed());
        console.log("totalAssets before withdraw: %s",new BigNumber(await iVault.totalAssets()).toFixed());
        console.log("Balance of ETHi of farmer1 before withdraw: %s", new BigNumber(await pegToken.balanceOf(farmer1)).toFixed());
        console.log("Balance of ETHi of farmer2 before withdraw: %s", new BigNumber(await pegToken.balanceOf(farmer2)).toFixed());
        console.log("Balance of ETHi of governance before withdraw: %s", new BigNumber(await pegToken.balanceOf(governance)).toFixed());
        let _amount =  new BigNumber(await pegToken.balanceOf(farmer1)).toFixed();
        await iVault.burn(_amount, MFC.ETH_ADDRESS, 0, false, [], {from: farmer1});
        console.log("totalValueInStrategies after farmer1 withdraw: %s",new BigNumber(await iVault.totalAssets()).minus(new BigNumber(await iVault.valueOfTrackedTokens())).toFixed());
        _amount =  new BigNumber(await pegToken.balanceOf(governance)).toFixed();
        await iVault.burn(_amount, MFC.ETH_ADDRESS, 0, false, [], {from: governance});
        console.log("totalValueInStrategies after governance withdraw: %s",new BigNumber(await iVault.totalAssets()).minus(new BigNumber(await iVault.valueOfTrackedTokens())).toFixed());
        _amount =  new BigNumber(await pegToken.balanceOf(farmer2)).minus(new BigNumber(10).pow(15)).plus(10).toFixed();
        await iVault.burn(_amount, MFC.ETH_ADDRESS, 0, false, [], {from: farmer2});
        const totalValueInStrategies = new BigNumber(await iVault.totalAssets()).minus(new BigNumber(await iVault.valueOfTrackedTokens())).toFixed();
        console.log("totalValueInStrategies after withdraw: %s",totalValueInStrategies);
        console.log("totalAssets after withdraw: %s",new BigNumber(await iVault.totalAssets()).toFixed());
        console.log("Balance of ETHi of farmer1 after withdraw: %s", new BigNumber(await pegToken.balanceOf(farmer1)).toFixed());
        console.log("Balance of ETHi of farmer2 after withdraw: %s", new BigNumber(await pegToken.balanceOf(farmer2)).toFixed());
        console.log("Balance of ETHi of governance after withdraw: %s", new BigNumber(await pegToken.balanceOf(governance)).toFixed());

        Utils.assertBNEq(totalValueInStrategies, 0);
    });

    it('Verify：multicall', async function (){
        await iVault.multicall([
            iVault.contract.methods.setMaxTimestampBetweenTwoReported(1000).encodeABI(),
            iVault.contract.methods.setRedeemFeeBps(1000).encodeABI(),
            iVault.contract.methods.setMinimumInvestmentAmount(10000000000000).encodeABI()
        ],{from:governance});
        console.log(new BigNumber(await iVault.maxTimestampBetweenTwoReported()).toFixed());
        console.log(new BigNumber(await iVault.minimumInvestmentAmount()).toFixed());
        Utils.assertBNEq(new BigNumber(await iVault.maxTimestampBetweenTwoReported()).toFixed(), 1000);
    });
});