// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexIBUSDCBaseStrategy.sol";

contract ConvexIBUSDCGbpStrategy is ConvexIBUSDCBaseStrategy {
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
        return "ConvexIBUSDCGbpStrategy";
    }

    function getCollateralCToken() public pure override returns(CTokenInterface){
        return CTokenInterface(0x76Eb2FE28b36B3ee97F3Adae0C69606eeDB2A37c);
    }
    function getCollateralToken() public pure override returns(address){
        return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }
    function getBorrowCToken() public pure override returns(CTokenInterface){
        return CTokenInterface(0xecaB2C76f1A8359A06fAB5fA0CEea51280A97eCF);
    }
    function getCurvePool() public pure override returns(address){
        return 0xAcCe4Fe9Ce2A6FE9af83e7CF321a3fF7675e0AB6;
    }
    function getRewardPool() public pure override returns(address){
        return 0x8C87E32000ADD1a7D7D69a1AE180C415AF769361;
    }
    function getPId() public pure override returns(uint256){
        return 87;
    }
}
