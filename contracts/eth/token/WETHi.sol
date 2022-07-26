// SPDX-FileCopyrightText: 2021 Lido <info@lido.fi>

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./IETHi.sol";

contract WETHi is ERC20Permit {
    IETHi public ETHi;

    /**
     * @param _ETHi address of the ETHi token to wrap
     */
    constructor(IETHi _ETHi)
        public
        ERC20Permit("Wrapped bank of chain ETH")
        ERC20("Wrapped bank of chain ETH", "WETHi")
    {
        ETHi = _ETHi;
    }

    /**
     * @notice Exchanges ETHi to WETHi
     * @param _ETHiAmount amount of ETHi to wrap in exchange for WETHi
     * @dev Requirements:
     *  - `_ETHiAmount` must be non-zero
     *  - msg.sender must approve at least `_ETHiAmount` ETHi to this
     *    contract.
     *  - msg.sender must have at least `_ETHiAmount` of ETHi.
     * User should first approve _ETHiAmount to the WETHi contract
     * @return Amount of WETHi user receives after wrap
     */
    function wrap(uint256 _ETHiAmount) external returns (uint256) {
        require(_ETHiAmount > 0, "wstETH: can't wrap zero stETH");
        uint256 wETHiAmount = ETHi.getSharesByPooledEth(_ETHiAmount);
        _mint(msg.sender, wETHiAmount);
        ETHi.transferFrom(msg.sender, address(this), _ETHiAmount);
        return wETHiAmount;
    }

    /**
     * @notice Exchanges WETHi to ETHi
     * @param _wETHiAmount amount of WETHi to uwrap in exchange for ETHi
     * @dev Requirements:
     *  - `_wETHiAmount` must be non-zero
     *  - msg.sender must have at least `_wETHiAmount` WETHi.
     * @return Amount of stETH user receives after unwrap
     */
    function unwrap(uint256 _wETHiAmount) external returns (uint256) {
        require(_wETHiAmount > 0, "wstETH: zero amount unwrap not allowed");
        uint256 ETHiAmount = ETHi.getPooledEthByShares(_wETHiAmount);
        _burn(msg.sender, _wETHiAmount);
        ETHi.transfer(msg.sender, ETHiAmount);
        return ETHiAmount;
    }


    /**
     * @notice Get amount of WETHi for a given amount of ETHi
     * @param _ETHiAmount amount of ETHi
     * @return Amount of WETHi for a given ETHi amount
     */
    function getWETHiByETHi(uint256 _ETHiAmount) external view returns (uint256) {
        return ETHi.getSharesByPooledEth(_ETHiAmount);
    }

    /**
     * @notice Get amount of ETHi for a given amount of WETHi
     * @param _wstETHAmount amount of WETHi
     * @return Amount of ETHi for a given WETHi amount
     */
    function getETHiByWETHi(uint256 _wstETHAmount) external view returns (uint256) {
        return ETHi.getPooledEthByShares(_wstETHAmount);
    }

    /**
     * @notice Get amount of ETHi for a one WETHi
     * @return Amount of ETHi for 1 WETHi
     */
    function eTHiPerToken() external view returns (uint256) {
        return ETHi.getPooledEthByShares(1 ether);
    }

    /**
     * @notice Get amount of WETHi for a one ETHi
     * @return Amount of WETHi for a 1 ETHi
     */
    function tokensPerETHi() external view returns (uint256) {
        return ETHi.getSharesByPooledEth(1 ether);
    }
}