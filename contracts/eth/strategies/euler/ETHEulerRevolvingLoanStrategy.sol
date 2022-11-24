// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../ETHBaseStrategy.sol";

import "./../../enums/ProtocolEnum.sol";
import "../../../external/euler/IEulDistributor.sol";
import "../../../external/euler/IEulerDToken.sol";
import "../../../external/euler/IEulerEToken.sol";
import "../../../external/euler/IEulerMarkets.sol";
import "../../../external/uniswap/IUniswapV2Router2.sol";
import "../../../external/uniswap/IUniswapV3.sol";

/// @title ETHEulerRevolvingLoanStrategy
/// @notice Investment strategy of investing in WETH/WstETH and revolving lending through post-staking via EulerRevolvingLoan
/// @author Bank of Chain Protocol Inc
contract ETHEulerRevolvingLoanStrategy is ETHBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @param tokenIn The token address of in
    /// @param tokenOut The token address of out
    /// @param fee The fee of exchange
    struct UniswapV3Params {
        address tokenIn;
        address tokenOut;
        uint24 fee;
    }

    address internal constant EULER_ADDRESS = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    address internal constant EULER_MARKETS = 0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3;
    address internal constant EUL = 0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b;
    address internal constant EUL_DISTRIBUTOR = 0xd524E29E3BAF5BB085403Ca5665301E94387A7e2;
    address internal constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address public constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant BPS = 10000;

    address public eToken;
    address public dToken;

    uint256 public borrowFactor;
    uint256 public borrowFactorMax;
    uint256 public borrowFactorMin;
    uint256 public borrowCount;
    uint256 public leverage;
    uint256 public leverageMax;
    uint256 public leverageMin;

    mapping(address => UniswapV3Params) public swapRewardRoutes;

    /// @param _borrowFactor The new borrow factor
    event UpdateBorrowFactor(uint256 _borrowFactor);
    /// @param _borrowFactorMax The new max borrow factor
    event UpdateBorrowFactorMax(uint256 _borrowFactorMax);
    /// @param _borrowFactorMin The new min borrow factor
    event UpdateBorrowFactorMin(uint256 _borrowFactorMin);
    /// @param _borrowCount The new count Of borrow
    event UpdateBorrowCount(uint256 _borrowCount);
    /// @param _remainingAmount The amount of aToken will still be used as collateral to borrow eth
    /// @param _overflowAmount The amount of debt token that exceeds the maximum allowable loan
    event Rebalance(uint256 _remainingAmount, uint256 _overflowAmount);
    /// @param _strategy The strategy for reporting
    /// @param _gain The gain in ETH units for this report
    /// @param _loss The loss in ETH units for this report
    /// @param _lastStrategyTotalDebt The total debt of `_strategy` for last report
    /// @param _nowStrategyTotalDebt The total debt of `_strategy` for this report
    /// @param _rewardTokens The reward token list
    /// @param _claimAmounts The amount list of `_rewardTokens`
    event StrategyClaimReported(
        address indexed _strategy,
        uint256 _gain,
        uint256 _loss,
        uint256 _lastStrategyTotalDebt,
        uint256 _nowStrategyTotalDebt,
        address[] _rewardTokens,
        uint256[] _claimAmounts
    );

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _name The name of strategy
    /// @param _underlyingToken The lending asset of the Vault contract
    function initialize(
        address _vault,
        string memory _name,
        address _underlyingToken,
        uint256 _borrowFactor,
        uint256 _borrowFactorMax,
        uint256 _borrowFactorMin
    ) external initializer {
        borrowCount = 10;
        borrowFactor = _borrowFactor;
        borrowFactorMax = _borrowFactorMax;
        borrowFactorMin = _borrowFactorMin;
        leverage = _calLeverage(_borrowFactor, 10000, 10);
        leverageMax = _calLeverage(_borrowFactorMax, 10000, 10);
        leverageMin = _calLeverage(_borrowFactorMin, 10000, 10);

        address[] memory _wants = new address[](1);
        _wants[0] = _underlyingToken;

        IEulerMarkets eIEulerMarkets = IEulerMarkets(EULER_MARKETS);
        address _eToken = eIEulerMarkets.underlyingToEToken(_underlyingToken);
        eToken = _eToken;
        address _dToken = eIEulerMarkets.underlyingToDToken(_underlyingToken);
        dToken = _dToken;

        //set up sell reward path
        address _eul = EUL;
        address _weth = W_ETH;
        swapRewardRoutes[_eul] = UniswapV3Params({
            tokenIn: _eul,
            tokenOut: _weth,
            fee: uint24(10000)
        });
        swapRewardRoutes[_wants[0]] = UniswapV3Params({
            tokenIn: _weth,
            tokenOut: _wants[0],
            fee: uint24(500)
        });

        super._initialize(_vault, uint16(ProtocolEnum.Euler), _name, _wants);
        IERC20Upgradeable(_underlyingToken).safeApprove(EULER_ADDRESS, type(uint256).max);
        IERC20Upgradeable(EUL).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        if (_underlyingToken != W_ETH) {
            IERC20Upgradeable(W_ETH).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
        }
    }

    /// @notice Sets the path of swap from reward token
    /// @param _token The reward token or  want token
    /// @param _tokenIn The token address of in
    /// @param _tokenOut The token address of out
    /// @param _fee The fee of exchange
    /// Requirements: only vault manager can call
    function setRewardSwapPath(
        address _token,
        address _tokenIn,
        address _tokenOut,
        uint24 _fee
    ) external isVaultManager {
        swapRewardRoutes[_token] = UniswapV3Params({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee
        });
        IERC20Upgradeable(_tokenIn).safeApprove(UNISWAP_V3_ROUTER, 0);
        IERC20Upgradeable(_tokenIn).safeApprove(UNISWAP_V3_ROUTER, type(uint256).max);
    }

    /// @notice Sets `_borrowFactor` to `borrowFactor`
    /// @param _borrowFactor The new value of `borrowFactor`
    /// Requirements: only vault manager can call
    function setBorrowFactor(uint256 _borrowFactor) external isVaultManager {
        require(
            _borrowFactor < BPS &&
                _borrowFactor >= borrowFactorMin &&
                _borrowFactor <= borrowFactorMax,
            "setting output the range"
        );
        borrowFactor = _borrowFactor;
        leverage = _getNewLeverage(_borrowFactor);

        emit UpdateBorrowFactor(_borrowFactor);
    }

    /// @notice Sets `_borrowFactorMax` to `borrowFactorMax`
    /// @param _borrowFactorMax The new value of `borrowFactorMax`
    /// Requirements: only vault manager can call
    function setBorrowFactorMax(uint256 _borrowFactorMax) external isVaultManager {
        require(
            _borrowFactorMax < BPS && _borrowFactorMax > borrowFactor,
            "setting output the range"
        );
        borrowFactorMax = _borrowFactorMax;
        leverageMax = _getNewLeverage(_borrowFactorMax);

        emit UpdateBorrowFactorMax(_borrowFactorMax);
    }

    /// @notice Sets `_borrowFactorMin` to `borrowFactorMin`
    /// @param _borrowFactorMin The new value of `borrowFactorMin`
    /// Requirements: only vault manager can call
    function setBorrowFactorMin(uint256 _borrowFactorMin) external isVaultManager {
        require(
            _borrowFactorMin < BPS && _borrowFactorMin < borrowFactor,
            "setting output the range"
        );
        borrowFactorMin = _borrowFactorMin;
        leverageMin = _getNewLeverage(_borrowFactorMin);

        emit UpdateBorrowFactorMin(_borrowFactorMin);
    }

    /// @notice Sets `_borrowCount` to `borrowCount`
    /// @param _borrowCount The new value of `borrowCount`
    /// Requirements: only keeper can call
    function setBorrowCount(uint256 _borrowCount) external isKeeper {
        require(_borrowCount <= 20, "setting output the range");
        borrowCount = _borrowCount;
        _updateAllLeverage(_borrowCount);
        emit UpdateBorrowCount(_borrowCount);
    }

    /// @notice Return the version of strategy
    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc ETHBaseStrategy
    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
    }

    /// @inheritdoc ETHBaseStrategy
    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](1);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = wants;
    }

    /// @inheritdoc ETHBaseStrategy
    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        )
    {
        _tokens = wants;
        _amounts = new uint256[](1);
        _amounts[0] =
            IEulerEToken(eToken).balanceOfUnderlying(address(this)) +
            balanceOfToken(_tokens[0]) -
            IEulerDToken(dToken).balanceOf(address(this));
    }

    /// @inheritdoc ETHBaseStrategy
    function get3rdPoolAssets() external view override returns (uint256) {
        uint256 _iTokenTotalSupply = IEulerEToken(eToken).totalSupplyUnderlying();
        return _iTokenTotalSupply != 0 ? queryTokenValueInETH(wants[0], _iTokenTotalSupply) : 0;
    }

    /// @inheritdoc ETHBaseStrategy
    function harvest()
        public
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        (_rewardsTokens, _claimAmounts) = _claimRewardsAndReInvest();
        vault.report(_rewardsTokens, _claimAmounts);
    }

    /// @notice Rebalance the collateral of this strategy
    /// Requirements: only keeper can call
    function rebalance() external isKeeper {
        address _eToken = eToken;
        (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowInfo(
            _eToken,
            dToken,
            borrowCount
        );
        _rebalance(_remainingAmount, _overflowAmount, _eToken);
    }

    /// @notice Returns the info of borrow.
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow
    /// @return _overflowAmount The amount of aToken that exceeds the maximum allowable loan
    function borrowInfo() public view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        (_remainingAmount, _overflowAmount) = _borrowInfo(eToken, dToken, borrowCount);
    }

    /// @inheritdoc ETHBaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        uint256 _amount = _amounts[0];
        if (_amount > 0) {
            address _eToken = eToken;
            IEulerEToken(_eToken).deposit(0, _amount);
            IEulerMarkets(EULER_MARKETS).enterMarket(0, _assets[0]);
            (uint256 _remainingAmount, uint256 _overflowAmount) = _borrowStandardInfo(
                _eToken,
                dToken,
                borrowCount
            );
            _rebalance(_remainingAmount, _overflowAmount, _eToken);
        }
    }

    /// @inheritdoc ETHBaseStrategy
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        address _eToken = eToken;
        address _dToken = dToken;
        uint256 _collateralAmount = IEulerEToken(_eToken).balanceOfUnderlying(address(this));
        uint256 _redeemAmount = (_collateralAmount * _withdrawShares) / _totalShares;
        uint256 _debtAmount = IEulerDToken(_dToken).balanceOf(address(this));
        uint256 _repayBorrowAmount = (_debtAmount * _withdrawShares) / _totalShares;
        if (_redeemAmount > 0) {
            uint256 _leverage = leverage;
            uint256 _newDebtAmount = (_debtAmount - _repayBorrowAmount) * _leverage;
            uint256 _newCollateralAmount = (_collateralAmount - _redeemAmount) * (_leverage - BPS);
            if (_newDebtAmount > _newCollateralAmount) {
                uint256 _decreaseAmount = (_newDebtAmount - _newCollateralAmount) / BPS;
                _redeemAmount = _redeemAmount + _decreaseAmount;
                _repayBorrowAmount = _repayBorrowAmount + _decreaseAmount;
            } else {
                uint256 _increaseAmount = (_newCollateralAmount - _newDebtAmount) / BPS;
                _redeemAmount = _redeemAmount - _increaseAmount;
                _repayBorrowAmount = _repayBorrowAmount - _increaseAmount;
            }
            _repay(_redeemAmount, _repayBorrowAmount, _eToken);
        }
    }

    /// @notice Claim distributed tokens
    /// @param _account Address that should receive tokens
    /// @param _token Address of token being claimed (ie EUL)
    /// @param _proof Merkle proof that validates this claim
    /// @param _stake If non-zero, then the address of a token to auto-stake to, instead of claiming
    /// @return _claimAmount claimed amount
    function claim(
        address _account,
        address _token,
        uint256 _claimable,
        bytes32[] calldata _proof,
        address _stake
    ) external returns (uint256 _claimAmount) {
        uint256 _beforeBalance = IERC20Upgradeable(_token).balanceOf(_account);
        IEulDistributor(EUL_DISTRIBUTOR).claim(_account, _token, _claimable, _proof, _stake);
        uint256 _balanceOfEUL = IERC20Upgradeable(_token).balanceOf(_account);
        _claimAmount = _balanceOfEUL - _beforeBalance;
        if (_account == address(this) && _balanceOfEUL > 0 && _token == EUL) {
            sellRewardAndTransferToVault();
        }
        return _claimAmount;
    }

    /// @notice sell claim reward to usdc and transfer to vault
    function sellRewardAndTransferToVault() public {
        address _eulToken = EUL;
        uint256 _balanceOfEUL = balanceOfToken(_eulToken);
        (address[] memory _tokens, uint256[] memory _amounts, , ) = getPositionDetail();
        uint256 _assetsInETH = queryTokenValueInETH(_tokens[0], _amounts[0]);
        if (_assetsInETH < 1e10 && _balanceOfEUL > 0) {
            address[] memory _rewardTokens = new address[](1);
            _rewardTokens[0] = _eulToken;
            uint256[] memory _claimAmounts = new uint256[](1);
            _claimAmounts[0] = _balanceOfEUL;
            address[] memory _wantTokens = new address[](1);
            UniswapV3Params memory _eulUniswapV3Params = swapRewardRoutes[_rewardTokens[0]];
            _wantTokens[0] = _eulUniswapV3Params.tokenOut;
            uint256[] memory _wantAmounts = new uint256[](1);
            _wantAmounts[0] = swapRewardsToWants(_balanceOfEUL, _rewardTokens[0], _wantTokens[0]);

            transferTokensToTarget(address(vault), _wantTokens, _wantAmounts);

            emit StrategyClaimReported(
                address(this),
                uint256(0),
                uint256(0),
                _assetsInETH,
                _assetsInETH,
                _rewardTokens,
                _claimAmounts
            );
        }
    }

    /// @notice sell claim reward to want token
    function swapRewardsToWants(
        uint256 _balanceOfEUL,
        address _rewardToken,
        address _wantToken
    ) internal returns (uint256) {
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = _rewardToken;
        uint256[] memory _claimAmounts = new uint256[](1);
        _claimAmounts[0] = _balanceOfEUL;
        address[] memory _wantTokens = new address[](1);
        _wantTokens[0] = _wantToken;
        uint256[] memory _wantAmounts = new uint256[](1);
        UniswapV3Params memory _eulUniswapV3Params = swapRewardRoutes[_rewardTokens[0]];
        IUniswapV3 _uniswapv3Pool = IUniswapV3(UNISWAP_V3_ROUTER);
        // swap from EUL to W_ETH by uinswap v3 1% fee
        _uniswapv3Pool.exactInputSingle(
            IUniswapV3.ExactInputSingleParams(
                _eulUniswapV3Params.tokenIn,
                _eulUniswapV3Params.tokenOut,
                _eulUniswapV3Params.fee,
                address(this),
                block.timestamp,
                _balanceOfEUL,
                0,
                0
            )
        );
        if (_wantTokens[0] != _eulUniswapV3Params.tokenOut) {
            UniswapV3Params memory _wantUniswapV3Params = swapRewardRoutes[_wantTokens[0]];
            _uniswapv3Pool.exactInputSingle(
                IUniswapV3.ExactInputSingleParams(
                    _wantUniswapV3Params.tokenIn,
                    _wantUniswapV3Params.tokenOut,
                    _wantUniswapV3Params.fee,
                    address(this),
                    block.timestamp,
                    balanceOfToken(_eulUniswapV3Params.tokenOut),
                    0,
                    0
                )
            );
        }

        _wantAmounts[0] = balanceOfToken(_wantTokens[0]);
        emit SwapRewardsToWants(
            address(this),
            _rewardTokens,
            _claimAmounts,
            _wantTokens,
            _wantAmounts
        );
        return _wantAmounts[0];
    }

    /// @notice Collect the rewards from third party protocol,then swap from the reward tokens to wanted tokens and reInvest
    /// @return _rewardTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function _claimRewardsAndReInvest()
        internal
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        _rewardTokens = new address[](1);
        _rewardTokens[0] = EUL;
        _claimAmounts = new uint256[](1);
        uint256 _balanceOfEUL = balanceOfToken(_rewardTokens[0]);
        _claimAmounts[0] = _balanceOfEUL;
        if (_balanceOfEUL > 0) {
            uint256 _wantAmount = swapRewardsToWants(_balanceOfEUL, _rewardTokens[0], wants[0]);
            if (_wantAmount > 0) {
                IEulerEToken(eToken).deposit(0, _wantAmount);
            }
        }
    }

    /// @notice repayBorrow and redeem collateral
    function _repay(
        uint256 _redeemAmount,
        uint256 _repayBorrowAmount,
        address _eToken
    ) internal {
        if (_redeemAmount > _repayBorrowAmount) {
            if (_repayBorrowAmount > 0) {
                IEulerEToken(_eToken).burn(0, _repayBorrowAmount);
            }
            uint256 _withdrawAmount = _redeemAmount - _repayBorrowAmount;
            uint256 _withdrawAmountInternal = IEulerEToken(_eToken).convertUnderlyingToBalance(
                _withdrawAmount
            );
            // fix e/insufficient-balance error
            // amountInternal use underlyingAmountToBalanceRoundUp cal ,sometime will gt balance
            // code at https://etherscan.io/address/0xbb0d4bb654a21054af95456a3b29c63e8d1f4c0a#code
            if (IEulerEToken(_eToken).balanceOf(address(this)) <= _withdrawAmountInternal) {
                IEulerEToken(_eToken).withdraw(0, type(uint256).max);
            } else {
                IEulerEToken(_eToken).withdraw(0, _withdrawAmount);
            }
        } else {
            IEulerEToken(_eToken).burn(0, _redeemAmount);
        }
    }

    /// @notice Rebalance the collateral of this strategy
    function _rebalance(
        uint256 _remainingAmount,
        uint256 _overflowAmount,
        address _eToken
    ) internal {
        if (_remainingAmount > 0) {
            IEulerEToken(_eToken).mint(0, _remainingAmount);
        } else if (_overflowAmount > 0) {
            _repay(_overflowAmount, _overflowAmount, _eToken);
        }
        if (_remainingAmount + _overflowAmount > 0) {
            emit Rebalance(_remainingAmount, _overflowAmount);
        }
    }

    /// @notice Returns the info of borrow.
    /// @dev _needCollateralAmount = (_debtAmount * _leverage) / (_leverage - BPS);
    /// _debtAmount_now / _needCollateralAmount = （_leverage - 10000) / _leverage;
    /// _leverage = (capitalAmount + _debtAmount_now) *10000 / capitalAmount;
    /// _debtAmount_now = capitalAmount * (_leverage - 10000)
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow eth
    /// @return _overflowAmount The amount of debt token that exceeds the maximum allowable loan
    function _borrowInfo(
        address _eToken,
        address _dToken,
        uint256 _borrowCount
    ) private view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        if (_borrowCount == 0) {
            _overflowAmount = IEulerDToken(_dToken).balanceOf(address(this));
        } else {
            uint256 _debtAmount = IEulerDToken(_dToken).balanceOf(address(this));
            uint256 _collateralAmount = IEulerEToken(_eToken).balanceOfUnderlying(address(this));
            uint256 _capitalAmount = _collateralAmount - _debtAmount;

            uint256 _BPS = BPS;
            uint256 _needCollateralAmount = (_capitalAmount * leverage) / _BPS;
            uint256 _needCollateralAmountMin = (_capitalAmount * leverageMin) / _BPS;
            uint256 _needCollateralAmountMax = (_capitalAmount * leverageMax) / _BPS;
            if (_needCollateralAmountMin > _collateralAmount) {
                _remainingAmount = _needCollateralAmount - _collateralAmount;
            } else if (_needCollateralAmountMax < _collateralAmount) {
                _overflowAmount = _collateralAmount - _needCollateralAmount;
            }
        }
    }

    /// @notice Returns the info of borrow with default borrowFactor
    /// @return _remainingAmount The amount of aToken will still be used as collateral to borrow
    /// @return _overflowAmount The amount of debt token that exceeds the maximum allowable loan
    function _borrowStandardInfo(
        address _eToken,
        address _dToken,
        uint256 _borrowCount
    ) private view returns (uint256 _remainingAmount, uint256 _overflowAmount) {
        if (_borrowCount == 0) {
            _overflowAmount = IEulerDToken(_dToken).balanceOf(address(this));
        } else {
            uint256 _debtAmount = IEulerDToken(_dToken).balanceOf(address(this));
            uint256 _collateralAmount = IEulerEToken(_eToken).balanceOfUnderlying(address(this));
            uint256 _capitalAmount = _collateralAmount - _debtAmount;
            uint256 _needCollateralAmount = (_capitalAmount * leverage) / BPS;
            if (_needCollateralAmount > _collateralAmount) {
                _remainingAmount = _needCollateralAmount - _collateralAmount;
            } else if (_needCollateralAmount < _collateralAmount) {
                _overflowAmount = _collateralAmount - _needCollateralAmount;
            }
        }
    }

    /// @notice Returns the new leverage with the fix borrowFactor
    /// @return _borrowFactor The borrow factor
    function _getNewLeverage(uint256 _borrowFactor) internal view returns (uint256) {
        return _calLeverage(_borrowFactor, BPS, borrowCount);
    }

    /// @notice update all leverage (leverage leverageMax leverageMin)
    function _updateAllLeverage(uint256 _borrowCount) internal {
        uint256 _bps = BPS;
        leverage = _calLeverage(borrowFactor, _bps, _borrowCount);
        leverageMax = _calLeverage(borrowFactorMax, _bps, _borrowCount);
        leverageMin = _calLeverage(borrowFactorMin, _bps, _borrowCount);
    }

    /// @notice Returns the leverage  with by _borrowFactor _bps  _borrowCount
    /// @return _borrowFactor The borrow factor
    function _calLeverage(
        uint256 _borrowFactor,
        uint256 _bps,
        uint256 _borrowCount
    ) private pure returns (uint256) {
        // q = borrowFactor/bps
        // n = borrowCount + 1;
        // _leverage = (1-q^n)/(1-q),(n>=1, q=0.8)
        uint256 _leverage = _bps;
        if (_borrowCount >= 1) {
            _leverage =
                (_bps * _bps - (_borrowFactor**(_borrowCount + 1)) / (_bps**(_borrowCount - 1))) /
                (_bps - _borrowFactor);
        }
        return _leverage;
    }
}
