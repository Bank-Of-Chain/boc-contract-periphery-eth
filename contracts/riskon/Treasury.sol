// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import 'boc-contract-core/contracts/access-control/AccessControlMixin.sol';
import 'boc-contract-core/contracts/library/BocRoles.sol';

//contracts/exchanges/utils/ExchangeHelpers.sol
import 'boc-contract-core/contracts/library/NativeToken.sol';
import '../../library/RiskOnConstant.sol';
import './../external/uniswap/IUniswapV3.sol';
import './ITreasury.sol';
import '../external/riskon/IWMATIC.sol';


/// @title Treasury
/// @notice Treasury contract mainly used to keep the portion of profit transfered to treasury
/// @author Bank of Chain Protocol Inc
contract Treasury is
    ITreasury,
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlMixin
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // vault => token => total manage fee amount
    mapping(address => mapping(address => uint256)) public accManageFee;

    // vault => token => accumulate profitAmount
    mapping(address => mapping(address => uint256)) public accVaultProfit;

    // token => bool
    mapping(address => bool) public isReceivableToken;

    /// @notice The keeper to receive manage fee
    address payable public keeper;

    /// @notice The total Matic amount transfered to keeper
    uint256 public totalManageFeeInMainCoin2Keeper;

    /// @param _vault The vault with profits
    /// @param _token The fee token
    /// @param _feeAmount The fee amount
    event ReceiveManageFee(address indexed _vault, address indexed _token, uint256 _feeAmount);
    
    /// @param _vault The vault with profits
    /// @param _token The profit token
    /// @param _profitAmount The profit amount
    event ReceiveProfit(address indexed _vault, address indexed _token, uint256 _profitAmount);

    /// @param _newFlag The new flag
    event TakeProfitFlagChanged(bool _newFlag);

    /// @param _token The token set
    /// @param _newBool The new bool value
    event ReceiveTokenChanged(address indexed _token, bool _newBool);

    /// @notice Initialize
    /// @param _accessControlProxy The access control proxy address
    /// @param _receivableTokens,  The receivable tokens list
    /// @param _keeper The keeper address
    function initialize(
        address _accessControlProxy, 
        address[] memory _receivableTokens, 
        address payable _keeper
    ) public initializer {
        require(_receivableTokens.length > 0,'The len of _receivableTokens must GT 0');
        for(uint256 i = 0; i < _receivableTokens.length; i++) {
            isReceivableToken[_receivableTokens[i]]= true;
        }
        
        keeper = _keeper;
        _initAccessControl(_accessControlProxy);
    }

    receive() external payable {}

    fallback() external payable {}

    /// @notice Return the current version of this contract.
    function version() public pure returns (string memory) {
        return 'V1.0.0';
    }

    /// @inheritdoc ITreasury
    function balance(address _token) public view override returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    /// Requirements: only gov role can call
    /// @inheritdoc ITreasury
    function withdrawToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) external override onlyRole(BocRoles.GOV_ROLE) {
        require(_amount <= balance(_token), '!insufficient');
        IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
    }

    /// Requirements: only gov role can call
    /// @inheritdoc ITreasury
    function withdrawETH(address payable _receiver, uint256 _amount)
        external
        payable
        override
        nonReentrant
        onlyRole(BocRoles.GOV_ROLE)
    {
        require(_amount <= address(this).balance, '!insufficient');
        _receiver.transfer(_amount);
    }

    /// @inheritdoc ITreasury
    function receiveManageFeeFromVault(address _token, uint256 _feeAmount) external payable override{
        require(isReceivableToken[_token],'Not receivable token');

        uint256 amountOutMainCoin = 0;
        if(_token == NativeToken.NATIVE_TOKEN) {
            require(msg.value > 0,'Cannot transfer 0 ETH fee');
            amountOutMainCoin = msg.value;// _feeAmount in main coin
            accManageFee[msg.sender][_token] += amountOutMainCoin;
        } else if (_feeAmount > 0) {
            // receive manage fee
            IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _feeAmount);
            accManageFee[msg.sender][_token] += _feeAmount;
            emit ReceiveManageFee(msg.sender, _token, _feeAmount);

            // swap from `_token` to Matic, the recipient is keeper
            IERC20Upgradeable(_token).safeApprove(RiskOnConstant.UNISWAP_V3_ROUTER, 0);
            IERC20Upgradeable(_token).safeApprove(RiskOnConstant.UNISWAP_V3_ROUTER, _feeAmount);
            amountOutMainCoin = IUniswapV3(RiskOnConstant.UNISWAP_V3_ROUTER).exactInputSingle(
                IUniswapV3.ExactInputSingleParams(
                    _token, 
                    RiskOnConstant.WMATIC,//WMATIC on Polygon， WETH on Ethereum
                    500, // fee
                    address(this), 
                    block.timestamp, 
                    _feeAmount, 
                    0, 
                    0
                )
            );

            // withdraw wmatic to matic, then transfer matic to keeper
            IWMATIC(RiskOnConstant.WMATIC).withdraw(amountOutMainCoin); 
        }

        totalManageFeeInMainCoin2Keeper += amountOutMainCoin;

        // transfer main coin to keeper
        keeper.transfer(amountOutMainCoin);
    }
    
    /// @inheritdoc ITreasury
    function receiveProfitFromVault(address _token, uint256 _profitAmount) external payable override {
        require(isReceivableToken[_token],'Not receivable token');
        if(_token == NativeToken.NATIVE_TOKEN) {
            _profitAmount = msg.value;
        } else {
            IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _profitAmount);
        }
        
        accVaultProfit[msg.sender][_token] += _profitAmount;
        emit ReceiveProfit(msg.sender, _token, _profitAmount);
    }

    /// @notice Sets `_token` is receivable token or not
    /// @param _token The token set
    /// @param _newBool The new bool value
    /// Requirements: only governance role can call
    function setIsReceivableToken(address _token, bool _newBool) external onlyRole(BocRoles.GOV_ROLE) {
        isReceivableToken[_token] = _newBool;
        emit ReceiveTokenChanged(_token, _newBool);
    }
}
