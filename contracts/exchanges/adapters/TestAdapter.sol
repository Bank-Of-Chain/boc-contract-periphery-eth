// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "boc-contract-core/contracts/exchanges/IExchangeAdapter.sol";
import "boc-contract-core/contracts/price-feeds/IValueInterpreter.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "../../eth/oracle/IPriceOracleConsumer.sol";


contract MyTestAdapter is IExchangeAdapter {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address valueInterpreter;

    mapping(address => uint256)  public  supportedTokens;
    mapping(address => uint256)  public  tokensDecimals;
    uint256 vaultType = 0; // 0: USDi  1: ETHi

    constructor(address _valueInterpreter) {
        valueInterpreter = _valueInterpreter;
    }

    receive() external payable {}
    fallback() external payable {}

    function identifier() external pure override returns (string memory) {
        return "testAdapter";
    }

    function setParams( uint256 _vaultType, address _valueInterpreter) 
        external 
    {
        vaultType = _vaultType;
        valueInterpreter = _valueInterpreter;
    }

    function setPrice(address[] memory _tokens, uint256[] memory _prices, uint256[] memory _decimals) 
        external 
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            supportedTokens[_tokens[i]] = _prices[i];
            tokensDecimals[_tokens[i]] = _decimals[i];
        }
    }

    function clearPrice(address[] memory _tokens) 
        external
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
           supportedTokens[_tokens[i]] = 0;
        }
    }

    function getPrice(address[] memory _tokens) 
        external
        view 
        returns (uint256[] memory _prices) 
    {
        _prices = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _prices[i] = supportedTokens[_tokens[i]];
        }
    }

    function calcCanonicalAssetValue(address _srcToken, uint256 _srcAmount, address _dstToken) 
        internal 
        view 
        returns (uint256) 
    {
        uint256 _srcPrice = supportedTokens[_srcToken];
        uint256 _dstPrice = supportedTokens[_dstToken];
        
        if (_srcPrice > 0 && _dstPrice > 0){
            uint256 _dstAmount = _srcAmount;
            uint256 _dstDecimals = tokensDecimals[_dstToken];
            uint256 _srcDecimals = tokensDecimals[_srcToken];

            if (_dstDecimals > _srcDecimals){
                _dstAmount = _srcAmount * (10 ** (_dstDecimals - _srcDecimals));
            }
            else if(_dstDecimals < _srcDecimals){
                _dstAmount = _srcAmount / (10 ** (_srcDecimals - _dstDecimals));
            }
            return _dstAmount * _srcPrice / _dstPrice;
        }
        if (vaultType == 0){
            return IValueInterpreter(valueInterpreter).calcCanonicalAssetValue(_srcToken, _srcAmount, _dstToken);
        }
        return IPriceOracleConsumer(valueInterpreter).valueInTargetToken(_srcToken, _srcAmount, _dstToken);
    }

    function swap(
        uint8 _method,
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) external payable override returns (uint256) {

        uint256 _amount = calcCanonicalAssetValue(
            _sd.srcToken,
            _sd.amount,
            _sd.dstToken
        );
        // Mock exchange
        uint256 _expectAmount = (_amount * 1000) / 1000;

        if (_sd.dstToken == NativeToken.NATIVE_TOKEN) {
            payable(_sd.receiver).transfer(_expectAmount);
        } else {
            IERC20Upgradeable(_sd.dstToken).safeTransfer(_sd.receiver, _expectAmount);
        }
        return _expectAmount;
    }
}