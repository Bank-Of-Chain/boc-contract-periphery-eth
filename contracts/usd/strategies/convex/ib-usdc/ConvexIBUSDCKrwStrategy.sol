// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexIBUSDCBaseStrategy.sol";

contract ConvexIBUSDCKrwStrategy is ConvexIBUSDCBaseStrategy {
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
        return "ConvexIBUSDCKrwStrategy";
    }

    function getCollateralCToken() public pure override returns(CTokenInterface){
        return CTokenInterface(0x76Eb2FE28b36B3ee97F3Adae0C69606eeDB2A37c);
    }
    function getCollateralToken() public pure override returns(address){
        return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }
    function getBorrowCToken() public pure override returns(CTokenInterface){
        return CTokenInterface(0x3c9f5385c288cE438Ed55620938A4B967c080101);
    }
    function getCurvePool() public pure override returns(address){
        return 0xef04f337fCB2ea220B6e8dB5eDbE2D774837581c;
    }
    function getRewardPool() public pure override returns(address){
        return 0x1900249c7a90D27b246032792004FF0E092Ac2cE;
    }
    function getPId() public pure override returns(uint256){
        return 89;
    }
}
