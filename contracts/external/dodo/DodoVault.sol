// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DodoVault {
    // Apply to this contract for dodo https://cn.etherscan.com/address/0x3058ef90929cb8180174d74c507176cca6835d73#readContract

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function _BASE_RESERVE_() external view returns (uint112);

    function _QUOTE_RESERVE_() external view returns (uint112);

    function _RState_() external view returns (uint32);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function buyShares(address to)
        external
        returns (
            uint256 shares,
            uint256 baseInput,
            uint256 quoteInput
        );

    function sellBase(address to) external returns (uint256 receiveQuoteAmount);

    function sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        bytes calldata data,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 quoteAmount);

    function getVaultReserve() external view returns (uint256 baseReserve, uint256 quoteReserve);
}
