// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexIronBankBaseStrategy.sol";

contract ConvexIronBankKrwStrategy is ConvexIronBankBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(_vault,
        _harvester,
        0xdAC17F958D2ee523a2206206994597C13D831ec7 ,//collateralToken
        0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a ,//collateralCToken
        0x3c9f5385c288cE438Ed55620938A4B967c080101 ,//borrowCToken
        0x8F18C0AF0d7d511E8Bdc6B3c64926B04EDfE4892);//rewardPool
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "ConvexIronBankKrwStrategy";
    }

    
}
