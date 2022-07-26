pragma solidity >=0.8.0 <0.9.0;

interface ISystemStatus {
    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);
}