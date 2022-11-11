// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface DFiToken {
    function mint(address, uint256) external;

    /**
     * @dev Caller deposits assets into the market and `_recipient` receives iToken in exchange.
     * @param _recipient The account that would receive the iToken.
     */
    function mint(address _recipient) external payable;

    function redeem(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    /**
     * @dev Caller borrows tokens from the protocol to their own address.
     * @param _borrowAmount The amount of the underlying token to borrow.
     */
    function borrow(uint256 _borrowAmount) external;

    /**
     * @dev Caller repays their own borrow.
     * @param _repayAmount The amount to repay.
     */
    function repayBorrow(uint256 _repayAmount) external;

    /**
     * @dev Caller repays their own borrow.
     */
    function repayBorrow() external payable;

    /**
     * @dev Gets the borrow balance of user without accruing interest.
     */
    function borrowBalanceStored(address _account) external view returns (uint256);

    /**
     * @dev Gets user borrowing information. return principal and interestIndex
     */
    function borrowSnapshot(address _account) external view returns (uint256, uint256);

    /**
     * @dev Gets the user's borrow balance with the latest `borrowIndex`.
     */
    function borrowBalanceCurrent(address _account) external returns (uint256);
}
