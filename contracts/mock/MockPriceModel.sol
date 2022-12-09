// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../external/dforce/IDForcePriceModel.sol";
import "../external/dforce/IDForcePriceOracle.sol";
import "../external/dforce/IDForceController.sol";

/// @title MockPriceOracle
/// @notice The mock contract of PriceOracle contract
contract MockPriceModel is IDForcePriceModel {

    mapping(address => address) private priceModelMap;
    address private constant originPriceOracleAddr = 0xb4De37b03f7AcE98FB795572B18aE3CFae85A628;

    constructor(){
        IDForcePriceOracle originPriceOracle = IDForcePriceOracle(originPriceOracleAddr);
        IDForceController _controller = IDForceController(0x8B53Ab2c0Df3230EA327017C91Eb909f815Ad113);
        address[] memory _alliTokens = _controller.getAlliTokens();
        for(uint256 i=0;i<_alliTokens.length;i++){
            priceModelMap[_alliTokens[i]] = originPriceOracle.priceModel(_alliTokens[i]);
        }
    }

    /// @notice Send funds to the pool
    /// @dev Users are able to submit their funds by transacting to the fallback function.
    /// Unlike vanilla Eth2.0 Deposit contract, accepting only 32-Ether transactions, Lido
    /// accepts payments of any size. Submitted Ethers are stored in Buffer until someone calls
    /// depositBufferedEther() and pushes them to the ETH2 Deposit contract.
    receive() external payable {}

    /// @dev fallback
    /// @notice This is a catch all for all functions not declared in core
    fallback() external payable {}

    function isPriceModel() external view override returns (bool){
        return true;
    }

    function getAssetPrice(address _asset) external override returns (uint256){
        return IDForcePriceModel(priceModelMap[_asset]).getAssetPrice(_asset);
    }

    function getAssetStatus(address _asset) external override returns (bool){
        return true;
    }

    function getAssetPriceStatus(address _asset)
    external
    override
    returns (uint256, bool){
        return (IDForcePriceModel(priceModelMap[_asset]).getAssetPrice(_asset),true);
    }
}