const IAddressResolver = hre.artifacts.require('IAddressResolver');
const ISystemSettings = hre.artifacts.require('ISystemSettings');

const {
    impersonates,
} = require('../utils/top-up-utils');

const SYSTEM_SETTING_BYTES32 = '0x53797374656d53657474696e67730000000000000000000000000000000000';
const systemSettingOwner = '0xeb3107117fead7de89cd14d463d340a2e6917769';
async function modifier() {
    let addressResolver = await IAddressResolver.at('0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83');
    const systemSettingAddr = await addressResolver.getAddress(SYSTEM_SETTING_BYTES32);
    console.log('systemSettingAddr:%s', systemSettingAddr);

    const systemSetting = await ISystemSettings.at(systemSettingAddr);

    await impersonates([systemSettingOwner]);
    await systemSetting.setRateStalePeriod(1000000, { from: systemSettingOwner });
    console.log('rateStalePeriod:%d', await systemSetting.rateStalePeriod());

    // 合成资产的使用间隔设置成0
    await systemSetting.setWaitingPeriodSecs(0, { from: systemSettingOwner });
}

module.exports = {
    modifier
}