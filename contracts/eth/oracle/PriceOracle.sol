// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IPriceOracle.sol";
import "../../external/lido/IWstETH.sol";
import "../../external/rocketpool/RocketTokenRETHInterface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "hardhat/console.sol";
import "../../library/ETHToken.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);
}

contract PriceOracle is IPriceOracle, Initializable {
    AggregatorInterface public constant steth_eth_aggregator =
        AggregatorInterface(0x86392dC19c0b719886221c78AB11eb8Cf5c52812);
    AggregatorInterface public constant eth_usd_aggregator =
        AggregatorInterface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    address private constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address private constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address private constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address private constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant sETH = 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb;

    address private constant weth_reth_uni_v3_pool = 0xf0E02Cf61b31260fd5AE527d58Be16312BDA59b1;
    address private constant weth_seth2_uni_v3_pool = 0x7379e81228514a1D2a6Cf7559203998E20598346;
    address private constant reth2_seth2_uni_v3_pool = 0xa9ffb27d36901F87f1D0F20773f7072e38C5bfbA;

    function initialize() public initializer {}

    function version() external pure returns (string memory){
        return '1.0.1';
    }
    
    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function stEthPriceInEth() public view override returns (uint256) {
        return uint256(steth_eth_aggregator.latestAnswer());
    }

    function wstEthPriceInEth() public view override returns (uint256) {
        return (IWstETH(wstETH).stEthPerToken() * stEthPriceInEth()) / 1e18;
    }

    function rEthPriceInEth() public view override returns (uint256) {
        uint256 twapPrice  = getTwapPrice(weth_reth_uni_v3_pool,3600);
        uint256 exchangeRate = RocketTokenRETHInterface(rETH).getExchangeRate();
        uint256 weigthedPrice = (exchangeRate + twapPrice) / 2;
        console.log('reth weigthedPrice:',weigthedPrice);
        return weigthedPrice;
    }

    function sEthPriceInEth() public pure override returns (uint256) {
        return 1 ether;
    }

    function wEthPriceInEth() public pure override returns (uint256) {
        return 1 ether;
    }

    function sEth2PriceInEth() public view override returns (uint256) {
        uint256 twapPrice = getTwapPrice(weth_seth2_uni_v3_pool, 60);
        return 1e18 * 1e18 / twapPrice;
    }

    function rEth2PriceInEth() public view override returns (uint256) {
        uint256 reth2ToSeth2TwapPrice = getTwapPrice(reth2_seth2_uni_v3_pool, 60);
        uint256 ethToSeth2TwapPrice = getTwapPrice(weth_seth2_uni_v3_pool, 60);
        return reth2ToSeth2TwapPrice * 1e18 / ethToSeth2TwapPrice;
    }

    function ethPriceInUsd() public view override returns (uint256) {
        return uint256(eth_usd_aggregator.latestAnswer());
    }

    function stEthPriceInUsd() external view override returns (uint256) {
        return (stEthPriceInEth() * ethPriceInUsd()) / 1e8;
    }

    function wstEthPriceInUsd() external view override returns (uint256) {
        return (wstEthPriceInEth() * ethPriceInUsd()) / 1e8;
    }

    function rEthPriceInUsd() external view override returns (uint256) {
        return (rEthPriceInEth() * ethPriceInUsd()) / 1e8;
    }

    function wEthPriceInUsd() external view override returns (uint256) {
        return (wEthPriceInEth() * ethPriceInUsd()) / 1e8;
    }

    function sEth2PriceInUsd() external view override returns (uint256) {
        return (sEth2PriceInEth() * ethPriceInUsd()) / 1e8;
    }

    function rEth2PriceInUsd() public view override returns (uint256) {
        return (rEth2PriceInEth() * ethPriceInUsd()) / 1e8;
    }

    function priceInEth(address _asset) public view override returns (uint256) {
        if (_asset == ETHToken.NATIVE_TOKEN) {
            return 1e18;
        } else if (_asset == stETH) {
            return stEthPriceInEth();
        } else if (_asset == wstETH) {
            return wstEthPriceInEth();
        } else if (_asset == rETH) {
            return rEthPriceInEth();
        } else if (_asset == wETH) {
            return wEthPriceInEth();
        } else if (_asset == sETH) {
            return sEthPriceInEth();
        } else if (_asset == sETH2) {
            return sEth2PriceInEth();
        } else if (_asset == rETH2) {
            return rEth2PriceInEth();
        } else {
            assert(false);
        }
    }

    function priceInUSD(address _asset) public view override returns (uint256) {
        if (_asset == ETHToken.NATIVE_TOKEN) {
            return ethPriceInUsd() * 1e10;
        } else {
            return (priceInEth(_asset) * ethPriceInUsd()) / 1e8;
        }
    }

    function valueInEth(address _asset, uint256 _amount) external view override returns (uint256) {
        return (priceInEth(_asset) * _amount) / getPowDecimals(_asset);
    }

    function valueInUsd(address _asset, uint256 _amount) external view override returns (uint256) {
        return (priceInUSD(_asset) * _amount) / getPowDecimals(_asset);
    }

    function valueInTargetToken(
        address _fromToken,
        uint256 _amount,
        address _toToken
    ) external view override returns (uint256) {
        return
            (priceInEth(_fromToken) * _amount * getPowDecimals(_toToken)) /
            getPowDecimals(_fromToken) /
            priceInEth(_toToken);
    }

    function getPowDecimals(address _asset) internal view returns (uint256) {
        if (_asset == ETHToken.NATIVE_TOKEN) {
            return 1e18;
        } else {
            return 10**IERC20Metadata(_asset).decimals();
        }
    }

    function getTwapPrice(address _pool,uint32 _twapDuration) internal view returns(uint256) {
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = _twapDuration;
        secondsAgo[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(_pool).observe(secondsAgo);
        int24 twap = int24((tickCumulatives[1] - tickCumulatives[0]) / int32(_twapDuration));

        uint256 priceSqrt = (TickMath.getSqrtRatioAtTick(twap) * 1e18) / 2**96;
        console.log("getTwapPrice priceSqrt:", priceSqrt);
        uint256 twapPrice = priceSqrt**2 / 1e18;
        return twapPrice;
    }
}
