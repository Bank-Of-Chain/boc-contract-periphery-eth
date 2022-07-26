// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexIBUSDCBaseStrategy.sol";

contract ConvexIBUSDCAudStrategy is ConvexIBUSDCBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester
        );
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "ConvexIBUSDCAudStrategy";
    }

    function getCollateralCToken() public pure override returns(CTokenInterface){
        return CTokenInterface(0x76Eb2FE28b36B3ee97F3Adae0C69606eeDB2A37c);
    }
    function getCollateralToken() public pure override returns(address){
        return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }
    function getBorrowCToken() public pure override returns(CTokenInterface){
        return CTokenInterface(0x86BBD9ac8B9B44C95FFc6BAAe58E25033B7548AA);
    }
    function getCurvePool() public pure override returns(address){
        return 0x5b692073F141C31384faE55856CfB6CBfFE91E60;
    }
    function getRewardPool() public pure override returns(address){
        return 0xbAFC4FAeB733C18411886A04679F11877D8629b1;
    }

    function getPId() public pure override returns(uint256){
        return 84;
    }
}
