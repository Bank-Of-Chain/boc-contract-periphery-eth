const {auraStrategies} = require('./strategy-config-eth-aura');
const {convexStrategies} = require('./strategy-config-eth-convex');
const {uniswapStrategies} = require('./strategy-config-eth-uniswap');
const {stakewiseStrategies} = require('./strategy-config-eth-stakewise');
const {yearnStrategies} = require('./strategy-config-eth-yearn');

const strategiesList = [
    ...auraStrategies,
    ...convexStrategies,
    ...uniswapStrategies,
    ...stakewiseStrategies,
    ...yearnStrategies
]

exports.strategiesList = strategiesList