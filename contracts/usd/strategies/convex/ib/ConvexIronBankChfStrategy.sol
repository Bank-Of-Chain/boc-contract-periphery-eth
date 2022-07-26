// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexIronBankBaseStrategy.sol";

contract ConvexIronBankChfStrategy is ConvexIronBankBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(_vault,
        _harvester,
        0xdAC17F958D2ee523a2206206994597C13D831ec7 ,//collateralToken
        0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a ,//collateralCToken
        0x1b3E95E8ECF7A7caB6c4De1b344F94865aBD12d5 ,//borrowCToken
        0xa5A5905efc55B05059eE247d5CaC6DD6791Cfc33);//rewardPool
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "ConvexIronBankChfStrategy";
    }

    
}
