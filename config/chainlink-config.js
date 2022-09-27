const address = require('./address-config');
const {
    WETH_ADDRESS,
    DAI_ADDRESS,
    USDT_ADDRESS,
    USDC_ADDRESS,
    BUSD_ADDRESS,
    MIM_ADDRESS,
    TUSD_ADDRESS,
    USDP_ADDRESS,
    LUSD_ADDRESS,
    GUSD_ADDRESS,
    SUSD_ADDRESS,
    IBEUR_ADDRESS,
    IBKRW_ADDRESS,
    IBAUD_ADDRESS,
    IBGBP_ADDRESS,
    IBJPY_ADDRESS,
    IBCHF_ADDRESS,
} = address;
const CHAINLINK_RATE_ASSETS = {
    ETH: 0,
    USD: 1,
};

const getChainlinkConfig = () => {
    const nextConfig = {
        ETH_USD_AGGREGATOR: '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419',
        ETH_USD_HEARTBEAT: 1 * 60 * 60,
        basePegged: {
            WETH: {
                primitive: WETH_ADDRESS,
                rateAsset: CHAINLINK_RATE_ASSETS.ETH,
            },
        },
        aggregators: {
            WETH_USD: {
                primitive: WETH_ADDRESS,
                aggregator: '0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419',
                rateAsset: CHAINLINK_RATE_ASSETS.USD,
                heartbeat: 1 * 60 * 60
            },
//            DAI_USD: {
//                primitive: DAI_ADDRESS,
//                aggregator: '0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 1 * 60 * 60
//            },
            USDT_USD: {
                primitive: USDT_ADDRESS,
                aggregator: '0x3E7d1eAB13ad0104d2750B8863b489D65364e32D',
                rateAsset: CHAINLINK_RATE_ASSETS.USD,
                heartbeat: 24 * 60 * 60
            },
            USDC_USD: {
                primitive: USDC_ADDRESS,
                aggregator: '0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6',
                rateAsset: CHAINLINK_RATE_ASSETS.USD,
                heartbeat: 24 * 60 * 60
            },
//            BUSD_USD: {
//                primitive: BUSD_ADDRESS,
//                aggregator: '0x833D8Eb16D306ed1FbB5D7A2E019e106B960965A',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            EUR_USD: {
//                primitive: IBEUR_ADDRESS,
//                aggregator: '0xb49f677943BC038e9857d61E7d053CaA2C1734C1',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            KRW_USD: {
//                primitive: IBKRW_ADDRESS,
//                aggregator: '0x01435677FB11763550905594A16B645847C1d0F3',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            AUD_USD: {
//                primitive: IBAUD_ADDRESS,
//                aggregator: '0x77F9710E7d0A19669A13c055F62cd80d313dF022',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            GBP_USD: {
//                primitive: IBGBP_ADDRESS,
//                aggregator: '0x5c0Ab2d9b5a7ed9f470386e82BB36A3613cDd4b5',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            CHF_USD: {
//                primitive: IBCHF_ADDRESS,
//                aggregator: '0x449d117117838fFA61263B61dA6301AA2a88B13A',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            JPY_USD: {
//                primitive: IBJPY_ADDRESS,
//                aggregator: '0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            MIM_USD: {
//                primitive: MIM_ADDRESS,
//                aggregator: '0x7A364e8770418566e3eb2001A96116E6138Eb32F',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            TUSD_USD: {
//                primitive: TUSD_ADDRESS,
//                aggregator: '0xec746eCF986E2927Abd291a2A1716c940100f8Ba',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            USDP_USD: {
//                primitive: USDP_ADDRESS,
//                aggregator: '0x09023c0DA49Aaf8fc3fA3ADF34C6A7016D38D5e3',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 1 * 60 * 60
//            },
//            LUSD_USD: {
//                primitive: LUSD_ADDRESS,
//                aggregator: '0x3D7aE7E594f2f2091Ad8798313450130d0Aba3a0',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
//            GUSD_USD: {
//                primitive: GUSD_ADDRESS,
//                aggregator: '0xa89f5d2365ce98B3cD68012b6f503ab1416245Fc',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 1 * 60 * 60
//            },
//            SUSD_USD: {
//                primitive: SUSD_ADDRESS,
//                aggregator: '0xad35Bd71b9aFE6e4bDc266B345c198eaDEf9Ad94',
//                rateAsset: CHAINLINK_RATE_ASSETS.USD,
//                heartbeat: 24 * 60 * 60
//            },
        },
    }
    return nextConfig;
}

module.exports = {
    getChainlinkConfig
};
