// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0 <0.9.0;

//import "./ILiquidityProtectionStore.sol";
//import "./ILiquidityProtectionStats.sol";
//import "./ILiquidityProtectionSettings.sol";
//import "./ILiquidityProtectionSystemStore.sol";
//import "./ITransferPositionCallback.sol";

//import "../../utility/interfaces/ITokenHolder.sol";
//
//import "../../token/interfaces/IReserveToken.sol";
//
//import "../../converter/interfaces/IConverterAnchor.sol";

/*
    Liquidity Protection interface
*/
interface ILiquidityProtection {
//    function store() external view returns (ILiquidityProtectionStore);
//
//    function stats() external view returns (ILiquidityProtectionStats);
//
//    function settings() external view returns (ILiquidityProtectionSettings);
//
//    function systemStore() external view returns (ILiquidityProtectionSystemStore);
//
//    function wallet() external view returns (ITokenHolder);

    function poolAvailableSpace(address poolAnchor) external view returns( uint256, uint256);

    function addLiquidityFor(
        address owner,
        address poolAnchor,
        address reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function addLiquidity(
        address poolAnchor,
        address reserveToken,
        uint256 amount
    ) external payable returns (uint256);

    function removeLiquidity(uint256 id, uint32 portion) external;

    function transferPosition(uint256 id, address newProvider) external returns (uint256);

//    function transferPositionAndNotify(
//        uint256 id,
//        address newProvider,
//        ITransferPositionCallback callback,
//        bytes calldata data
//    ) external returns (uint256);
}
