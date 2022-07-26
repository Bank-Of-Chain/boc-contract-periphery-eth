// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexIBUSDCBaseStrategy.sol";

contract ConvexIBUSDCChfStrategy is ConvexIBUSDCBaseStrategy {
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
        return "ConvexIBUSDCChfStrategy";
    }

    function getCollateralCToken() public pure override returns(CTokenInterface){
        return CTokenInterface(0x76Eb2FE28b36B3ee97F3Adae0C69606eeDB2A37c);
    }
    function getCollateralToken() public pure override returns(address){
        return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }
    function getBorrowCToken() public pure override returns(CTokenInterface){
        return CTokenInterface(0x1b3E95E8ECF7A7caB6c4De1b344F94865aBD12d5);
    }
    function getCurvePool() public pure override returns(address){
        return 0x6Df0D77F0496CE44e72D695943950D8641fcA5Cf;
    }
    function getRewardPool() public pure override returns(address){
        return 0x9BEc26bDd9702F4e0e4de853dd65Ec75F90b1F2e;
    }

    function getPId() public pure override returns(uint256){
        return 85;
    }
}
