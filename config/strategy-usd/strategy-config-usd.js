const {auraStrategies} = require('./strategy-config-usd-aura');
const {convexStrategies} = require('./strategy-config-usd-convex');
const {dForceStrategies} = require('./strategy-config-usd-dforce');
const {dodoStrategies} = require('./strategy-config-usd-dodo');
const {stargateStrategies} = require('./strategy-config-usd-stargate');
const {sushiStrategies} = require('./strategy-config-usd-sushi');
const {uniswapStrategies} = require('./strategy-config-usd-uniswap');
const {yearnStrategies} = require('./strategy-config-usd-yearn');
const {aaveStrategies} = require('./strategy-config-usd-aave');

const strategiesList = [
    ...auraStrategies,
    ...convexStrategies,
    ...dForceStrategies,
    ...dodoStrategies,
    // ...stargateStrategies,
    // ...sushiStrategies,
    ...uniswapStrategies,
    // ...yearnStrategies
    ...aaveStrategies
]

exports.strategiesList = strategiesList
