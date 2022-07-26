const address = require('./address-config');
const {
  getChainlinkConfig
} = require('./chainlink-config');

const config = getChainlinkConfig();
module.exports = {
  ...address,
  CHAINLINK: config
};