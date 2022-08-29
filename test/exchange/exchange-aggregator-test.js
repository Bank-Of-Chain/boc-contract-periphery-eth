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

const EXCHANGE_PLATFORMS = {
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

const getExchangePlatformAdapters = async exchangeAggregator => {
    const adapters = await exchangeAggregator.getExchangeAdapters()
    const exchangePlatformAdapters = {}
    for (let i = 0; i < adapters._identifiers.length; i++) {
        exchangePlatformAdapters[adapters._identifiers[i]] = adapters._exchangeAdapters[i]
    }
    return exchangePlatformAdapters
}

const getTokenDetail = async function (tokenAddr) {
    if (tokenAddr == '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE') {
        return { address: tokenAddr, symbol: 'ETH', decimals: 18 }
    }
    const token = await ERC20.at(tokenAddr);
    return { address: tokenAddr, symbol: await token.symbol(), decimals: Number(await token.decimals()) }
}

const balanceOfToken = async function (account, tokenAddr) {
    if (tokenAddr == '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE') {
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



    before('INIT', async function () {
        await ethers.getSigners().then((resp) => {
            accounts = resp;
            governance = accounts[0].address;
            farmer1 = accounts[1].address;
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

    it('Case 1: ETH swap to USDT should success.', async function () {
        let platformAdapter = {
            // paraswap: exchangePlatformAdapters.paraswap,
            oneInchV4: exchangePlatformAdapters.oneInchV4
        };
        const srcTokenDetail = await getTokenDetail(MFC.ETH_ADDRESS);
        const dstTokenDetail = await getTokenDetail(MFC.USDT_ADDRESS);
        const srcAmount = new BigNumber(1e18);

        const SWAP_INFO = await getBestSwapInfo(srcTokenDetail,
            dstTokenDetail, srcAmount, 4999, 4999, platformAdapter, EXCHANGE_PLATFORMS);
        const swapDesc = {
            amount: srcAmount.toString(),
            srcToken: srcTokenDetail.address,
            dstToken: dstTokenDetail.address,
            receiver: farmer1
        };
        const tx = await exchangeAggregator.swap(SWAP_INFO.platform, SWAP_INFO.method, SWAP_INFO.encodeExchangeArgs, swapDesc, { from: farmer1, value: srcAmount });

        expectEvent(tx, 'Exchanged', {
            _sender: farmer1,
            _platform: SWAP_INFO.platform,
            _srcToken: swapDesc.srcToken,
            _srcAmount: srcAmount.toString(),
            _dstToken: swapDesc.dstToken,
            _dstAmount: (await balanceOfToken(farmer1, swapDesc.dstToken)).toString()
        })
    });

    it('Case 2: USDT swap to USDC on curve should success.', async function () {
        let platformAdapter = {
            // paraswap: exchangePlatformAdapters.paraswap,
            oneInchV4: exchangePlatformAdapters.oneInchV4
        };
        const srcTokenDetail = await getTokenDetail(MFC.USDT_ADDRESS);
        const dstTokenDetail = await getTokenDetail(MFC.USDC_ADDRESS);
        const srcAmount = await balanceOfToken(farmer1, MFC.USDT_ADDRESS);
        const srcPlusAmount = srcAmount.plus(1000);
        const SWAP_INFO = await getBestSwapInfo(srcTokenDetail,
            dstTokenDetail, srcPlusAmount, 4999, 4999, platformAdapter, {
            oneInchV4: {
                useHttp: true,
                network: 1,
                protocols: 'BALANCER_V2'
            }
        });
        const swapDesc = {
            amount: srcAmount.toString(),
            srcToken: srcTokenDetail.address,
            dstToken: dstTokenDetail.address,
            receiver: farmer1
        };
        const dstTokenBalance1 = await balanceOfToken(farmer1, swapDesc.dstToken);
        console.log('dstTokenBalance1:%d',dstTokenBalance1);
        const token = await ERC20.at(swapDesc.srcToken);
        await token.approve(exchangeAggregator.address, srcAmount, { from: farmer1 });
        console.log('perpare srcAmount:%d',srcAmount);
        
        const tx = await exchangeAggregator.swap(SWAP_INFO.platform, SWAP_INFO.method, SWAP_INFO.encodeExchangeArgs, swapDesc, { from: farmer1, value: srcAmount });

        const dstTokenBalance2 = await balanceOfToken(farmer1, swapDesc.dstToken);
        console.log('dstTokenBalance2:%d',dstTokenBalance2);
        
        expectEvent(tx, 'Exchanged', {
            _sender: farmer1,
            _platform: SWAP_INFO.platform,
            _srcToken: swapDesc.srcToken,
            _srcAmount: srcAmount.toString(),
            _dstToken: swapDesc.dstToken,
            _dstAmount: (dstTokenBalance2.minus(dstTokenBalance1)).toString()
        })
    });
});