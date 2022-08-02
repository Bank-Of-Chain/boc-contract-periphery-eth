const address = require('./../config/address-config');
const topUp = require('./../utils/top-up-utils');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const BigNumber = require('bignumber.js');
const MockUniswapV3Router = hre.artifacts.require('contracts/usd/mock/MockUniswapV3Router.sol:MockUniswapV3Router');
const swapParam = process.env.HARDHAT_TSCONFIG;

const main = async () => {
    const network = hre.network.name;
    console.log('\n\n 📡 uniswapv3 swap ... At %s Network \n', network);

    const swapParams = swapParam.split(",");
    const swapPoolAddress = swapParams[0];
    console.log('swapPoolAddress: ', swapPoolAddress);
    const swapTokenAddress = swapParams[1];
    console.log('swapTokenAddress: ', swapTokenAddress);
    const swapTokenPosition = swapParams[2];
    console.log('swapTokenPosition: ', swapTokenPosition);
    const swapAmount = swapParams[3];
    console.log('swapAmount: ', swapAmount);

    const accounts = await ethers.getSigners();
    const investor = accounts[1].address;
    const mockUniswapV3Router = await MockUniswapV3Router.new();

    let swapToken = await ERC20.at(swapTokenAddress);
    let swapTokenDecimals = await swapToken.decimals();
    await topUpSwapAmount(swapTokenAddress, swapAmount, investor);

    let swapTokenBalance = new BigNumber(await swapToken.balanceOf(investor));
    console.log('swapTokenBalance: ', swapTokenBalance.toFixed());
    await swapToken.approve(mockUniswapV3Router.address, new BigNumber(swapAmount).multipliedBy(new BigNumber(10).pow(swapTokenDecimals)), {"from": investor});
    await mockUniswapV3Router.swap(swapPoolAddress, swapTokenPosition === '0', new BigNumber(swapAmount).multipliedBy(new BigNumber(10).pow(swapTokenDecimals)), {"from": investor});
    console.log('swap finish!!!');

    async function topUpSwapAmount(tokenAddress, tokenAmount, investor) {
        let token;
        let tokenDecimals;
        switch (tokenAddress) {
            case address.USDT_ADDRESS:
                console.log('top up USDT');
                token = await ERC20.at(address.USDT_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpUsdtByAddress(tokenAmount * 10 ** tokenDecimals, investor);
                break;
            case address.USDC_ADDRESS:
                console.log('top up USDC');
                token = await ERC20.at(address.USDC_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpUsdcByAddress(tokenAmount * 10 ** tokenDecimals, investor);
                break;
            case address.DAI_ADDRESS:
                console.log('top up DAI');
                token = await ERC20.at(address.DAI_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpDaiByAddress(tokenAmount * 10 ** tokenDecimals, investor);
                break;
            case address.BUSD_ADDRESS:
                console.log('top up BUSD');
                token = await ERC20.at(address.BUSD_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.impersonates([address.BUSD_WHALE_ADDRESS]);
                await topUp.topUpMain(
                    address.BUSD_ADDRESS,
                    address.BUSD_WHALE_ADDRESS,
                    investor,
                    tokenAmount * 10 ** tokenDecimals
                );
                break;
            case address.TUSD_ADDRESS:
                console.log('top up TUSD');
                token = await ERC20.at(address.TUSD_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.topUpTusdByAddress(tokenAmount * 10 ** tokenDecimals, investor);
                break;
            case address.USDP_ADDRESS:
                console.log('top up USDP');
                token = await ERC20.at(address.USDP_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.impersonates([address.USDP_WHALE_ADDRESS]);
                await topUp.topUpMain(
                    address.USDP_ADDRESS,
                    address.USDP_WHALE_ADDRESS,
                    investor,
                    tokenAmount * 10 ** tokenDecimals
                );
                break;
            case address.GUSD_ADDRESS:
                console.log('top up GUSD');
                token = await ERC20.at(address.GUSD_ADDRESS);
                tokenDecimals = await token.decimals();
                await topUp.impersonates([address.GUSD_WHALE_ADDRESS]);
                await topUp.topUpMain(
                    address.GUSD_ADDRESS,
                    address.GUSD_WHALE_ADDRESS,
                    investor,
                    tokenAmount * 10 ** tokenDecimals
                );
                break;
            default:
                throw new Error('Unsupported token!');
        }
        console.log('topUp finish!!!');
    }
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
