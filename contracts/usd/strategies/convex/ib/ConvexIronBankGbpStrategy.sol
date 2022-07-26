// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexIronBankBaseStrategy.sol";

contract ConvexIronBankGbpStrategy is ConvexIronBankBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(_vault,
        _harvester,
        0xdAC17F958D2ee523a2206206994597C13D831ec7 ,//collateralToken
        0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a ,//collateralCToken
        0xecaB2C76f1A8359A06fAB5fA0CEea51280A97eCF ,//borrowCToken
        0x51a16DA36c79E28dD3C8c0c19214D8aF413984Aa);//rewardPool
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "ConvexIronBankGbpStrategy";
    }

    
}
