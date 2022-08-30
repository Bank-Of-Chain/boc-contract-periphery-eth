const BigNumber = require('bignumber.js');
const { expectEvent,
    expectRevert,
    BN } = require('@openzeppelin/test-helpers');
const MFC = require("../../config/mainnet-fork-test-config")
const { getBestSwapInfo } = require("piggy-finance-utils");
const { ethers } = require('hardhat');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const AccessControlProxy = artifacts.require('AccessControlProxy')
const ExchangeAggregator = artifacts.require('ExchangeAggregator')
const OneInchV4Adapter = artifacts.require('OneInchV4Adapter')
const ParaSwapV5Adapter = artifacts.require('ParaSwapV5Adapter')
const NativeToken = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

const EXCHANGE_PLATFORMS = {
    oneInchV4: {
        useHttp: true,
        network: 1,
        // protocols: 'CURVE_V2,SUSHI,CURVE,UNISWAP_V2,UNISWAP_V3'
    },
    paraswap: {
        network: 1,
        includeDEXS: 'UniswapV2,UniswapV3,SushiSwap,mStable,DODOV2,DODOV1,Curve,CurveV2,Compound,Bancor,BalancerV2,Aave2',
        excludeContractMethods: ['swapOnZeroXv2', 'swapOnZeroXv4']
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
        return new BigNumber(await ethers.provider.getBalance(account));
    }
    const token = await ERC20.at(tokenAddr);
    return new BigNumber(await token.balanceOf(account));
}

describe('ExchangeAggregator test.', function () {
    let governance;
    let keeper;
    let vault;
    let farmer1
    let exchangeAggregator;

    let tokenList = [
        MFC.ETH_ADDRESS,
        MFC.rocketPoolETH_ADDRESS,
        MFC.stETH_ADDRESS,
        MFC.DAI_ADDRESS,
        MFC.USDC_ADDRESS,
        MFC.TUSD_ADDRESS,
        MFC.LUSD_ADDRESS,
        MFC.USDT_ADDRESS,
        MFC.wstETH_ADDRESS
    ];

    async function swap(srcTokenAddr, dstTokenAddr, srcAmount = new BigNumber(1e18)) {
        let platformAdapter = {
            paraswap: exchangePlatformAdapters.paraswap,
            oneInchV4: exchangePlatformAdapters.oneInchV4
        };
        const srcTokenDetail = await getTokenDetail(srcTokenAddr);
        const dstTokenDetail = await getTokenDetail(dstTokenAddr);

        if (srcTokenAddr != NativeToken){
            srcAmount = new BigNumber(100 * 1e18);
            const srcBalance = await balanceOfToken(farmer1,srcTokenAddr);
            if (srcAmount.isGreaterThan(srcBalance)){
                srcAmount = srcBalance;
            }
        }
        console.log('getBestSwapInfo## from:%s to:%s,amount:%s',srcTokenDetail.symbol,dstTokenDetail.symbol,srcAmount);
        const SWAP_INFO = await getBestSwapInfo(srcTokenDetail,
            dstTokenDetail, srcAmount, 4900, 4900, platformAdapter, EXCHANGE_PLATFORMS);
        const swapDesc = {
            amount: srcAmount.toString(),
            srcToken: srcTokenDetail.address,
            dstToken: dstTokenDetail.address,
            receiver: farmer1
        };
        let tx;
        if (srcTokenAddr == NativeToken) {
            tx = await exchangeAggregator.swap(SWAP_INFO.platform, SWAP_INFO.method, SWAP_INFO.encodeExchangeArgs, swapDesc, { from: farmer1, value: srcAmount });
        } else {
            const token = await ERC20.at(swapDesc.srcToken);
            await token.approve(exchangeAggregator.address, srcAmount, { from: farmer1 });
            tx = await exchangeAggregator.swap(SWAP_INFO.platform, SWAP_INFO.method, SWAP_INFO.encodeExchangeArgs, swapDesc, { from: farmer1 });
        }

        expectEvent(tx, 'Swap', {
            _platform: SWAP_INFO.platform,
            _amount: srcAmount.toString(),
            _srcToken: swapDesc.srcToken,
            _dstToken: swapDesc.dstToken,
            _exchangeAmount: (await balanceOfToken(farmer1, swapDesc.dstToken)).toFixed(),
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
    });

    for (let i = 0; i < tokenList.length - 1; i++) {
        const srcToken = tokenList[i];
        const dstToken = tokenList[i + 1];
        it(`Case ${i}: swap ${srcToken} to ${dstToken} should be success.`, async function () {
            let srcAmount = await balanceOfToken(farmer1,srcToken);
            if (srcToken == NativeToken){
                srcAmount = new BigNumber(10 * 1e18);
            }
            await swap(srcToken, dstToken,srcAmount);
        });
    }

});