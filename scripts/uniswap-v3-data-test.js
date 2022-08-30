const axios = require('axios');
const lodash = require('lodash');
const moment = require('moment');
const {default: BigNumber} = require('bignumber.js');

const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const UniswapV3Pool = hre.artifacts.require('@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol');
const IVault = hre.artifacts.require('boc-contract-core/contracts/vault/IVault.sol:IVault');
const UniswapV3Strategy = hre.artifacts.require("UniswapV3Strategy");
const MockUniswapV3Router = hre.artifacts.require('contracts/usd/mock/MockUniswapV3Router.sol:MockUniswapV3Router');

const address = require('./../config/address-config');
const topUp = require('./../utils/top-up-utils');
const {advanceBlock} = require('./../utils/block-utils');

const main = async () => {
    const accounts = await ethers.getSigners();
    const investor = accounts[0].address;
    const keeper = accounts[19].address;

    const vaultAddress = '0x9d4454B023096f34B160D6B654540c56A1F81688';
    const vaultBufferAddress = '0x2bdCC0de6bE1f7D2ee689a0342D76F52E8EFABa3';
    const strategyAddress = '0x162A433068F51e18b7d13932F27e66a3f99E6890';
    const poolAddress = '0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36';
    const uniswapV3Pool = await UniswapV3Pool.at(poolAddress);
    const uniswapV3Strategy = await UniswapV3Strategy.at(strategyAddress);
    const bocVault = await IVault.at(vaultAddress);
    const mockUniswapV3Router = await MockUniswapV3Router.new();

    const token0Address = await uniswapV3Pool.token0();
    const token1Address = await uniswapV3Pool.token1();
    const token0 = await ERC20.at(token0Address);
    const token1 = await ERC20.at(token1Address);

    const token0Decimals = await token0.decimals();
    const token1Decimals = await token1.decimals();

//const slot0 = await uniswapV3Pool.slot0();
//console.log(`=== rebalance slot0.tick: ${slot0.tick} ===`);
//const MintInfo = await uniswapV3Strategy.getMintInfo()
//const PositionDetail = await uniswapV3Strategy.getPositionDetail()
//console.log('=== rebalanceByKeeper MintInfo %d,%d,%d,%d ===', MintInfo.baseTickUpper, MintInfo.baseTickLower, MintInfo.limitTickUpper, MintInfo.limitTickLower);
//console.log('=== rebalanceByKeeper PositionDetail %d, %d ===', PositionDetail._amounts[0], PositionDetail._amounts[1]);
    await bocVault.setStrategySetLimitRatio(strategyAddress, 1000000, 1000000, {'from': investor});
    const strategies = await bocVault.strategies(strategyAddress);
    console.log('=== strategies: %s ===', JSON.stringify(strategies));
//return
    await strategyInvest();

    let offset = 0;
    const limit = 100;
    let recordTimestamp = 0;
    let count = 0;
    while (true) {
        const eventsRes = await axios.get(`http://127.0.0.1:8081/tests/chain_ids/1/uniswap_v3s/events?offset=${offset}&limit=${limit}`);
        const events = eventsRes.data;
        if (lodash.isEmpty(events)) {
            break;
        }

        for (const event of events) {
            console.log(`=== while for blockNumber: ${event.blockNumber} ===`);

            const getDateByBlockRes = await axios.post(`http://127.0.0.1:8080/utils/getTimestampByBlock`, {
                chainId: 1,
                blockNumber: event.blockNumber
            });
            let tempTimestamp = getDateByBlockRes.data;
            if (recordTimestamp === 0) {
                recordTimestamp = (moment(tempTimestamp * 1000).utc().startOf('days') + 86400000) / 1000;
                console.log(`=== while first date blockNumber: ${event.blockNumber}, tempTimestamp: ${tempTimestamp}, recordTimestamp: ${recordTimestamp} ===`);
            } else {
                if (tempTimestamp >= recordTimestamp) {
                    await advanceBlock(1);
                    recordTimestamp = (moment(tempTimestamp * 1000).utc().startOf('days') + 86400000) / 1000;
                    console.log(`=== while change date blockNumber: ${event.blockNumber}, tempTimestamp: ${tempTimestamp}, recordTimestamp: ${recordTimestamp} ===`);
                    await strategyHarvest();
                    await strategyRebalance();
                }
            }

            const eventData = event.data;
            switch (event.eventName) {
                case 'Swap':
                    await swap(eventData.sender, poolAddress, eventData.amount0, eventData.amount1);
                    break;
                case 'Mint':
                    await mint(eventData.owner, poolAddress, eventData.tickLower, eventData.tickUpper, eventData.amount0, eventData.amount1, eventData.amount);
                    break;
                case 'Burn':
                    await burn(eventData.owner, poolAddress, eventData.tickLower, eventData.tickUpper, eventData.amount, eventData.amount0, eventData.amount1);
                    break;
                case 'Collect':
                    await collect(eventData.owner, poolAddress, eventData.tickLower, eventData.tickUpper, eventData.amount0, eventData.amount1, eventData.recipient);
                    break;
                default:
                    throw new Error('Unsupported product!');
            }

            count++;
        }
        offset += limit;
    }
    console.log(`=== while end count: ${count} ===`);

    async function mint(ownerAddress, poolAddress, tickLower, tickUpper, amount0, amount1, amount) {
        if (amount0 > 0) {
            await topUpAmount(token0Address, new BigNumber(amount0).multipliedBy(10), ownerAddress);
        }
        if (amount1 > 0) {
            await topUpAmount(token1Address, new BigNumber(amount1).multipliedBy(10), ownerAddress);
        }

        await topUp.sendEthers(ownerAddress);
        const callback = await topUp.impersonates([ownerAddress]);
        await token0.approve(mockUniswapV3Router.address, new BigNumber(0), {'from': ownerAddress});
        await token0.approve(mockUniswapV3Router.address, new BigNumber(amount0).multipliedBy(10), {'from': ownerAddress});
        await token1.approve(mockUniswapV3Router.address, new BigNumber(0), {'from': ownerAddress});
        await token1.approve(mockUniswapV3Router.address, new BigNumber(amount1).multipliedBy(10), {'from': ownerAddress});
//        console.log(`=== mint before token0.balanceOf: ${await token0.balanceOf(ownerAddress)}, token1.balanceOf: ${await token1.balanceOf(ownerAddress)} ===`);
        await mockUniswapV3Router.mint(poolAddress, tickLower, tickUpper, new BigNumber(amount), {'from': ownerAddress});
//        console.log(`=== mint after token0C.balanceOf: ${await token0.balanceOf(ownerAddress)}, token1.balanceOf: ${await token1.balanceOf(ownerAddress)} ===`);
        await callback();
    }

    async function burn(ownerAddress, poolAddress, tickLower, tickUpper, amount, amount0, amount1) {
        await topUp.sendEthers(ownerAddress);
        const callback = await topUp.impersonates([ownerAddress]);
        const liquidity = await uniswapV3Strategy.getLiquidityForAmounts(tickLower, tickUpper, new BigNumber(amount0), new BigNumber(amount1));
        if (liquidity < amount) {
            console.log('=== burn before uniswapV3Strategy.getLiquidityForAmounts: %d, amount: %d ===', liquidity, amount);
            amount = liquidity;
        }
//        console.log(`=== burn before uniswapV3Pool.liquidity: ${await uniswapV3Pool.liquidity()},  uniswapV3Pool.slot0: ${JSON.stringify(await uniswapV3Pool.slot0())} ===`);
        await uniswapV3Pool.burn(tickLower, tickUpper, new BigNumber(amount), {'from': ownerAddress});
//        console.log(`=== burn after uniswapV3Pool.liquidity: ${await uniswapV3Pool.liquidity()},  uniswapV3Pool.slot0: ${JSON.stringify(await uniswapV3Pool.slot0())} ===`);
        await callback();
    }

    async function collect(ownerAddress, poolAddress, tickLower, tickUpper, amount0Requested, amount1Requested, recipient) {
        await topUp.sendEthers(ownerAddress);
        const callback = await topUp.impersonates([ownerAddress]);
//        console.log(`=== collect before token0.balanceOf: ${await token0.balanceOf(recipient)}, token1.balanceOf: ${await token1.balanceOf(recipient)} ===`);
        await uniswapV3Pool.collect(recipient, tickLower, tickUpper, new BigNumber(amount0Requested), new BigNumber(amount1Requested), {'from': ownerAddress});
//        console.log(`=== collect after token0.balanceOf: ${await token0.balanceOf(recipient)}, token1.balanceOf: ${await token1.balanceOf(recipient)} ===`);
        await callback();
    }

    async function swap(ownerAddress, poolAddress, amount0, amount1) {
        let zeroForOne = true;
        let amountSpecified = amount0;
        let swapTokenAddress = token0Address;
        let swapToken = token0;
        let forToken = token1;
        if (amount0 < 0) {
            zeroForOne = false;
            amountSpecified = amount1;
            swapTokenAddress = token1Address;
            swapToken = token1;
            forToken = token0;
        }

        await topUpAmount(swapTokenAddress, new BigNumber(amountSpecified).multipliedBy(10), ownerAddress);
        await topUp.sendEthers(ownerAddress);
        const callback = await topUp.impersonates([ownerAddress]);
        await swapToken.approve(mockUniswapV3Router.address, new BigNumber(0), {'from': ownerAddress});
        await swapToken.approve(mockUniswapV3Router.address, new BigNumber(amountSpecified).multipliedBy(10), {'from': ownerAddress});
//        console.log(`=== swap before swapToken.balanceOf: ${await swapToken.balanceOf(ownerAddress)}, forToken.balanceOf: ${await forToken.balanceOf(ownerAddress)} ===`);
        await mockUniswapV3Router.swap(poolAddress, zeroForOne, new BigNumber(amountSpecified), {'from': ownerAddress});
//        console.log(`=== swap after swapToken.balanceOf: ${await swapToken.balanceOf(ownerAddress)}, forToken.balanceOf: ${await forToken.balanceOf(ownerAddress)} ===`);
        await callback();
    }

    async function strategyInvest() {
        const investAmount0 = 1;
        const investAmount1 = 10000;

        // top up
        await topUpAmount(token0Address, new BigNumber(investAmount0).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), investor);
        await topUpAmount(token1Address, new BigNumber(investAmount1).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token1Decimals)), investor);

        // approve
        await token0.approve(vaultAddress, new BigNumber(investAmount0).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), {"from": investor});
        await token0.approve(vaultBufferAddress, new BigNumber(investAmount0).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), {"from": investor});
        await token1.approve(vaultAddress, new BigNumber(investAmount1).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token1Decimals)), {"from": investor});
        await token1.approve(vaultBufferAddress, new BigNumber(investAmount1).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token1Decimals)), {"from": investor});

        await bocVault.mint([token0Address, token1Address], [new BigNumber(investAmount0).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), new BigNumber(investAmount1).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token1Decimals))], 0, {'from': investor});

        // transfer cash from vault buffer to vault
        await bocVault.startAdjustPosition();
        await bocVault.endAdjustPosition();

        const wantsInfo = await uniswapV3Strategy.getWantsInfo();
        let initialRatio = wantsInfo._ratios[0];
        let exchangeTokens = [];
        for (let i = 0; i < wantsInfo._assets.length; i++) {
            const asset = wantsInfo._assets[i];
            const assetContract = await ERC20.at(asset);
            let amount;
            if (i !== 0) {
                amount = new BigNumber(investAmount0).multipliedBy(new BigNumber(10 ** token0Decimals)).multipliedBy(wantsInfo._ratios[i]).dividedBy(initialRatio).toFixed(0);
            } else {
                amount = new BigNumber(investAmount0).multipliedBy(new BigNumber(10 ** (await assetContract.decimals()))).toFixed();
            }
            exchangeTokens.push({
                fromToken: asset,
                toToken: asset,
                fromAmount: amount,
                exchangeParam: {
                    platform: '0x0000000000000000000000000000000000000000',
                    method: 0,
                    encodeExchangeArgs: '0x',
                    slippage: 0,
                    oracleAdditionalSlippage: 0,
                }
            });
        }

        console.log('exchangeTokens===========', exchangeTokens);
        console.log('exchangeTokens===========%d, %d', await token0.balanceOf(vaultAddress), await token1.balanceOf(vaultAddress));
        console.log(`=== strategyInvest before uniswapV3Strategy.getPositionDetail: ${JSON.stringify(await uniswapV3Strategy.getPositionDetail())} ===`);
        await bocVault.lend(strategyAddress, exchangeTokens);
        console.log(`=== strategyInvest after uniswapV3Strategy.getPositionDetail: ${JSON.stringify(await uniswapV3Strategy.getPositionDetail())} ===`);
    }

    async function strategyHarvest() {
        console.log(`=== strategyHarvest before token0.balanceOf: ${await token0.balanceOf(strategyAddress)}, token1.balanceOf: ${await token1.balanceOf(strategyAddress)} ===`);
        await uniswapV3Strategy.harvest();
        console.log(`=== strategyHarvest after token0.balanceOf: ${await token0.balanceOf(strategyAddress)}, token1.balanceOf: ${await token1.balanceOf(strategyAddress)} ===`);
    }

    async function strategyRebalance() {
        const slot0 = await uniswapV3Pool.slot0();
        console.log(`=== rebalance slot0.tick: ${slot0.tick} ===`);
        const shouldRebalance = await uniswapV3Strategy.shouldRebalance(slot0.tick);
        if (shouldRebalance) {
            console.log(`=== rebalanceByKeeper before uniswapV3Strategy.getMintInfo: ${JSON.stringify(await uniswapV3Strategy.getMintInfo())} ===`);
            await uniswapV3Strategy.rebalanceByKeeper({'from': keeper});
            console.log(`=== rebalanceByKeeper after uniswapV3Strategy.getMintInfo: ${JSON.stringify(await uniswapV3Strategy.getMintInfo())} ===`);
        }
    }

    async function topUpAmount(tokenAddress, tokenAmount, investor) {
        let token;
        let tokenDecimals;
        switch (tokenAddress) {
            case address.USDT_ADDRESS:
//                console.log('top up USDT');
                token = await ERC20.at(address.USDT_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpUsdtByAddress(tokenAmount, investor);
                break;
            case address.USDC_ADDRESS:
//                console.log('top up USDC');
                token = await ERC20.at(address.USDC_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpUsdcByAddress(tokenAmount, investor);
                break;
            case address.DAI_ADDRESS:
//                console.log('top up DAI');
                token = await ERC20.at(address.DAI_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpDaiByAddress(tokenAmount, investor);
                break;
            case address.BUSD_ADDRESS:
//                console.log('top up BUSD');
                token = await ERC20.at(address.BUSD_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.impersonates([address.BUSD_WHALE_ADDRESS]);
                await topUp.topUpMain(address.BUSD_ADDRESS, address.BUSD_WHALE_ADDRESS, investor, tokenAmount);
                break;
            case address.TUSD_ADDRESS:
//                console.log('top up TUSD');
                token = await ERC20.at(address.TUSD_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpTusdByAddress(tokenAmount, investor);
                break;
            case address.USDP_ADDRESS:
//                console.log('top up USDP');
                token = await ERC20.at(address.USDP_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.impersonates([address.USDP_WHALE_ADDRESS]);
                await topUp.topUpMain(
                    address.USDP_ADDRESS,
                    address.USDP_WHALE_ADDRESS,
                    investor,
                    tokenAmount
                );
                break;
            case address.GUSD_ADDRESS:
//                console.log('top up GUSD');
                token = await ERC20.at(address.GUSD_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.impersonates([address.GUSD_WHALE_ADDRESS]);
                await topUp.topUpMain(
                    address.GUSD_ADDRESS,
                    address.GUSD_WHALE_ADDRESS,
                    investor,
                    tokenAmount
                );
                break;
            case address.WETH_ADDRESS:
//                console.log('top up WETH');
                token = await ERC20.at(address.WETH_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpWETHByAddress(tokenAmount, investor);
                break;
            case address.rocketPoolETH_ADDRESS:
//                console.log('top up rocketPoolETH');
                token = await ERC20.at(address.rocketPoolETH_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpRocketPoolEthByAddress(tokenAmount, investor);
                break;
            case address.sETH2_ADDRESS:
//                console.log('top up sETH2');
                token = await ERC20.at(address.sETH2_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpSEth2ByAddress(tokenAmount, investor);
                break;
            case address.rETH2_ADDRESS:
//                console.log('top up rETH2');
                token = await ERC20.at(address.rETH2_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpREth2ByAddress(tokenAmount, investor);
                break;
            default:
                throw new Error('Unsupported token!');
        }
//        console.log('topUp finish!!!');
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
