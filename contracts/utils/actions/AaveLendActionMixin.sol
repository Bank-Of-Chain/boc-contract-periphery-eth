// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <council@enzyme.finance>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "../../external/aave/ILendingPool.sol";
import "../../external/aave/IWETHGateway.sol";
import "../../external/aave/IAToken.sol";
import {DataTypes} from "../../external/aave/DataTypes.sol";

import "hardhat/console.sol";

abstract contract AaveLendActionMixin {
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // aave lending pool address
    address internal constant LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    // native token gateway
    address internal constant WETH_GATEWAY = 0xEFFC18fC3b7eb8E676dac549E0c693ad50D1Ce31;
    //interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
    uint256 internal interestRateMode;

    address internal collaternalToken;
    address internal borrowToken;

    // address internal aBorrowToken;

    function borrowInfo()
        public
        view
        returns (
            uint256 _totalCollateralETH,
            uint256 _totalDebtETH,
            uint256 _availableBorrowsETH,
            uint256 _currentLiquidationThreshold,
            uint256 _ltv,
            uint256 _healthFactor
        )
    {
        return ILendingPool(LENDING_POOL).getUserAccountData(address(this));
    }

    function getAToken(address _asset) public view returns (address) {
        if (_asset == NativeToken.NATIVE_TOKEN) {
            _asset = WETH;
        }
        return ILendingPool(LENDING_POOL).getReserveData(_asset).aTokenAddress;
    }

    function getDebtToken() public view returns (address) {
        address _borrowToken = borrowToken;
        if (_borrowToken == NativeToken.NATIVE_TOKEN) {
            _borrowToken = WETH;
        }
        DataTypes.ReserveData memory reserveData = ILendingPool(LENDING_POOL).getReserveData(_borrowToken);
        if (interestRateMode == 1) {
            return reserveData.stableDebtTokenAddress;
        } else if (interestRateMode == 2) {
            return reserveData.variableDebtTokenAddress;
        }
    }

    function getCurrentBorrow() public view returns (uint256) {
        return IERC20(getDebtToken()).balanceOf(address(this));
    }

    function __initLendConfigation(
        uint256 _interestRateMode,
        address _collaternalToken,
        address _borrowToken
    ) internal {
        require(
            _interestRateMode == 1 || _interestRateMode == 2,
            "Invalid interest rate parameter"
        );
        interestRateMode = _interestRateMode;
        collaternalToken = _collaternalToken;
        borrowToken = _borrowToken;
    }

    function __addCollaternal(uint256 _collaternalAmount) internal {
        // saving gas
        address _collaternalToken = collaternalToken;
        if (_collaternalToken == NativeToken.NATIVE_TOKEN) {
            IWETHGateway(WETH_GATEWAY).depositETH{value: _collaternalAmount}(
                LENDING_POOL,
                address(this),
                0
            );
        } else {
            IERC20(_collaternalToken).approve(LENDING_POOL, _collaternalAmount);
            ILendingPool(LENDING_POOL).deposit(
                _collaternalToken,
                _collaternalAmount,
                address(this),
                0
            );
        }
    }

    function __removeCollaternal(uint256 _collaternalAmount) internal {
        // saving gas
        address _collaternalToken = collaternalToken;
        address _aCollaternalToken = getAToken(_collaternalToken);
        if (_collaternalToken == NativeToken.NATIVE_TOKEN) {
            IERC20(_aCollaternalToken).approve(WETH_GATEWAY, _collaternalAmount);
            IWETHGateway(WETH_GATEWAY).withdrawETH(
                LENDING_POOL,
                _collaternalAmount,
                address(this)
            );
        } else {
            IERC20(_aCollaternalToken).approve(LENDING_POOL, _collaternalAmount);
            ILendingPool(LENDING_POOL).withdraw(
                _collaternalToken,
                _collaternalAmount,
                address(this)
            );
        }
    }

    function __borrow(uint256 _borrowAmount) internal {
        if (borrowToken == NativeToken.NATIVE_TOKEN) {
            IWETHGateway(WETH_GATEWAY).borrowETH(LENDING_POOL, _borrowAmount, interestRateMode, 0);
        } else {
            ILendingPool(LENDING_POOL).borrow(
                borrowToken,
                _borrowAmount,
                interestRateMode,
                0,
                address(this)
            );
        }
    }

    function __repay(uint256 _repayAmount) internal {
        if (borrowToken == NativeToken.NATIVE_TOKEN) {
            IERC20(WETH).approve(LENDING_POOL,_repayAmount);
            IWETHGateway(WETH_GATEWAY).repayETH(
                LENDING_POOL,
                _repayAmount,
                interestRateMode,
                address(this)
            );
        } else {
            IERC20(borrowToken).approve(LENDING_POOL,_repayAmount);
            ILendingPool(LENDING_POOL).repay(
                borrowToken,
                _repayAmount,
                interestRateMode,
                address(this)
            );
        }
    }
}
