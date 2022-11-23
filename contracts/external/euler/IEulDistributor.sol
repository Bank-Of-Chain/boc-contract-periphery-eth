// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEulDistributor {

    /// @notice Claim distributed tokens
    /// @param account Address that should receive tokens
    /// @param token Address of token being claimed (ie EUL)
    /// @param proof Merkle proof that validates this claim
    /// @param stake If non-zero, then the address of a token to auto-stake to, instead of claiming
    function claim(address account, address token, uint claimable, bytes32[] calldata proof, address stake) external;
}
