// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DodoVaultV1 {
    // Apply to this contract for dodo https://cn.etherscan.com/address/0xc9f93163c99695c6526b799ebca2207fdf7d61ad#readContract

    function depositQuote(uint256 amount) external returns (uint256);

    function depositBase(uint256 amount) external returns (uint256);

    function getTotalBaseCapital() external view returns (uint256);

    function getTotalQuoteCapital() external view returns (uint256);

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function _BASE_BALANCE_() external view returns (uint256);

    function _QUOTE_BALANCE_() external view returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external view returns (address);

    function _QUOTE_CAPITAL_TOKEN_() external view returns (address);

    function _TARGET_QUOTE_TOKEN_AMOUNT_() external view returns (uint256);

    function _TARGET_BASE_TOKEN_AMOUNT_() external view returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawBase(uint256 amount) external returns (uint256);

    function _R_STATUS_() external view returns (uint8);

    function getQuoteCapitalBalanceOf(address lp) external view returns (uint256);

    function getBaseCapitalBalanceOf(address lp) external view returns (uint256);

    function getLpQuoteBalance(address lp) external view returns (uint256 lpBalance);

    function getWithdrawBasePenalty(uint256 amount) external view returns (uint256 penalty);

    function getWithdrawQuotePenalty(uint256 amount) external view returns (uint256 penalty);

    function getExpectedTarget() external view returns (uint256 baseTarget, uint256 quoteTarget);
}
