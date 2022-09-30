const axios = require("axios");
const lodash = require("lodash");
const moment = require("moment");
const { default: BigNumber } = require("bignumber.js");

const ERC20 = hre.artifacts.require("@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20");
const UniswapV3Pool = hre.artifacts.require("@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol");
const IVault = hre.artifacts.require("boc-contract-core/contracts/vault/IVault.sol:IVault");
const IETHVault = hre.artifacts.require("IETHVault");
const UniswapV3Strategy = hre.artifacts.require("UniswapV3Strategy");
const ETHUniswapV3Strategy = hre.artifacts.require("ETHUniswapV3Strategy");
const MockUniswapV3Router = hre.artifacts.require("MockUniswapV3Router");
const MockAavePriceOracleConsumer = hre.artifacts.require('MockAavePriceOracleConsumer');
const ILendingPoolAddressesProvider = hre.artifacts.require('ILendingPoolAddressesProvider');

const address = require("./../config/address-config");
const topUp = require("./../utils/top-up-utils");
const { advanceBlock } = require("./../utils/block-utils");

const main = async () => {
    // init
    const dateBlockNumbers = [13724084, 13730329, 13736623, 13742801, 13749028, 13755301, 13761567, 13767793, 13774074, 13780502, 13786990, 13793512, 13799999, 13806390, 13812868, 13819265, 13825732, 13832240, 13838693, 13845239, 13851681, 13858106, 13864522, 13870990, 13877450, 13883917, 13890393, 13896836, 13903355, 13909787, 13916166, 13922671, 13929167, 13935628, 13942121, 13948582, 13954973, 13961397, 13967922, 13974426, 13980848];
    const accounts = await ethers.getSigners();
    const investor = accounts[0].address;
    const keeper = accounts[19].address;

    const usdi = false;
    const poolAddress = "0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640";
    const strategyAddress = "0xCA8c8688914e0F7096c920146cd0Ad85cD7Ae8b9";
    const vaultAddress = "0x457cCf29090fe5A24c19c1bc95F492168C0EaFdb";
    const vaultBufferAddress = "0xF32D39ff9f6Aa7a7A64d7a4F00a54826Ef791a55";

    const uniswapV3Pool = await UniswapV3Pool.at(poolAddress);
    const uniswapV3Strategy = usdi ? (await UniswapV3Strategy.at(strategyAddress)) : (await ETHUniswapV3Strategy.at(strategyAddress));
    const bocVault = usdi ? (await IVault.at(vaultAddress)) : (await IETHVault.at(vaultAddress));
    const mockUniswapV3Router = await MockUniswapV3Router.new();

    const token0Address = await uniswapV3Pool.token0();
    const token1Address = await uniswapV3Pool.token1();
    const token0 = await ERC20.at(token0Address);
    const token1 = await ERC20.at(token1Address);

    const token0Decimals = await token0.decimals();
    const token1Decimals = await token1.decimals();

    await uniswapV3Pool.increaseObservationCardinalityNext(360);
    await bocVault.setStrategySetLimitRatio(strategyAddress, 1000000, 1000000, { "from": investor });
    const strategies = await bocVault.strategies(strategyAddress);
    console.log("=== strategies: %s ===", JSON.stringify(strategies));

    const addressProvider = await ILendingPoolAddressesProvider.at('0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5');

    const originPriceOracleConsumer = await MockAavePriceOracleConsumer.at(await addressProvider.getPriceOracle());
    console.log('USDC price0:%s',await originPriceOracleConsumer.getAssetPrice('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'));

    // invest
    await strategyInvest();

    // topUp & approve
    await topUpAmount(token0Address, new BigNumber(10).pow(12).multipliedBy(new BigNumber(10).pow(token0Decimals)), investor);
    await token0.approve(mockUniswapV3Router.address, new BigNumber(0), { "from": investor });
    await token0.approve(mockUniswapV3Router.address, new BigNumber(10).pow(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), { "from": investor });
    await topUpAmount(token1Address, new BigNumber(10).pow(12).multipliedBy(new BigNumber(10).pow(token1Decimals)), investor);
    await token1.approve(mockUniswapV3Router.address, new BigNumber(0), { "from": investor });
    await token1.approve(mockUniswapV3Router.address, new BigNumber(10).pow(10).multipliedBy(new BigNumber(10).pow(token1Decimals)), { "from": investor });

    // start data back to test
    let count = 0;
    for (let i = 0; i < dateBlockNumbers.length; i++) {
        await eventsTracing(dateBlockNumbers[i], dateBlockNumbers[i + 1]);
        console.log(`=== blockNumberStart: ${dateBlockNumbers[i]}, blockNumberEnd: ${dateBlockNumbers[i + 1]} eventsTracing end ===`);
        await advanceBlock(1);
        console.log("======== getBlockNumber: %d ========", await ethers.provider.getBlockNumber());
        let positionDetail = await uniswapV3Strategy.getPositionDetail();
        console.log("=== strategyHarvest before strategy.getPositionDetail.token0: %d, strategy.getPositionDetail.token1: %d ===", positionDetail._amounts[0], positionDetail._amounts[1]);
        await strategyHarvest();
        positionDetail = await uniswapV3Strategy.getPositionDetail();
        console.log("=== strategyHarvest after strategy.getPositionDetail.token0: %d, strategy.getPositionDetail.token1: %d ===", positionDetail._amounts[0], positionDetail._amounts[1]);
        const twap = await uniswapV3Strategy.getTwap();

        await originPriceOracleConsumer.setAssetPrice('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', new BigNumber(Math.pow(1.0001, twap) * 1e6).toFixed(0,1));
        await strategyBorrowRebalance();
        await strategyRebalance();
        positionDetail = await uniswapV3Strategy.getPositionDetail();
        console.log("=== strategyRebalance after strategy.getPositionDetail.token0: %d, strategy.getPositionDetail.token1: %d ===", positionDetail._amounts[0], positionDetail._amounts[1]);
        console.log("======== getBlockNumber: %d ========", await ethers.provider.getBlockNumber());
    }

    async function eventsTracing(blockNumberStart, blockNumberEnd) {
        // get events
        const eventsRes = await axios.get(`http://192.168.75.35:8081/event_log?chain_id=1&offset=0&limit=1000000&block_number_start=${blockNumberStart}&block_number_end=${blockNumberEnd}&event_name=Swap,Mint,Burn,Collect`);
        const events = eventsRes.data.records;
        if (lodash.isEmpty(events)) {
            return;
        }

        let swapEventDatas = [];
        for (let i = 0; i < events.length; i++) {
//            console.log('=== blockNumber: ===', events[i].blockNumber);
            const eventData = events[i].data;
            try {
                switch (events[i].eventName) {
                    case "Swap":
                        swapEventDatas.push(eventData);
                        break;
                    case "Mint":
                        if (swapEventDatas.length > 0) {
                            await batchSwapRetry(swapEventDatas);
                            swapEventDatas = [];
                        }
                        await mintRetry(eventData.owner, eventData.tickLower, eventData.tickUpper, new BigNumber(eventData.amount0), new BigNumber(eventData.amount1), new BigNumber(eventData.amount));
                        break;
                    case "Burn":
                        if (swapEventDatas.length > 0) {
                            await batchSwapRetry(swapEventDatas);
                            swapEventDatas = [];
                        }
                        await burnRetry(eventData.owner, eventData.tickLower, eventData.tickUpper, new BigNumber(eventData.amount), new BigNumber(eventData.amount0), new BigNumber(eventData.amount1));
                        break;
                    case "Collect":
                        if (swapEventDatas.length > 0) {
                            await batchSwapRetry(swapEventDatas);
                            swapEventDatas = [];
                        }
                        await collectRetry(eventData.owner, eventData.tickLower, eventData.tickUpper, new BigNumber(eventData.amount0), new BigNumber(eventData.amount1), eventData.recipient);
                        break;
                    default:
                        throw new Error("Unsupported product!");
                }
            } catch (e) {
                console.log("=== switch case error: ===", e);
            }
        }
        if (swapEventDatas.length > 0) {
            await batchSwapRetry(swapEventDatas);
        }
    }

    console.log(`=== while end count: ${count} ===`);

    // end data back to test

    async function mintRetry(ownerAddress, tickLower, tickUpper, amount0, amount1, amount) {
        let count = 0;
        while (true) {
            try {
                await mint(ownerAddress, tickLower, tickUpper, amount0, amount1, amount);
                return;
            } catch (e) {
                count++;
                console.log(`=== mintRetry count: ${count}, ownerAddress: ${ownerAddress}, tickLower: ${tickLower}, tickUpper: ${tickUpper}, amount0: ${amount0}, amount1: ${amount1}, amount: ${amount} ===`);
                console.log("=== mintRetry error: ===", e);
                if (count > 3) {
                    return;
                }
            }
        }
    }

    async function mint(ownerAddress, tickLower, tickUpper, amount0, amount1, amount) {
        if (amount0.gt(0)) {
            await topUpAmount(token0Address, amount0.multipliedBy(10), ownerAddress);
        }
        if (amount1.gt(0)) {
            await topUpAmount(token1Address, amount1.multipliedBy(10), ownerAddress);
        }

        await topUp.sendEthers(ownerAddress);
        const callback = await topUp.impersonates([ownerAddress]);
        await token0.approve(mockUniswapV3Router.address, new BigNumber(0), { "from": ownerAddress });
        await token0.approve(mockUniswapV3Router.address, amount0.multipliedBy(10), { "from": ownerAddress });
        await token1.approve(mockUniswapV3Router.address, new BigNumber(0), { "from": ownerAddress });
        await token1.approve(mockUniswapV3Router.address, amount1.multipliedBy(10), { "from": ownerAddress });
        console.log(`=== mint before amount0: ${amount0}, amount1: ${amount1} ===`);
        console.log(`=== mint before token0.balanceOf: ${await token0.balanceOf(ownerAddress)}, token1.balanceOf: ${await token1.balanceOf(ownerAddress)} ===`);
        await mockUniswapV3Router.mint(poolAddress, tickLower, tickUpper, amount, { "from": ownerAddress });
        console.log(`=== mint after token0.balanceOf: ${await token0.balanceOf(ownerAddress)}, token1.balanceOf: ${await token1.balanceOf(ownerAddress)} ===`);
        await callback();
    }

    async function burnRetry(ownerAddress, tickLower, tickUpper, amount, amount0, amount1) {
        let count = 0;
        while (true) {
            try {
                await burn(ownerAddress, tickLower, tickUpper, amount, amount0, amount1);
                return;
            } catch (e) {
                count++;
                console.log(`=== burnRetry count: ${count}, ownerAddress: ${ownerAddress}, tickLower: ${tickLower}, tickUpper: ${tickUpper}, amount0: ${amount0}, amount1: ${amount1}, amount: ${amount} ===`);
                console.log("=== burnRetry error: ===", e);
                if (count > 3) {
                    return;
                }
            }
        }
    }

    async function burn(ownerAddress, tickLower, tickUpper, amount, amount0, amount1) {
        await topUp.sendEthers(ownerAddress);
        const callback = await topUp.impersonates([ownerAddress]);
        const liquidity = await uniswapV3Strategy.getLiquidityForAmounts(tickLower, tickUpper, amount0, amount1);
        if (new BigNumber(liquidity).lt(amount)) {
//            console.log('=== burn before uniswapV3Strategy.getLiquidityForAmounts: %d, amount: %d ===', liquidity, amount);
            amount = liquidity;
        }
//        console.log(`=== burn before uniswapV3Pool.liquidity: ${await uniswapV3Pool.liquidity()},  uniswapV3Pool.slot0: ${JSON.stringify(await uniswapV3Pool.slot0())} ===`);
        await uniswapV3Pool.burn(tickLower, tickUpper, amount, { "from": ownerAddress });
//        console.log(`=== burn after uniswapV3Pool.liquidity: ${await uniswapV3Pool.liquidity()},  uniswapV3Pool.slot0: ${JSON.stringify(await uniswapV3Pool.slot0())} ===`);
        await callback();
    }

    async function collectRetry(ownerAddress, tickLower, tickUpper, amount0Requested, amount1Requested, recipient) {
        let count = 0;
        while (true) {
            try {
                await collect(ownerAddress, tickLower, tickUpper, amount0Requested, amount1Requested, recipient);
                return;
            } catch (e) {
                count++;
                console.log(`=== collectRetry count: ${count}, ownerAddress: ${ownerAddress}, tickLower: ${tickLower}, tickUpper: ${tickUpper}, amount0Requested: ${amount0Requested}, amount1Requested: ${amount1Requested}, recipient: ${recipient} ===`);
                console.log("=== collectRetry error: ===", e);
                if (count > 3) {
                    return;
                }
            }
        }
    }

    async function collect(ownerAddress, tickLower, tickUpper, amount0Requested, amount1Requested, recipient) {
        await topUp.sendEthers(ownerAddress);
        const callback = await topUp.impersonates([ownerAddress]);
//        console.log(`=== collect before token0.balanceOf: ${await token0.balanceOf(recipient)}, token1.balanceOf: ${await token1.balanceOf(recipient)} ===`);
        await uniswapV3Pool.collect(recipient, tickLower, tickUpper, amount0Requested, amount1Requested, { "from": ownerAddress });
//        console.log(`=== collect after token0.balanceOf: ${await token0.balanceOf(recipient)}, token1.balanceOf: ${await token1.balanceOf(recipient)} ===`);
        await callback();
    }

    async function batchSwapRetry(swapEventDatas) {
        let count = 0;
        while (true) {
            try {
                await batchSwap(swapEventDatas);
                return;
            } catch (e) {
                count++;
                console.log(`=== batchSwapRetry count: ${count}, swapEventDatas: ${swapEventDatas} ===`);
                console.log("=== batchSwapRetry error: ===", e);
                if (count > 3) {
                    return;
                }
            }
        }
    }

    async function batchSwap(swapEventDatas) {
        let multicallFuns = [];
        for (const swapEvent of swapEventDatas) {
            let amount0 = new BigNumber(swapEvent.amount0);
            let amount1 = new BigNumber(swapEvent.amount1);

            let zeroForOne = true;
            let amountSpecified = amount0;
            if (amount0.lt(0)) {
                zeroForOne = false;
                amountSpecified = amount1;
            }

            multicallFuns.push(mockUniswapV3Router.contract.methods.swap(poolAddress, zeroForOne, amountSpecified).encodeABI());
        }
        console.log(`=== swap before swapEventDatas.length: ${swapEventDatas.length} ===`);
//        console.log(`=== swap before token0.balanceOf: ${await token0.balanceOf(investor)}, token1.balanceOf: ${await token1.balanceOf(investor)} ===`);
        await mockUniswapV3Router.multicall(multicallFuns, { "from": investor });
//        console.log(`=== swap after token0.balanceOf: ${await token0.balanceOf(investor)}, token1.balanceOf: ${await token1.balanceOf(investor)} ===`);
        const slot0 = await uniswapV3Pool.slot0();
        console.log(`=== swap after slot0.tick: ${slot0.tick}, swapEventDatas.amount0: ${new BigNumber(swapEventDatas[swapEventDatas.length - 1].amount0).toFixed()}, swapEventDatas.amount1: ${new BigNumber(swapEventDatas[swapEventDatas.length - 1].amount1).toFixed()} ===`);
    }

    async function strategyInvest() {
        const investAmount0 = 10;
        const investAmount1 = 10;

        // top up
        await topUpAmount(token0Address, new BigNumber(investAmount0).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), investor);
        await topUpAmount(token1Address, new BigNumber(investAmount1).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token1Decimals)), investor);

        // approve
        await token0.approve(vaultAddress, new BigNumber(0), { "from": investor });
        await token0.approve(vaultAddress, new BigNumber(investAmount0).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), { "from": investor });
        await token0.approve(vaultBufferAddress, new BigNumber(0), { "from": investor });
        await token0.approve(vaultBufferAddress, new BigNumber(investAmount0).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), { "from": investor });
        await token1.approve(vaultAddress, new BigNumber(0), { "from": investor });
        await token1.approve(vaultAddress, new BigNumber(investAmount1).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token1Decimals)), { "from": investor });
        await token1.approve(vaultBufferAddress, new BigNumber(0), { "from": investor });
        await token1.approve(vaultBufferAddress, new BigNumber(investAmount1).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token1Decimals)), { "from": investor });

        if (usdi) {
            await bocVault.mint([token0Address, token1Address], [new BigNumber(investAmount0).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), new BigNumber(investAmount1).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token1Decimals))], 0, { "from": investor });
        } else {
            await bocVault.mint(token0Address, new BigNumber(investAmount0).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token0Decimals)), 0, { "from": investor });
            await bocVault.mint(token1Address, new BigNumber(investAmount1).multipliedBy(10).multipliedBy(new BigNumber(10).pow(token1Decimals)), 0, { "from": investor });
        }

        // transfer cash from vault buffer to vault
        await bocVault.startAdjustPosition();
        await bocVault.endAdjustPosition();

        const wantsInfo = await uniswapV3Strategy.getWantsInfo();
        let initialRatio = wantsInfo._ratios[1];
        let exchangeTokens = [];
        for (let i = 0; i < wantsInfo._assets.length; i++) {
            const asset = wantsInfo._assets[i];
            const assetContract = await ERC20.at(asset);
            let amount = new BigNumber(1).multipliedBy(new BigNumber(10 ** token1Decimals)).toFixed();
//            if (i !== 0) {
//                amount = new BigNumber(investAmount1).multipliedBy(new BigNumber(10 ** (usdi ? (token1Decimals) : (token1Decimals - 7)))).toFixed();
//            } else {
//                amount = new BigNumber(investAmount1).multipliedBy(new BigNumber(10 ** (usdi ? (token1Decimals) : (token1Decimals - 7)))).multipliedBy(wantsInfo._ratios[i]).dividedBy(initialRatio).toFixed(0);
//            }
            exchangeTokens.push({
                fromToken: asset,
                toToken: asset,
                fromAmount: amount,
                exchangeParam: {
                    platform: "0x0000000000000000000000000000000000000000",
                    method: 0,
                    encodeExchangeArgs: "0x",
                    slippage: 0,
                    oracleAdditionalSlippage: 0,
                },
            });
        }
        console.log("=== wantsInfo._ratios[0]: %d, wantsInfo._ratios[1]: %d ===", wantsInfo._ratios[0], wantsInfo._ratios[1]);
        console.log("=== exchangeTokens: ===", exchangeTokens);
        console.log("=== exchangeTokens token0.balanceOf(vault): %d, token1.balanceOf(vault): %d ===", await token0.balanceOf(vaultAddress), await token1.balanceOf(vaultAddress));
        let investPositionDetail = await uniswapV3Strategy.getPositionDetail();
        console.log("=== strategyInvest before strategy.getPositionDetail.token0: %d, strategy.getPositionDetail.token1: %d ===", investPositionDetail._amounts[0], investPositionDetail._amounts[1]);
        await bocVault.lend(strategyAddress, exchangeTokens);
        investPositionDetail = await uniswapV3Strategy.getPositionDetail();
        console.log("=== strategyInvest after strategy.getPositionDetail.token0: %d, strategy.getPositionDetail.token1: %d ===", investPositionDetail._amounts[0], investPositionDetail._amounts[1]);
    }

    async function strategyHarvest() {
        console.log(`=== strategyHarvest before token0.balanceOf: ${await token0.balanceOf(strategyAddress)}, token1.balanceOf: ${await token1.balanceOf(strategyAddress)} ===`);
        await uniswapV3Strategy.harvest();
        console.log(`=== strategyHarvest after token0.balanceOf: ${await token0.balanceOf(strategyAddress)}, token1.balanceOf: ${await token1.balanceOf(strategyAddress)} ===`);
    }

    async function strategyBorrowRebalance() {
        console.log(`=== strategyBorrowRebalance before token0.balanceOf: ${await token0.balanceOf(strategyAddress)}, token1.balanceOf: ${await token1.balanceOf(strategyAddress)} ===`);
        await uniswapV3Strategy.strategyBorrowRebalance();
        console.log(`=== strategyBorrowRebalance after token0.balanceOf: ${await token0.balanceOf(strategyAddress)}, token1.balanceOf: ${await token1.balanceOf(strategyAddress)} ===`);
    }

    async function strategyRebalance() {
        const slot0 = await uniswapV3Pool.slot0();
        console.log(`=== rebalance slot0.tick: ${slot0.tick} ===`);
        const currentTick = slot0.tick;
        const shouldRebalance = await uniswapV3Strategy.shouldRebalance(currentTick);
        if (shouldRebalance) {
//            let allowedOffset = 0;
//            const tickSpacing = await uniswapV3Pool.tickSpacing();
//            switch (+tickSpacing) {
//                case 1:
//                    allowedOffset = 2;
//                    break;
//                case 10:
//                    allowedOffset = 2;
//                    break;
//                case 60:
//                    allowedOffset = 10;
//                    break;
//                default:
//                    console.log(`UniswapV3RebalanceTask tickSpacing: ${tickSpacing} error`);
//            }
//
//            const mintInfo = await uniswapV3Strategy.getMintInfo();
//            const baseTokenId = mintInfo.baseTokenId;
//            const baseTickUpper = mintInfo.baseTickUpper;
//            const baseTickLower = mintInfo.baseTickLower;
//            if (baseTokenId !== 0) {
//                if (+currentTick <= +baseTickUpper + +allowedOffset && +currentTick >= +baseTickLower - +allowedOffset) {
//                    console.log(`=== UniswapV3RebalanceTask currentTick not in excess of allowedOffset, no execute rebalance ===`);
//                    return;
//                }
//            }
            console.log(`=== rebalanceByKeeper before uniswapV3Strategy.getMintInfo: ${JSON.stringify(await uniswapV3Strategy.getMintInfo())} ===`);
            await uniswapV3Strategy.rebalanceByKeeper({ "from": keeper });
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
                    tokenAmount,
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
                    tokenAmount,
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
                throw new Error("Unsupported token!");
        }
//        console.log('topUp finish!!!');
    }
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
