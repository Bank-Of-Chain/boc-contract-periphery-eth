// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexIronBankBaseStrategy.sol";

contract ConvexIronBankJpyStrategy is ConvexIronBankBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(_vault,
        _harvester,
        0xdAC17F958D2ee523a2206206994597C13D831ec7 ,//collateralToken
        0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a ,//collateralCToken
        0x215F34af6557A6598DbdA9aa11cc556F5AE264B1 ,//borrowCToken
        0xbA8fE590498ed24D330Bb925E69913b1Ac35a81E);//rewardPool
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "ConvexIronBankJpyStrategy";
    }

    
}
