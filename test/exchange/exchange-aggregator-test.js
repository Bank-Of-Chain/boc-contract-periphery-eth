const { expectEvent,
    expectRevert,
    BN } = require('@openzeppelin/test-helpers');
const MFC = require("../../config/mainnet-fork-test-config")
const { getBestSwapInfo } = require("piggy-finance-utils");
const { ethers } = require('hardhat');
const { inTransaction } = require('@openzeppelin/test-helpers/src/expectEvent');
const {topUpUsdtByAddress, topUpUsdcByAddress, topUpDaiByAddress, topUpBusdByAddress, topUpLusdByAddress,
    topUpUsdpByAddress, topUpSusdByAddress, topUpTusdByAddress, topUpGusdByAddress, topUpEthByAddress,
    topUpRocketPoolEthByAddress, topUpSEthByAddress, topUpWETHByAddress, topUpWstEthByAddress, topUpREth2ByAddress,
    topUpSEth2ByAddress, topUpSTETHByAddress
} = require("../../utils/top-up-utils");
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const AccessControlProxy = artifacts.require('AccessControlProxy')
const ExchangeAggregator = artifacts.require('ExchangeAggregator')
const OneInchV4Adapter = artifacts.require('OneInchV4Adapter')
const ParaSwapV5Adapter = artifacts.require('ParaSwapV5Adapter')
const NativeToken = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const{BigNumber} =ethers;

const EXCHANGE_PLATFORMS = {
    oneInchV4: {
        network: 1,
        useHttp: true,
        // protocols: ['PMM1','PMM2','PMM3','PMM4','UNISWAP_V1','UNISWAP_V2','UNISWAP_V3'],
        // excludeProtocols: ['ONE_INCH_LIMIT_ORDER', 'ONE_INCH_LIMIT_ORDER_V2','PMM1','PMM2','PMM3','PMM4','UNISWAP_V1','UNISWAP_V2','UNISWAP_V3']
        excludeProtocols: ['ONE_INCH_LIMIT_ORDER', 'ONE_INCH_LIMIT_ORDER_V2','ZEROX_LIMIT_ORDER','PMM1','PMM2','PMM3','PMM4'],
    },
    paraswap: {
        network: 1,
        excludeContractMethods: ['swapOnZeroXv2','swapOnZeroXv4'],
        excludeDEXS: 'acryptos',
        includeDEXS: 'Uniswap,Kyber,Bancor,Oasis,Compound,Fulcrum,0x,MakerDAO,Chai,Aave,Aave2,MultiPath,MegaPath,Curve,Curve3,Saddle,IronV2,BDai,idle,Weth,Beth,UniswapV2,Balancer,0xRFQt,SushiSwap,LINKSWAP,Synthetix,DefiSwap,Swerve,CoFiX,Shell,DODOV1,DODOV2,OnChainPricing,PancakeSwap,PancakeSwapV2,ApeSwap,Wbnb,streetswap,bakeryswap,julswap,vswap,vpegswap,beltfi,ellipsis,QuickSwap,COMETH,Wmatic,Nerve,Dfyn,UniswapV3,Smoothy,PantherSwap,OMM1,OneInchLP,CurveV2,mStable,WaultFinance,MDEX,ShibaSwap,CoinSwap,SakeSwap,JetSwap,Biswap,BProtocol'
    }
}

const getExchangePlatformAdapters = async exchangeAggregator => {
    const adapters = await exchangeAggregator.getExchangeAdapters()
    const exchangePlatformAdapters = {}
    for (let i = 0; i < adapters._identifiers.length; i++) {
        exchangePlatformAdapters[adapters._identifiers[i]] = adapters._exchangeAdapters[i]
    }
    return exchangePlatformAdapters
}

async function getTokenDetail(tokenAddr) {
    if (tokenAddr == NativeToken) {
        return { address: tokenAddr, symbol: 'ETH', decimals: 18 }
    }
    const token = await ERC20.at(tokenAddr);
    return { address: tokenAddr, symbol: await token.symbol(), decimals: Number(await token.decimals()) }
}

async function balanceOfToken(account, tokenAddr) {
    if (tokenAddr == NativeToken) {
        return BigNumber.from(BigInt(await ethers.provider.getBalance(account)));
    }
    const token = await ERC20.at(tokenAddr);
    return BigNumber.from((await token.balanceOf(account)).toString());
}

describe('ExchangeAggregator test.', function () {
    let governance;
    let keeper;
    let vault;
    let farmer1
    let exchangeAggregator;
    let ethiAmount = BigNumber.from(100000);
    let usdiAmount = BigNumber.from(100000);
    let snapshotId;

    let ethiTokenList = [
        MFC.ETH_ADDRESS,
        MFC.rocketPoolETH_ADDRESS,
        MFC.stETH_ADDRESS,
        MFC.WETH_ADDRESS,
        MFC.wstETH_ADDRESS,
        // MFC.rETH2_ADDRESS,
        // MFC.sETH2_ADDRESS,
    ];

    let usdiTokenList = [
        MFC.USDT_ADDRESS,
        MFC.USDC_ADDRESS,
        MFC.DAI_ADDRESS,
        MFC.BUSD_ADDRESS,
        MFC.LUSD_ADDRESS,
        MFC.USDP_ADDRESS,
        MFC.SUSD_ADDRESS,
        MFC.TUSD_ADDRESS,
        MFC.GUSD_ADDRESS,
    ];

    async function swap(srcTokenAddr, dstTokenAddr, srcAmount = BigNumber.from(10).pow(18).toString()) {
        let platformAdapter = {
            paraswap: exchangePlatformAdapters.paraswap,
            oneInchV4: exchangePlatformAdapters.oneInchV4
        };
        const srcTokenDetail = await getTokenDetail(srcTokenAddr);
        const dstTokenDetail = await getTokenDetail(dstTokenAddr);
        // if (srcTokenAddr != NativeToken){
        //     srcAmount = BigNumber.from('99623559194942650').toString();
        // }

        // console.log('getBestSwapInfo## from:%s to:%s,amount:%s,balance:%s',srcTokenDetail.symbol,dstTokenDetail.symbol,srcAmount, (await balanceOfToken(farmer1,srcTokenAddr)));
        const SWAP_INFO = await getBestSwapInfo(srcTokenDetail,
            dstTokenDetail, srcAmount, 500, 500, platformAdapter, EXCHANGE_PLATFORMS);

        if (typeof(SWAP_INFO) == 'undefined'){
            throw Error('getBestSwapInfo error');
        }
        const swapDesc = {
            amount: srcAmount,
            srcToken: srcTokenDetail.address,
            dstToken: dstTokenDetail.address,
            receiver: farmer1
        };
        let tx;
        let dstTokenBalanceBeforeSwap = BigNumber.from((await balanceOfToken(farmer1,dstTokenAddr)).toString());
        // if(dstTokenAddr == MFC.stETH_ADDRESS){
        //     dstTokenBalanceBeforeSwap = dstTokenBalanceBeforeSwap.sub(1);
        // }

        let gasUsed = BigNumber.from(0);
        console.log('start exchange aggregator swap');
        if (srcTokenAddr == NativeToken) {
            tx = await exchangeAggregator.swap(SWAP_INFO.platform, SWAP_INFO.method, SWAP_INFO.encodeExchangeArgs, swapDesc, { from: farmer1, value: srcAmount});
        } else {
            const token = await ERC20.at(swapDesc.srcToken);
            await token.approve(exchangeAggregator.address, 0, { from: farmer1 });
            await token.approve(exchangeAggregator.address, srcAmount, { from: farmer1 });
            // console.log(SWAP_INFO.platform, SWAP_INFO.method, SWAP_INFO.encodeExchangeArgs, swapDesc);
            tx = await exchangeAggregator.swap(SWAP_INFO.platform, SWAP_INFO.method, SWAP_INFO.encodeExchangeArgs, swapDesc, { from: farmer1,gasPrice:10* (10**9) });
            if (dstTokenAddr == NativeToken){
                gasUsed = BigNumber.from(tx.receipt.gasUsed.toString()).mul(BigNumber.from(tx.receipt.effectiveGasPrice.toString()));
                // console.log('tx',tx);
                console.log('gasUsed',gasUsed.toString());
                gasUsed = 0;
            }
        }
        // console.log('tx',tx);
        console.log('end exchange aggregator swap');

        expectEvent(tx, 'Swap', {
            _platform: SWAP_INFO.platform,
            _amount: srcAmount,
            _srcToken: swapDesc.srcToken,
            _dstToken: swapDesc.dstToken,
            _exchangeAmount: BigNumber.from((await balanceOfToken(farmer1, swapDesc.dstToken)).toString()).sub(dstTokenBalanceBeforeSwap).add(gasUsed).toString(),
            _receiver: farmer1,
            _sender: farmer1,
        });
    }


    before('INIT', async function () {
        await ethers.getSigners().then((resp) => {
            accounts = resp;
            governance = accounts[0].address;
            farmer1 = accounts[13].address;
            vault = accounts[2].address;
            keeper = accounts[19].address;
        });

        const accessControlProxy = await AccessControlProxy.new()
        accessControlProxy.initialize(governance, governance, vault, keeper)
        console.log('deploy OneInchV4Adapter');
        const oneInchV4Adapter = await OneInchV4Adapter.new();
        console.log('deploy ParaSwapV5Adapter');
        const paraSwapV5Adapter = await ParaSwapV5Adapter.new();
        console.log('deploy ExchangeAggregator');
        exchangeAggregator = await ExchangeAggregator.new([oneInchV4Adapter.address, paraSwapV5Adapter.address], accessControlProxy.address);
        exchangePlatformAdapters = await getExchangePlatformAdapters(exchangeAggregator);


        await topUpUsdtByAddress((BigNumber.from(10).pow(6-1)).mul(2).mul(usdiAmount).toString(),farmer1);
        await topUpUsdcByAddress((BigNumber.from(10).pow(6-1)).mul(2).mul(usdiAmount).toString(),farmer1);
        await topUpDaiByAddress((BigNumber.from(10).pow(18-1)).mul(2).mul(usdiAmount).toString(),farmer1);
        await topUpBusdByAddress((BigNumber.from(10).pow(18-1)).mul(2).mul(usdiAmount).toString(),farmer1);
        await topUpLusdByAddress((BigNumber.from(10).pow(18-1)).mul(2).mul(usdiAmount).toString(),farmer1);
        await topUpUsdpByAddress((BigNumber.from(10).pow(18-1)).mul(2).mul(usdiAmount).toString(),farmer1);
        await topUpSusdByAddress((BigNumber.from(10).pow(18-1)).mul(2).mul(usdiAmount).toString(),farmer1);
        await topUpTusdByAddress((BigNumber.from(10).pow(18-1)).mul(2).mul(usdiAmount).toString(),farmer1);
        await topUpGusdByAddress((BigNumber.from(10).pow(18-1)).mul(2).mul(usdiAmount).toString(),farmer1);

        await topUpEthByAddress((BigNumber.from(10).pow(18-5)).mul(2).mul(ethiAmount).toString(),farmer1);
        await topUpRocketPoolEthByAddress((BigNumber.from(10).pow(18-5)).mul(2).mul(ethiAmount).toString(),farmer1);
        await topUpSTETHByAddress((BigNumber.from(10).pow(18-5)).mul(2).mul(ethiAmount).toString(),farmer1);
        await topUpWETHByAddress((BigNumber.from(10).pow(18-5)).mul(2).mul(ethiAmount).toString(),farmer1);
        await topUpWstEthByAddress((BigNumber.from(10).pow(18-5)).mul(2).mul(ethiAmount).toString(),farmer1);
        await topUpREth2ByAddress((BigNumber.from(10).pow(18-5)).mul(2).mul(ethiAmount).toString(),farmer1);
        await topUpSEth2ByAddress((BigNumber.from(10).pow(18-5)).mul(2).mul(ethiAmount).toString(),farmer1);
        snapshotId = await hre.network.provider.send("evm_snapshot", []);
    });

    for (let i = 0; i < ethiTokenList.length; i++) {
        const srcToken = ethiTokenList[i];
        for (let j = 0; j < ethiTokenList.length-1; j++) {
            const dstToken = ethiTokenList[(j + i + 1) % ethiTokenList.length];
            it(`Case ${i},${j}: swap ${srcToken} to ${dstToken} should be success.`, async function () {
                await hre.network.provider.send("evm_revert",[snapshotId]);
                snapshotId = await hre.network.provider.send("evm_snapshot", []);
                let srcTokenSymbol = 'ETH';
                let dstTokenSymbol = 'ETH';
                if (srcToken != NativeToken){
                    const srcTokenERC = await ERC20.at(srcToken);
                    srcTokenSymbol = await srcTokenERC.symbol();
                }
                if (dstToken != NativeToken){
                    const dstTokenERC = await ERC20.at(dstToken);
                    dstTokenSymbol = await dstTokenERC.symbol();
                }

                console.log(`start ${srcTokenSymbol} to ${dstTokenSymbol}`);
                let decimals = BigNumber.from(18);
                if (srcToken != NativeToken){
                    const token = await ERC20.at(srcToken);
                    decimals = BigNumber.from((await token.decimals()).toString());
                }
                let srcAmount = ethiAmount.mul(BigNumber.from(10).pow(decimals.sub(5)));
                await swap(srcToken, dstToken, srcAmount.toString());
            });
        }
    }

    for (let i = 0; i < usdiTokenList.length; i++) {
        const srcToken = usdiTokenList[i];
        for (let j = 0; j < usdiTokenList.length-1; j++) {
            const dstToken = usdiTokenList[(j + i + 1) % usdiTokenList.length];
            it(`Case ${i},${j}: swap ${srcToken} to ${dstToken} should be success.`, async function () {
                await hre.network.provider.send("evm_revert",[snapshotId]);
                snapshotId = await hre.network.provider.send("evm_snapshot", []);
                let srcTokenSymbol = 'ETH';
                let dstTokenSymbol = 'ETH';
                if (srcToken != NativeToken){
                    const srcTokenERC = await ERC20.at(srcToken);
                    srcTokenSymbol = await srcTokenERC.symbol();
                }
                if (dstToken != NativeToken){
                    const dstTokenERC = await ERC20.at(dstToken);
                    dstTokenSymbol = await dstTokenERC.symbol();
                }

                console.log(`start ${srcTokenSymbol} to ${dstTokenSymbol}`);
                let decimals = BigNumber.from(18);
                if (srcToken != NativeToken){
                    const token = await ERC20.at(srcToken);
                    decimals = BigNumber.from((await token.decimals()).toString());
                }
                let srcAmount = usdiAmount.mul(BigNumber.from(10).pow(decimals.sub(1)));
                await swap(srcToken, dstToken, srcAmount.toString());
            });
        }
    }

    // it('rETH2 to ETH',async function(){
    //     await swap(MFC.ETH_ADDRESS, MFC.rETH2_ADDRESS,new BigNumber(100 * 1e18));
    //     await swap(MFC.rETH2_ADDRESS, MFC.ETH_ADDRESS,new BigNumber(10 * 1e18));
    // });
    //
    // it('rETH2 to rETH',async function(){
    //     await swap(MFC.rETH2_ADDRESS, MFC.rocketPoolETH_ADDRESS,new BigNumber(10 * 1e18));
    // });
    //
    // it('rETH2 to wstETH',async function(){
    //     await swap(MFC.rETH2_ADDRESS, MFC.wstETH_ADDRESS,new BigNumber(10 * 1e18));
    // });
    //
    // it('rETH2 to stETH',async function(){
    //     await swap(MFC.rETH2_ADDRESS, MFC.stETH_ADDRESS,new BigNumber(10 * 1e18));
    // });
    //
    // it('rETH2 to WETH',async function(){
    //     await swap(MFC.rETH2_ADDRESS, MFC.WETH_ADDRESS,new BigNumber(10 * 1e18));
    // });
    //
    // it('WETH to sETH2',async function(){
    //     await swap(MFC.rETH2_ADDRESS, MFC.sETH2_ADDRESS,new BigNumber(10 * 1e18));
    // });

    // it('sETH2 to ETH',async function(){
    //     await swap(MFC.ETH_ADDRESS, MFC.sETH2_ADDRESS,new BigNumber(650 * 1e18));
    //     await swap(MFC.sETH2_ADDRESS, MFC.ETH_ADDRESS,new BigNumber(100 * 1e18));
    // });

    // it('sETH2 to rETH',async function(){
    //     await swap(MFC.sETH2_ADDRESS, MFC.rocketPoolETH_ADDRESS,new BigNumber(100 * 1e18));
    // });

    // it('sETH2 to wstETH',async function(){
    //     await swap(MFC.sETH2_ADDRESS, MFC.wstETH_ADDRESS,new BigNumber(100 * 1e18));
    // });

    // it('sETH2 to stETH',async function(){
    //     await swap(MFC.sETH2_ADDRESS, MFC.stETH_ADDRESS,new BigNumber(100 * 1e18));
    // });

    // it('sETH2 to WETH',async function(){
    //     await swap(MFC.sETH2_ADDRESS, MFC.WETH_ADDRESS,new BigNumber(100 * 1e18));
    // });

    // it('sETH2 to rETH2',async function(){
    //     await swap(MFC.sETH2_ADDRESS, MFC.rETH2_ADDRESS,new BigNumber(100 * 1e18));
    // });

    // it('DAI to USDC',async function(){
    //     await swap(MFC.ETH_ADDRESS, MFC.DAI_ADDRESS,new BigNumber(1 * 1e18));
    //     await swap(MFC.DAI_ADDRESS, MFC.USDC_ADDRESS,await balanceOfToken(farmer1,MFC.DAI_ADDRESS));
    // });
});