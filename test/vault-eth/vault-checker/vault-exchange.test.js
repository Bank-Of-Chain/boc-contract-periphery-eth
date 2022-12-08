/**
 * Vault rule：
 * 1. remove asset
 * 2. add asset
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
    mapKeys,
    map,
    filter,
    isEmpty,
    every
} = require("lodash");

const {
    send,
    balance
} = require('@openzeppelin/test-helpers');

const {
    setupCoreProtocol,
} = require('../../../utils/contract-utils-eth');
const {
    topUpSTETHByAddress,
    topUpEthByAddress,
    topUpWETHByAddress,
    tranferBackUsdt,
} = require('../../../utils/top-up-utils');

// === Constants === //
const MFC = require('../../../config/mainnet-fork-test-config');
const {strategiesList} = require('../../../config/strategy-eth/strategy-config-eth');
const {getBestSwapInfo} = require("piggy-finance-utils");
const hre = require("hardhat");
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const ExchangeAggregator = hre.artifacts.require("ExchangeAggregator")

const EXCHANGE_EXTRA_PARAMS = {
    oneInchV4: {
        useHttp: true,
        network: 1,
        protocols: 'CURVE_V2,SUSHI,CURVE,UNISWAP_V2,UNISWAP_V3'
    },
    // paraswap: {
    //     network: 1,
    //     includeDEXS: 'UniswapV2,UniswapV3,SushiSwap,mStable,DODOV2,DODOV1,Curve,CurveV2,Compound,Bancor,BalancerV2,Aave2',
    //     excludeContractMethods: ['swapOnZeroXv2', 'swapOnZeroXv4']
    // }
}
const EXCHANGE_EXTRA_PARAMS2 = {
    // oneInchV4: {
    //     useHttp: true,
    //     network: 1,
    //     protocols: 'CURVE_V2,SUSHI,CURVE,UNISWAP_V2,UNISWAP_V3'
    // },
    paraswap: {
        network: 1,
        // includeDEXS: 'UniswapV2,UniswapV3,SushiSwap,mStable,DODOV2,DODOV1,Curve,CurveV2,Compound,Bancor,BalancerV2,Aave2',
        excludeContractMethods: ['swapOnZeroXv2', 'swapOnZeroXv4']
    }
}

describe('【Vault unit exchange】', function () {
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
    let valueInterpreter;
    let exchangePlatformAdapters;
    let addToVaultStrategies;
    let farmer1Lp

    before(async function () {
        tokenDecimals = new BigNumber(18);
        depositAmount = new BigNumber(10).pow(tokenDecimals).multipliedBy(100);
        await ethers.getSigners().then((resp) => {
            accounts = resp;
            governance = accounts[0].address;
            farmer1 = accounts[1].address;
            keeper = accounts[19].address;
        });
        await topUpEthByAddress(depositAmount*2, keeper);
        await topUpSTETHByAddress(depositAmount, keeper);
        await topUpWETHByAddress(depositAmount, keeper);
        await setupCoreProtocol(MFC.ETH_ADDRESS, governance, keeper, false).then((resp) => {
            vault = resp.vault;
            underlying = resp.underlying;
            valueInterpreter = resp.valueInterpreter;
            exchangePlatformAdapters = resp.exchangePlatformAdapters;
            addToVaultStrategies = resp.addToVaultStrategies;
        });
    });
    after(async function () {
        await tranferBackUsdt(farmer1);
    });

    it('verify：Vault exchange', async function () {
        let fromToken = MFC.stETH_ADDRESS;
        let toToken =  MFC.ETH_ADDRESS;
        const fromAmount = depositAmount;
        const fromTokenERC = await ERC20.at(fromToken);
        // const toTokenERC = await ERC20.at(toToken);
        const fromTokenDecimals = new BigNumber(await fromTokenERC.decimals());
        const toTokenDecimals = new BigNumber(18);
        const fromTokenSymbol = await fromTokenERC.symbol();
        const toTokenSymbol = 'ETH';

        // let fromTokenArray = [fromToken];
        // let amountArray = [depositAmount, depositAmount];
        // let exchangeArray = await Promise.all(
        //     map(fromTokenArray, async (fromToken, index) => {
        //         const exchangeAmounts = amountArray[index].toString();

                // get value by key
                let platformAdapter = {
                    // paraswap: exchangePlatformAdapters.paraswap,
                    oneInchV4: exchangePlatformAdapters.oneInchV4
                };
                const SWAP_INFO = await getBestSwapInfo({
                    address: fromToken,
                    symbol: fromTokenSymbol,
                    decimals: fromTokenDecimals
                }, {
                    address: toToken,
                    symbol: toTokenSymbol,
                    decimals: toTokenDecimals
                }, fromAmount.div(2), 4999, 4999, platformAdapter, EXCHANGE_EXTRA_PARAMS);

                let exchangeParam = {
                        platform: SWAP_INFO.platform,
                        method: SWAP_INFO.method,
                        encodeExchangeArgs: SWAP_INFO.encodeExchangeArgs,
                        slippage: SWAP_INFO.slippage,
                        oracleAdditionalSlippage: SWAP_INFO.oracleAdditionalSlippage
                    };
            // })
        // );
        console.log(exchangeParam);

        // await fromTokenERC.approve(vault.address, 0, {
        //     from: keeper
        // });
        // await fromTokenERC.approve(vault.address, fromAmount, {
        //     from: keeper
        // });
        await topUpSTETHByAddress(fromAmount, vault.address);
        // await fromTokenERC.transfer(vault.address,fromAmount, {from: keeper});
        const fromTokenBalanceBefore = new BigNumber(await fromTokenERC.balanceOf(vault.address));
        const toTokenBalanceBefore = new BigNumber(await balance.current(vault.address));
        // const toTokenBalanceBefore = new BigNumber(await toTokenERC.balanceOf(vault.address));
        console.log("Balance of %s of Vault before exchange: %s", fromTokenSymbol, new BigNumber(await fromTokenERC.balanceOf(vault.address)).toFixed());
        console.log("Balance of %s of Vault before exchange: %s", toTokenSymbol, new BigNumber(await balance.current(vault.address)).toFixed());

        await vault.exchange(fromToken, toToken, fromAmount.div(2).toFixed(), exchangeParam, {from: keeper});
        const fromTokenBalanceAfter = new BigNumber(await fromTokenERC.balanceOf(vault.address));
        const toTokenBalanceAfter = new BigNumber(await balance.current(vault.address));
        console.log("Balance of %s of Vault after exchange: %s", fromTokenSymbol, new BigNumber(await fromTokenERC.balanceOf(vault.address)).toFixed());
        console.log("Balance of %s of Vault after exchange: %s", toTokenSymbol, new BigNumber(await balance.current(vault.address)).toFixed());

        Utils.assertBNGt(toTokenBalanceAfter.minus(toTokenBalanceBefore), 0);
        Utils.assertBNGt(fromTokenBalanceBefore.minus(fromTokenBalanceAfter), fromAmount.div(2).minus(2).toFixed());
        Utils.assertBNGt(fromAmount.div(2).plus(2).toFixed(),fromTokenBalanceBefore.minus(fromTokenBalanceAfter));

    });


    it('verify：ExchangeAggregator exchange', async function () {
        let fromToken = MFC.ETH_ADDRESS;
        let fromToken2 = MFC.WETH_ADDRESS;
        let toToken =  MFC.stETH_ADDRESS;
        const fromAmount = depositAmount;
        const fromToken2ERC = await ERC20.at(fromToken2);
        const toTokenERC = await ERC20.at(toToken);
        const fromTokenDecimals = 18;
        const fromToken2Decimals = new BigNumber(await fromToken2ERC.decimals());
        const toTokenDecimals = new BigNumber(await toTokenERC.decimals());
        const fromTokenSymbol = 'ETH';
        const fromToken2Symbol = await fromToken2ERC.symbol();
        const toTokenSymbol = await toTokenERC.symbol();

        // let fromTokenArray = [fromToken];
        // let amountArray = [depositAmount, depositAmount];
        // let exchangeArray = await Promise.all(
        //     map(fromTokenArray, async (fromToken, index) => {
        //         const exchangeAmounts = amountArray[index].toString();

        // get value by key
        let platformAdapter = {
            // paraswap: exchangePlatformAdapters.paraswap,
            oneInchV4: exchangePlatformAdapters.oneInchV4
        };
        let platformAdapter2 = {
            paraswap: exchangePlatformAdapters.paraswap,
            // oneInchV4: exchangePlatformAdapters.oneInchV4
        };

        const SWAP_INFO = await getBestSwapInfo({
            address: fromToken,
            symbol: fromTokenSymbol,
            decimals: fromTokenDecimals
        }, {
            address: toToken,
            symbol: toTokenSymbol,
            decimals: toTokenDecimals
        }, fromAmount.div(2).toFixed(), 4999, 4999, platformAdapter, EXCHANGE_EXTRA_PARAMS);

        const SWAP_INFO2 = await getBestSwapInfo({
            address: fromToken2,
            symbol: fromToken2Symbol,
            decimals: fromToken2Decimals
        }, {
            address: toToken,
            symbol: toTokenSymbol,
            decimals: toTokenDecimals
        }, fromAmount.div(2).toFixed(), 4999, 4999, platformAdapter2, EXCHANGE_EXTRA_PARAMS2);

        // })
        // );
        const exchangeManagerAddress = await vault.exchangeManager();

        // await fromTokenERC.approve(exchangeManagerAddress, fromAmount.div(2).toFixed(), {
        //     from: keeper
        // });
        await fromToken2ERC.approve(exchangeManagerAddress, fromAmount.div(2).toFixed(), {
            from: keeper
        });

        console.log('allowance2',new BigNumber(await fromToken2ERC.allowance(keeper,exchangeManagerAddress)).toFixed());
        const fromTokenBalanceBefore = new BigNumber(await balance.current(keeper));
        const fromToken2BalanceBefore = new BigNumber(await fromToken2ERC.balanceOf(keeper));
        const toTokenBalanceBefore = new BigNumber(await toTokenERC.balanceOf(keeper));
        console.log("Balance of %s of keeper before exchange: %s", fromTokenSymbol, new BigNumber(await balance.current(keeper)).toFixed());
        console.log("Balance of %s of keeper before exchange: %s", fromToken2Symbol, new BigNumber(await fromToken2ERC.balanceOf(keeper)).toFixed());
        console.log("Balance of %s of keeper before exchange: %s", toTokenSymbol, new BigNumber(await toTokenERC.balanceOf(keeper)).toFixed());

        const exchangeAggregator = await ExchangeAggregator.at(exchangeManagerAddress);
        let _swapDescription = {
            amount: fromAmount.div(2).toFixed(),
            srcToken: fromToken,
            dstToken: toToken,
            receiver: keeper
        };
        let swapParam = {
            platform: SWAP_INFO.platform,
            method: SWAP_INFO.method,
            data: SWAP_INFO.encodeExchangeArgs,
            swapDescription: _swapDescription
        }

        let _swapDescription2 = {
            amount: fromAmount.div(2).toFixed(),
            srcToken: fromToken2,
            dstToken: toToken,
            receiver: keeper
        };
        let swapParam2 = {
            platform: SWAP_INFO2.platform,
            method: SWAP_INFO2.method,
            data: SWAP_INFO2.encodeExchangeArgs,
            swapDescription: _swapDescription2
        }

        await exchangeAggregator.batchSwap([swapParam,swapParam2],{
            value: fromAmount.div(2).toFixed(),
            from: keeper
        });

        const fromTokenBalanceAfter = new BigNumber(await balance.current(keeper));
        const fromToken2BalanceAfter = new BigNumber(await fromToken2ERC.balanceOf(keeper));
        const toTokenBalanceAfter = new BigNumber(await toTokenERC.balanceOf(keeper));
        console.log("Balance of %s of keeper after exchange: %s", fromTokenSymbol, new BigNumber(await balance.current(keeper)).toFixed());
        console.log("Balance of %s of keeper after exchange: %s", fromToken2Symbol, new BigNumber(await fromToken2ERC.balanceOf(keeper)).toFixed());
        console.log("Balance of %s of keeper after exchange: %s", toTokenSymbol, new BigNumber(await toTokenERC.balanceOf(keeper)).toFixed());

        Utils.assertBNGt(toTokenBalanceAfter.minus(toTokenBalanceBefore), 0);
        Utils.assertBNGt(fromTokenBalanceBefore.minus(fromTokenBalanceAfter), fromAmount.div(2).toFixed());
        Utils.assertBNGt(fromAmount.div(2).toFixed(),fromTokenBalanceBefore.minus(fromTokenBalanceAfter).minus(10**17));
        Utils.assertBNEq(fromToken2BalanceBefore.minus(fromToken2BalanceAfter), fromAmount.div(2).toFixed());

    });

});

