// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexIronBankBaseStrategy.sol";

contract ConvexIronBankEurStrategy is ConvexIronBankBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(_vault,
        _harvester,
        0xdAC17F958D2ee523a2206206994597C13D831ec7 ,//collateralToken
        0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a ,//collateralCToken
        0x00e5c0774A5F065c285068170b20393925C84BF3 ,//borrowCToken
        0xCd0559ADb6fAa2fc83aB21Cf4497c3b9b45bB29f);//rewardPool
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "ConvexIronBankEurStrategy";
    }

    
}
