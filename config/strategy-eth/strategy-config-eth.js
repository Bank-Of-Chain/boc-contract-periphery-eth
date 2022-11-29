const {auraStrategies} = require('./strategy-config-eth-aura');
const {convexStrategies} = require('./strategy-config-eth-convex');
const {dForceStrategies} = require('./strategy-config-eth-dforce');
const {eulerStrategies} = require('./strategy-config-eth-euler');
const {uniswapStrategies} = require('./strategy-config-eth-uniswap');
const {stakewiseStrategies} = require('./strategy-config-eth-stakewise');
const {yearnStrategies} = require('./strategy-config-eth-yearn');
const {aaveStrategies} = require('./strategy-config-eth-aave');

const strategiesList = [
//     ...auraStrategies,
//     ...convexStrategies,
//     ...dForceStrategies,
    ...eulerStrategies,
//     ...uniswapStrategies,
//     ...stakewiseStrategies,
//     ...yearnStrategies,
//     ...aaveStrategies
]

exports.strategiesList = strategiesList