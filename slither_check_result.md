Summary
 - [name-reused](#name-reused) (5 results) (High)
 - [shadowing-state](#shadowing-state) (4 results) (High)
 - [uninitialized-state](#uninitialized-state) (17 results) (High)
 - [arbitrary-send](#arbitrary-send) (14 results) (High)
 - [reentrancy-eth](#reentrancy-eth) (2 results) (High)
 - [unchecked-transfer](#unchecked-transfer) (11 results) (High)
 - [incorrect-equality](#incorrect-equality) (20 results) (Medium)
 - [locked-ether](#locked-ether) (1 results) (Medium)
 - [divide-before-multiply](#divide-before-multiply) (47 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (28 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (36 results) (Medium)
 - [unused-return](#unused-return) (131 results) (Medium)
## name-reused
Impact: High
Confidence: High
 - [ ] ID-0
MockUniswapV3Router is re-used:
	- [MockUniswapV3Router](contracts/eth/mock/MockUniswapV3Router.sol#L16-L74)
	- [MockUniswapV3Router](contracts/usd/mock/MockUniswapV3Router.sol#L16-L74)

contracts/eth/mock/MockUniswapV3Router.sol#L16-L74


 - [ ] ID-1
ICurveMini is re-used:
	- [ICurveMini](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L22-L60)
	- [ICurveMini](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L22-L29)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L22-L60


 - [ ] ID-2
ConvexBaseStrategy is re-used:
	- [ConvexBaseStrategy](contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L11-L116)
	- [ConvexBaseStrategy](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L11-L97)

contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L11-L116


 - [ ] ID-3
MockVault is re-used:
	- [MockVault](contracts/eth/mock/MockVault.sol#L12-L76)
	- [MockVault](contracts/usd/mock/MockVault.sol#L10-L47)

contracts/eth/mock/MockVault.sol#L12-L76


 - [ ] ID-4
AggregatorInterface is re-used:
	- [AggregatorInterface](contracts/eth/mock/MockPriceOracleConsumer.sol#L14-L24)
	- [AggregatorInterface](contracts/eth/oracle/PriceOracleConsumer.sol#L14-L24)

contracts/eth/mock/MockPriceOracleConsumer.sol#L14-L24


## shadowing-state
Impact: High
Confidence: High
 - [ ] ID-5
[ConvexSusdStrategy.CVX](contracts/usd/strategies/convex/ConvexSusdStrategy.sol#L16) shadows:
	- [ConvexBaseStrategy.CVX](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L17)

contracts/usd/strategies/convex/ConvexSusdStrategy.sol#L16


 - [ ] ID-6
[ConvexSaaveStrategy.CVX](contracts/usd/strategies/convex/ConvexSaaveStrategy.sol#L15) shadows:
	- [ConvexBaseStrategy.CVX](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L17)

contracts/usd/strategies/convex/ConvexSaaveStrategy.sol#L15


 - [ ] ID-7
[ConvexSusdStrategy.CRV](contracts/usd/strategies/convex/ConvexSusdStrategy.sol#L15) shadows:
	- [ConvexBaseStrategy.CRV](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L16)

contracts/usd/strategies/convex/ConvexSusdStrategy.sol#L15


 - [ ] ID-8
[ConvexSaaveStrategy.CRV](contracts/usd/strategies/convex/ConvexSaaveStrategy.sol#L14) shadows:
	- [ConvexBaseStrategy.CRV](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L16)

contracts/usd/strategies/convex/ConvexSaaveStrategy.sol#L14


## uninitialized-state
Impact: High
Confidence: High
 - [ ] ID-9
[ETHVaultStorage.priceProvider](contracts/eth/vault/ETHVaultStorage.sol#L150) is never initialized. It is used in:
	- [ETHVaultAdmin.addAsset(address)](contracts/eth/vault/ETHVaultAdmin.sol#L157-L165)

contracts/eth/vault/ETHVaultStorage.sol#L150


 - [ ] ID-10
[VaultStorage.pegTokenAddress](node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L163) is never initialized. It is used in:
	- [Vault.burn(uint256,address,uint256,bool,IExchangeAggregator.ExchangeToken[])](node_modules/boc-contract-core/contracts/vault/Vault.sol#L185-L237)
	- [Vault.startAdjustPosition()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L353-L392)
	- [Vault.endAdjustPosition()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L395-L511)
	- [Vault._repayFromVaultBuffer(uint256,address[],uint256[],uint256[],uint256,uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L674-L726)
	- [Vault._replayToVault(uint256,uint256,address[],uint256[],uint256[])](node_modules/boc-contract-core/contracts/vault/Vault.sol#L894-L941)
	- [Vault._burnRebaseAndEmit(address,uint256,uint256,uint256,address[],uint256[],address[],uint256[],uint256[])](node_modules/boc-contract-core/contracts/vault/Vault.sol#L984-L1006)
	- [Vault._rebase(uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1013-L1016)
	- [Vault._rebase(uint256,uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1018-L1053)

node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L163


 - [ ] ID-11
[ETHVaultStorage.withdrawQueue](contracts/eth/vault/ETHVaultStorage.sol#L157) is never initialized. It is used in:
	- [ETHVault._repayFromWithdrawQueue(uint256)](contracts/eth/vault/ETHVault.sol#L642-L690)

contracts/eth/vault/ETHVaultStorage.sol#L157


 - [ ] ID-12
[ETHVaultStorage.vaultBufferAddress](contracts/eth/vault/ETHVaultStorage.sol#L168) is never initialized. It is used in:
	- [ETHVault.mint(address,uint256,uint256)](contracts/eth/vault/ETHVault.sol#L164-L183)
	- [ETHVault.startAdjustPosition()](contracts/eth/vault/ETHVault.sol#L361-L412)
	- [ETHVault.endAdjustPosition()](contracts/eth/vault/ETHVault.sol#L415-L537)
	- [ETHVault._calculateVault(address[],bool)](contracts/eth/vault/ETHVault.sol#L539-L571)
	- [ETHVault._totalAssetInVaultAndVaultBuffer()](contracts/eth/vault/ETHVault.sol#L603-L621)
	- [ETHVault._estimateMint(address,uint256)](contracts/eth/vault/ETHVault.sol#L623-L639)
	- [ETHVault._repayFromVaultBuffer(uint256,address[],uint256[],uint256[],uint256,uint256)](contracts/eth/vault/ETHVault.sol#L693-L748)

contracts/eth/vault/ETHVaultStorage.sol#L168


 - [ ] ID-13
[VaultStorage.trusteeFeeBps](node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L140) is never initialized. It is used in:
	- [Vault._rebase(uint256,uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1018-L1053)

node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L140


 - [ ] ID-14
[VaultStorage.vaultBufferAddress](node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L161) is never initialized. It is used in:
	- [Vault.mint(address[],uint256[],uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L161-L179)
	- [Vault.startAdjustPosition()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L353-L392)
	- [Vault.endAdjustPosition()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L395-L511)
	- [Vault._calculateVault(address[],bool)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L513-L545)
	- [Vault._totalAssetInVaultAndVaultBuffer()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L580-L597)
	- [Vault._repayFromVaultBuffer(uint256,address[],uint256[],uint256[],uint256,uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L674-L726)
	- [Vault._checkMintAssets(address[],uint256[])](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1249-L1262)

node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L161


 - [ ] ID-15
[ETHVaultStorage.trusteeFeeBps](contracts/eth/vault/ETHVaultStorage.sol#L142) is never initialized. It is used in:
	- [ETHVault._rebase(uint256,uint256)](contracts/eth/vault/ETHVault.sol#L977-L1015)

contracts/eth/vault/ETHVaultStorage.sol#L142


 - [ ] ID-16
[VaultStorage.emergencyShutdown](node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L132) is never initialized. It is used in:

node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L132


 - [ ] ID-17
[VaultStorage.minimumInvestmentAmount](node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L177) is never initialized. It is used in:
	- [Vault._estimateMint(address[],uint256[])](node_modules/boc-contract-core/contracts/vault/Vault.sol#L599-L620)

node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L177


 - [ ] ID-18
[ETHVaultStorage.minimumInvestmentAmount](contracts/eth/vault/ETHVaultStorage.sol#L186) is never initialized. It is used in:
	- [ETHVault._estimateMint(address,uint256)](contracts/eth/vault/ETHVault.sol#L623-L639)

contracts/eth/vault/ETHVaultStorage.sol#L186


 - [ ] ID-19
[ETHVaultStorage.pegTokenAddress](contracts/eth/vault/ETHVaultStorage.sol#L170) is never initialized. It is used in:
	- [ETHVault.burn(uint256,uint256)](contracts/eth/vault/ETHVault.sol#L188-L227)
	- [ETHVault.startAdjustPosition()](contracts/eth/vault/ETHVault.sol#L361-L412)
	- [ETHVault.endAdjustPosition()](contracts/eth/vault/ETHVault.sol#L415-L537)
	- [ETHVault._repayFromVaultBuffer(uint256,address[],uint256[],uint256[],uint256,uint256)](contracts/eth/vault/ETHVault.sol#L693-L748)
	- [ETHVault._replayToVault(uint256,uint256,address[],uint256[],uint256[])](contracts/eth/vault/ETHVault.sol#L856-L907)
	- [ETHVault._burnRebaseAndEmit(uint256,uint256,uint256,address[],uint256[],address[],uint256[],uint256[])](contracts/eth/vault/ETHVault.sol#L940-L965)
	- [ETHVault._rebase(uint256)](contracts/eth/vault/ETHVault.sol#L972-L975)
	- [ETHVault._rebase(uint256,uint256)](contracts/eth/vault/ETHVault.sol#L977-L1015)

contracts/eth/vault/ETHVaultStorage.sol#L170


 - [ ] ID-20
[VaultStorage.valueInterpreter](node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L148) is never initialized. It is used in:
	- [VaultAdmin.addAsset(address)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L137-L146)

node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L148


 - [ ] ID-21
[ETHVaultStorage.emergencyShutdown](contracts/eth/vault/ETHVaultStorage.sol#L139) is never initialized. It is used in:

contracts/eth/vault/ETHVaultStorage.sol#L139


 - [ ] ID-22
[ETHVaultStorage.rebasePaused](contracts/eth/vault/ETHVaultStorage.sol#L163) is never initialized. It is used in:
	- [ETHVault.startAdjustPosition()](contracts/eth/vault/ETHVault.sol#L361-L412)
	- [ETHVault.endAdjustPosition()](contracts/eth/vault/ETHVault.sol#L415-L537)
	- [ETHVault._burnRebaseAndEmit(uint256,uint256,uint256,address[],uint256[],address[],uint256[],uint256[])](contracts/eth/vault/ETHVault.sol#L940-L965)

contracts/eth/vault/ETHVaultStorage.sol#L163


 - [ ] ID-23
[VaultStorage.trackedAssetDecimalsMap](node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L127) is never initialized. It is used in:
	- [Vault._totalAssetInVaultAndVaultBuffer()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L580-L597)
	- [Vault._estimateMint(address[],uint256[])](node_modules/boc-contract-core/contracts/vault/Vault.sol#L599-L620)
	- [Vault._getAssetDecimals(uint256[],uint256,address)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1210-L1221)

node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L127


 - [ ] ID-24
[ETHVaultStorage.redeemFeeBps](contracts/eth/vault/ETHVaultStorage.sol#L144) is never initialized. It is used in:
	- [ETHVault._replayToVault(uint256,uint256,address[],uint256[],uint256[])](contracts/eth/vault/ETHVault.sol#L856-L907)

contracts/eth/vault/ETHVaultStorage.sol#L144


 - [ ] ID-25
[VaultStorage.withdrawQueue](node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L155) is never initialized. It is used in:
	- [Vault._repayFromWithdrawQueue(uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L623-L671)

node_modules/boc-contract-core/contracts/vault/VaultStorage.sol#L155


## arbitrary-send
Impact: High
Confidence: Medium
 - [ ] ID-26
[ParaSwapV5Adapter.swapOnUniswapV2Fork(bytes,IExchangeAdapter.SwapDescription)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L215-L242) sends eth to arbitrary user
	Dangerous calls:
	- [address(_sd.receiver).transfer(_amount)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L240)

contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L215-L242


 - [ ] ID-27
[ParaSwapV5Adapter.swapOnUniswapFork(bytes,IExchangeAdapter.SwapDescription)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L182-L213) sends eth to arbitrary user
	Dangerous calls:
	- [address(_sd.receiver).transfer(_amount)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L211)

contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L182-L213


 - [ ] ID-28
[OneInchV4Adapter.swap(uint8,bytes,IExchangeAdapter.SwapDescription)](contracts/exchanges/adapters/OneInchV4Adapter.sol#L29-L59) sends eth to arbitrary user
	Dangerous calls:
	- [address(_sd.receiver).transfer(_exchangeAmount)](contracts/exchanges/adapters/OneInchV4Adapter.sol#L56)

contracts/exchanges/adapters/OneInchV4Adapter.sol#L29-L59


 - [ ] ID-29
[ParaSwapV5Adapter.swapOnZeroXv2(bytes,IExchangeAdapter.SwapDescription)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L244-L275) sends eth to arbitrary user
	Dangerous calls:
	- [address(_sd.receiver).transfer(_amount)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L273)

contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L244-L275


 - [ ] ID-30
[ParaSwapV5Adapter.swapOnZeroXv4(bytes,IExchangeAdapter.SwapDescription)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L277-L307) sends eth to arbitrary user
	Dangerous calls:
	- [address(_sd.receiver).transfer(_amount)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L305)

contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L277-L307


 - [ ] ID-31
[ParaSwapV5Adapter.swapOnUniswap(bytes,IExchangeAdapter.SwapDescription)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L158-L180) sends eth to arbitrary user
	Dangerous calls:
	- [address(_sd.receiver).transfer(_amount)](contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L177)

contracts/exchanges/adapters/ParaSwapV5Adapter.sol#L158-L180


 - [ ] ID-32
[Mock3rdEthPool.withdraw()](contracts/eth/mock/Mock3rdEthPool.sol#L19-L30) sends eth to arbitrary user
	Dangerous calls:
	- [address(msg.sender).transfer(_amounts[0])](contracts/eth/mock/Mock3rdEthPool.sol#L28)

contracts/eth/mock/Mock3rdEthPool.sol#L19-L30


 - [ ] ID-33
[Treasury.withdrawETH(address,uint256)](node_modules/boc-contract-core/contracts/treasury/Treasury.sol#L56-L63) sends eth to arbitrary user
	Dangerous calls:
	- [_destination.transfer(_amount)](node_modules/boc-contract-core/contracts/treasury/Treasury.sol#L62)

node_modules/boc-contract-core/contracts/treasury/Treasury.sol#L56-L63


 - [ ] ID-34
[ETHVault.lend(address,IExchangeAggregator.ExchangeToken[])](contracts/eth/vault/ETHVault.sol#L261-L324) sends eth to arbitrary user
	Dangerous calls:
	- [_ethStrategy.borrow{value: _ethAmount}(_wants,_toAmounts)](contracts/eth/vault/ETHVault.sol#L318)

contracts/eth/vault/ETHVault.sol#L261-L324


 - [ ] ID-35
[ETHVault._exchange(address,address,uint256,IExchangeAggregator.ExchangeParam)](contracts/eth/vault/ETHVault.sol#L1071-L1119) sends eth to arbitrary user
	Dangerous calls:
	- [_exchangeAmount = IExchangeAggregator(exchangeManager).swap{value: _amount}(_exchangeParam.platform,_exchangeParam.method,_exchangeParam.encodeExchangeArgs,_swapDescription)](contracts/eth/vault/ETHVault.sol#L1088-L1093)

contracts/eth/vault/ETHVault.sol#L1071-L1119


 - [ ] ID-36
[TestAdapter.swap(uint8,bytes,IExchangeAdapter.SwapDescription)](node_modules/boc-contract-core/contracts/exchanges/adapters/TestAdapter.sol#L25-L44) sends eth to arbitrary user
	Dangerous calls:
	- [address(_sd.receiver).transfer(_expectAmount)](node_modules/boc-contract-core/contracts/exchanges/adapters/TestAdapter.sol#L39)

node_modules/boc-contract-core/contracts/exchanges/adapters/TestAdapter.sol#L25-L44


 - [ ] ID-37
[MockEthStrategy.depositTo3rdPool(address[],uint256[])](contracts/eth/mock/MockEthStrategy.sol#L107-L114) sends eth to arbitrary user
	Dangerous calls:
	- [mock3rdPool.deposit{value: _amounts[0]}(_assets,_amounts)](contracts/eth/mock/MockEthStrategy.sol#L113)

contracts/eth/mock/MockEthStrategy.sol#L107-L114


 - [ ] ID-38
[ETHVault._transfer(uint256[],address[],uint256[],uint256[])](contracts/eth/vault/ETHVault.sol#L824-L854) sends eth to arbitrary user
	Dangerous calls:
	- [address(msg.sender).transfer(_amount)](contracts/eth/vault/ETHVault.sol#L838)

contracts/eth/vault/ETHVault.sol#L824-L854


 - [ ] ID-39
[MockVault.lend(address,address[],uint256[])](contracts/eth/mock/MockVault.sol#L42-L58) sends eth to arbitrary user
	Dangerous calls:
	- [address(address(_strategy)).transfer(_amount)](contracts/eth/mock/MockVault.sol#L51)

contracts/eth/mock/MockVault.sol#L42-L58


## reentrancy-eth
Impact: High
Confidence: Medium
 - [ ] ID-40
Reentrancy in [Vault.burn(uint256,address,uint256,bool,IExchangeAggregator.ExchangeToken[])](node_modules/boc-contract-core/contracts/vault/Vault.sol#L185-L237):
	External calls:
	- [(_sharesAmount,_actualAsset) = _replayToVault(_amount,_accountBalance,_trackedAssets,_assetPrices,_assetDecimals)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L204-L210)
		- [(_assets,_amounts) = IStrategy(_strategy).repay(_strategyWithdrawValue,_strategyTotalValue,0)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L648-L652)
		- [IVaultBuffer(vaultBufferAddress).transferCashToVault(_transferAssets,_amounts)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L714)
		- [IPegToken(pegTokenAddress).mintShares(vaultBufferAddress,_totalTransferShares)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L721)
	- [(_assets,_amounts,_actuallyReceivedAmount) = _calculateAndTransfer(_asset,_exchangeTokens,_needExchange,_actualAsset,_trackedAssets,_assetPrices,_assetDecimals)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L213-L221)
		- [returndata = address(token).functionCall(data,SafeERC20: low-level call failed)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L93)
		- [IERC20Upgradeable(_fromToken).safeApprove(exchangeManager,_amount)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1123)
		- [_exchangeAmount = IExchangeAggregator(exchangeManager).swap(_exchangeParam.platform,_exchangeParam.method,_exchangeParam.encodeExchangeArgs,_swapDescription)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1124-L1129)
		- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L137)
		- [IERC20Upgradeable(_trackedAsset).safeTransfer(msg.sender,_amount)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L867)
	- [_burnRebaseAndEmit(_asset,_amount,_actuallyReceivedAmount,_sharesAmount,_assets,_amounts,_trackedAssets,_assetPrices,_assetDecimals)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L226-L236)
		- [IPegToken(pegTokenAddress).burnShares(msg.sender,_shareAmount)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L995)
		- [IPegToken(pegTokenAddress).mintShares(_treasuryAddress,_sharesAmount)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1041)
	External calls sending eth:
	- [(_assets,_amounts,_actuallyReceivedAmount) = _calculateAndTransfer(_asset,_exchangeTokens,_needExchange,_actualAsset,_trackedAssets,_assetPrices,_assetDecimals)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L213-L221)
		- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L137)
	State variables written after the call(s):
	- [_burnRebaseAndEmit(_asset,_amount,_actuallyReceivedAmount,_sharesAmount,_assets,_amounts,_trackedAssets,_assetPrices,_assetDecimals)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L226-L236)
		- [underlyingUnitsPerShare = _newUnderlyingUnitsPerShare](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1048)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L185-L237


 - [ ] ID-41
Reentrancy in [ETHVault.burn(uint256,uint256)](contracts/eth/vault/ETHVault.sol#L188-L227):
	External calls:
	- [(_sharesAmount,_actualAsset) = _replayToVault(_amount,_accountBalance,_trackedAssets,_assetPrices,_assetDecimals)](contracts/eth/vault/ETHVault.sol#L200-L206)
		- [(_assets,_amounts) = IETHStrategy(_strategy).repay(_strategyWithdrawValue,_strategyTotalValue,0)](contracts/eth/vault/ETHVault.sol#L666-L670)
		- [IVaultBuffer(vaultBufferAddress).transferCashToVault(_transferAssets,_amounts)](contracts/eth/vault/ETHVault.sol#L736)
		- [IPegToken(pegTokenAddress).mintShares(vaultBufferAddress,_totalTransferShares)](contracts/eth/vault/ETHVault.sol#L743)
	- [(_assets,_amounts,_actuallyReceivedAmount) = _calculateAndTransfer(_actualAsset,_trackedAssets,_assetPrices,_assetDecimals)](contracts/eth/vault/ETHVault.sol#L208-L213)
		- [returndata = address(token).functionCall(data,SafeERC20: low-level call failed)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L93)
		- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L137)
		- [IERC20Upgradeable(_trackedAsset).safeTransfer(msg.sender,_amount)](contracts/eth/vault/ETHVault.sol#L849)
	- [_burnRebaseAndEmit(_amount,_actuallyReceivedAmount,_sharesAmount,_assets,_amounts,_trackedAssets,_assetPrices,_assetDecimals)](contracts/eth/vault/ETHVault.sol#L217-L226)
		- [IPegToken(pegTokenAddress).burnShares(msg.sender,_shareAmount)](contracts/eth/vault/ETHVault.sol#L950)
		- [IPegToken(pegTokenAddress).mintShares(_treasuryAddress,_sharesAmount)](contracts/eth/vault/ETHVault.sol#L1000)
	External calls sending eth:
	- [(_assets,_amounts,_actuallyReceivedAmount) = _calculateAndTransfer(_actualAsset,_trackedAssets,_assetPrices,_assetDecimals)](contracts/eth/vault/ETHVault.sol#L208-L213)
		- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L137)
		- [address(msg.sender).transfer(_amount)](contracts/eth/vault/ETHVault.sol#L838)
	State variables written after the call(s):
	- [_burnRebaseAndEmit(_amount,_actuallyReceivedAmount,_sharesAmount,_assets,_amounts,_trackedAssets,_assetPrices,_assetDecimals)](contracts/eth/vault/ETHVault.sol#L217-L226)
		- [underlyingUnitsPerShare = _newUnderlyingUnitsPerShare](contracts/eth/vault/ETHVault.sol#L1010)

contracts/eth/vault/ETHVault.sol#L188-L227


## unchecked-transfer
Impact: High
Confidence: Medium
 - [ ] ID-42
[ETHExchanger.eth2wEth(address)](contracts/eth/exchanges/ETHExchanger.sol#L107-L113) ignores return value by [IERC20(wETH).transfer(_receiver,_wEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L112)

contracts/eth/exchanges/ETHExchanger.sol#L107-L113


 - [ ] ID-43
[ETHExchanger.stEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L38-L47) ignores return value by [IERC20(stETH).transferFrom(_receiver,address(this),_stEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L39)

contracts/eth/exchanges/ETHExchanger.sol#L38-L47


 - [ ] ID-44
[ETHExchanger.eth2wstEth(address)](contracts/eth/exchanges/ETHExchanger.sol#L49-L62) ignores return value by [IERC20(wstETH).transfer(_receiver,_wstEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L61)

contracts/eth/exchanges/ETHExchanger.sol#L49-L62


 - [ ] ID-45
[ETHExchanger.wstEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L64-L77) ignores return value by [IERC20(wstETH).transferFrom(_receiver,address(this),_wstEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L65)

contracts/eth/exchanges/ETHExchanger.sol#L64-L77


 - [ ] ID-46
[ETHExchanger.wEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L115-L125) ignores return value by [IERC20(wETH).transferFrom(_receiver,address(this),_wEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L116)

contracts/eth/exchanges/ETHExchanger.sol#L115-L125


 - [ ] ID-47
[Mock3rdEthPool.withdraw()](contracts/eth/mock/Mock3rdEthPool.sol#L19-L30) ignores return value by [IERC20Upgradeable(stETH).transfer(msg.sender,_amounts[1])](contracts/eth/mock/Mock3rdEthPool.sol#L29)

contracts/eth/mock/Mock3rdEthPool.sol#L19-L30


 - [ ] ID-48
[Mock3rdEthPool.deposit(address[],uint256[])](contracts/eth/mock/Mock3rdEthPool.sol#L13-L17) ignores return value by [IERC20Upgradeable(stETH).transferFrom(msg.sender,address(this),_amounts[1])](contracts/eth/mock/Mock3rdEthPool.sol#L16)

contracts/eth/mock/Mock3rdEthPool.sol#L13-L17


 - [ ] ID-49
[ETHExchanger.eth2stEth(address)](contracts/eth/exchanges/ETHExchanger.sol#L28-L36) ignores return value by [IERC20(stETH).transfer(_receiver,_stEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L35)

contracts/eth/exchanges/ETHExchanger.sol#L28-L36


 - [ ] ID-50
[ConvexIBUsdcStrategy.harvest()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L433-L483) ignores return value by [IERC20Upgradeable(RKPR).transfer(harvester,_rkprBalance)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L459)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L433-L483


 - [ ] ID-51
[ETHExchanger.rEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L90-L105) ignores return value by [IERC20(rETH).transferFrom(_receiver,address(this),_rEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L91)

contracts/eth/exchanges/ETHExchanger.sol#L90-L105


 - [ ] ID-52
[ConvexIBUsdtStrategy.harvest()](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L315-L359) ignores return value by [IERC20Upgradeable(RKPR).transfer(harvester,_rkprBalance)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L338)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L315-L359


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-53
[ParaSwapV5ActionsMixin.__megaSwap(Utils.MegaSwapSellData)](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L29-L38) uses a dangerous strict equality:
	- [_data.fromToken == NativeToken.NATIVE_TOKEN](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L32)

contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L29-L38


 - [ ] ID-54
[ParaSwapV5ActionsMixin.__protectedSimpleSwap(Utils.SimpleData)](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L62-L71) uses a dangerous strict equality:
	- [_data.fromToken == NativeToken.NATIVE_TOKEN](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L65)

contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L62-L71


 - [ ] ID-55
[ParaSwapV5ActionsMixin.__protectedMultiSwap(Utils.SellData)](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L40-L49) uses a dangerous strict equality:
	- [_data.fromToken == NativeToken.NATIVE_TOKEN](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L43)

contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L40-L49


 - [ ] ID-56
[ParaSwapV5ActionsMixin.__simpleSwap(Utils.SimpleData)](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L73-L82) uses a dangerous strict equality:
	- [_data.fromToken == NativeToken.NATIVE_TOKEN](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L76)

contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L73-L82


 - [ ] ID-57
[ParaSwapV5ActionsMixin.__multiSwap(Utils.SellData)](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L18-L27) uses a dangerous strict equality:
	- [_data.fromToken == NativeToken.NATIVE_TOKEN](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L21)

contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L18-L27


 - [ ] ID-58
[ParaSwapV5ActionsMixin.__protectedMegaSwap(Utils.MegaSwapSellData)](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L51-L60) uses a dangerous strict equality:
	- [_data.fromToken == NativeToken.NATIVE_TOKEN](contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L54)

contracts/exchanges/utils/ParaSwapV5ActionsMixin.sol#L51-L60


 - [ ] ID-59
[Vault._calculateShare(uint256,uint256,uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L728-L746) uses a dangerous strict equality:
	- [_shareAmount == 0](node_modules/boc-contract-core/contracts/vault/Vault.sol#L737)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L728-L746


 - [ ] ID-60
[VaultBuffer.distributeOnce()](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L124-L138) uses a dangerous strict equality:
	- [require(bool,string)(IERC20Upgradeable(_asset).balanceOf(address(this)) == 0,cash remain.)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L132)

node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L124-L138


 - [ ] ID-61
[ETHVault._replayToVault(uint256,uint256,address[],uint256[],uint256[])](contracts/eth/vault/ETHVault.sol#L856-L907) uses a dangerous strict equality:
	- [_accountBalance == _actualAmount](contracts/eth/vault/ETHVault.sol#L873)

contracts/eth/vault/ETHVault.sol#L856-L907


 - [ ] ID-62
[ETHVaultAdmin.removeAsset(address)](contracts/eth/vault/ETHVaultAdmin.sol#L168-L192) uses a dangerous strict equality:
	- [require(bool,string)(address(vaultBufferAddress).balance == 0,vaultBuffer exist this asset)](contracts/eth/vault/ETHVaultAdmin.sol#L170)

contracts/eth/vault/ETHVaultAdmin.sol#L168-L192


 - [ ] ID-63
[VaultBuffer.distributeOnce()](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L124-L138) uses a dangerous strict equality:
	- [require(bool,string)(address(this).balance == 0,cash remain.)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L130)

node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L124-L138


 - [ ] ID-64
[ETHVaultAdmin.removeAsset(address)](contracts/eth/vault/ETHVaultAdmin.sol#L168-L192) uses a dangerous strict equality:
	- [_balance == 0](contracts/eth/vault/ETHVaultAdmin.sol#L187)

contracts/eth/vault/ETHVaultAdmin.sol#L168-L192


 - [ ] ID-65
[VaultAdmin.removeAsset(address)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L149-L164) uses a dangerous strict equality:
	- [require(bool,string)(IERC20Upgradeable(_asset).balanceOf(vaultBufferAddress) == 0,vaultBuffer exist this asset)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L151-L154)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L149-L164


 - [ ] ID-66
[VaultAdmin.removeAsset(address)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L149-L164) uses a dangerous strict equality:
	- [trackedAssetsMap.get(_asset) <= 0 && IERC20Upgradeable(_asset).balanceOf(address(this)) == 0](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L158)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L149-L164


 - [ ] ID-67
[VaultAdmin._removeStrategy(address,bool)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260) uses a dangerous strict equality:
	- [trackedAssetsMap.get(_wantToken) <= 0 && IERC20Upgradeable(_wantToken).balanceOf(address(this)) == 0](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L248-L249)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260


 - [ ] ID-68
[ETHVault._calculateShare(uint256,uint256,uint256)](contracts/eth/vault/ETHVault.sol#L750-L768) uses a dangerous strict equality:
	- [_shareAmount == 0](contracts/eth/vault/ETHVault.sol#L759)

contracts/eth/vault/ETHVault.sol#L750-L768


 - [ ] ID-69
[ConvexIBUsdcStrategy.assetDelta()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L305-L356) uses a dangerous strict equality:
	- [_rewardBalance == 0](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L307)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L305-L356


 - [ ] ID-70
[ETHVaultAdmin.removeAsset(address)](contracts/eth/vault/ETHVaultAdmin.sol#L168-L192) uses a dangerous strict equality:
	- [require(bool,string)(IERC20Upgradeable(_asset).balanceOf(vaultBufferAddress) == 0,vaultBuffer exit this asset)](contracts/eth/vault/ETHVaultAdmin.sol#L172-L175)

contracts/eth/vault/ETHVaultAdmin.sol#L168-L192


 - [ ] ID-71
[Vault._replayToVault(uint256,uint256,address[],uint256[],uint256[])](node_modules/boc-contract-core/contracts/vault/Vault.sol#L894-L941) uses a dangerous strict equality:
	- [_accountBalance == _actualAmount](node_modules/boc-contract-core/contracts/vault/Vault.sol#L907)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L894-L941


 - [ ] ID-72
[ETHVaultAdmin._removeStrategy(address,bool)](contracts/eth/vault/ETHVaultAdmin.sol#L258-L290) uses a dangerous strict equality:
	- [_balance == 0](contracts/eth/vault/ETHVaultAdmin.sol#L279)

contracts/eth/vault/ETHVaultAdmin.sol#L258-L290


## locked-ether
Impact: Medium
Confidence: High
 - [ ] ID-73
Contract locking ether found:
	Contract [ETHVaultAdmin](contracts/eth/vault/ETHVaultAdmin.sol#L12-L349) has payable functions:
	 - [ETHVaultAdmin.receive()](contracts/eth/vault/ETHVaultAdmin.sol#L17)
	 - [ETHVaultAdmin.fallback()](contracts/eth/vault/ETHVaultAdmin.sol#L19)
	But does not have a function to withdraw the ether

contracts/eth/vault/ETHVaultAdmin.sol#L12-L349


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-74
[ConvexIBUsdtStrategy.collateralAssets()](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L271-L290) performs a multiplication on the result of a division:
	-[_collateralTokenAmount = (balanceOfToken(address(_collateralC)) * _exchangeRateMantissa * _collaterTokenPrecision * 1e18) / 1e16 / decimalUnitOfToken(address(_collateralC))](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L278-L283)
	-[_value = (_collateralTokenAmount * _collateralTokenPrice()) / _collaterTokenPrecision / 1e18 / 1e12](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L285-L289)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L271-L290


 - [ ] ID-75
[ConvexIBUsdtStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L567-L614) performs a multiplication on the result of a division:
	-[_repayAmount = (_currentBorrow * _withdrawShares) / _totalShares](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L588)
	-[_burnAmount = (balanceOfToken(address(_collateralC)) * _repayAmount) / _currentBorrow](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L591-L592)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L567-L614


 - [ ] ID-76
[ChainlinkPriceFeed.__calcConversionAmountUsdRateAssetToEthRateAsset(uint256,uint256,uint256,uint256,uint256,uint256)](node_modules/boc-contract-core/contracts/price-feeds/primitives/ChainlinkPriceFeed.sol#L325-L339) performs a multiplication on the result of a division:
	-[_intermediateStep = (_baseAssetAmount * _baseAssetRate * _quoteAssetUnit) / _ethPerUsdRate](node_modules/boc-contract-core/contracts/price-feeds/primitives/ChainlinkPriceFeed.sol#L335-L336)
	-[(_intermediateStep * ETH_UNIT) / _baseAssetUnit / _quoteAssetRate](node_modules/boc-contract-core/contracts/price-feeds/primitives/ChainlinkPriceFeed.sol#L338)

node_modules/boc-contract-core/contracts/price-feeds/primitives/ChainlinkPriceFeed.sol#L325-L339


 - [ ] ID-77
[FullMath.mulDiv(uint256,uint256,uint256)](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L67)
	-[inv *= 2 - denominator * inv](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L95)

node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106


 - [ ] ID-78
[ConvexIBUsdcStrategy.exitCollateralInvestToCurvePool(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L636-L661) performs a multiplication on the result of a division:
	-[_spaceValue = (_space * _borrowTokenPrice()) / _borrowTokenDecimals](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L640)
	-[_exitCollateral = (_spaceValue * 1e18 * BPS * _collaterTokenPrecision) / _rate / borrowFactor / _collateralTokenPrice()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L646-L649)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L636-L661


 - [ ] ID-79
[UniswapV3FullMath.mulDiv(uint256,uint256,uint256)](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L64)
	-[inv *= 2 - denominator * inv](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L91)

contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101


 - [ ] ID-80
[UniswapV3Strategy._floor(int24)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L431-L436) performs a multiplication on the result of a division:
	-[compressed = _tick / tickSpacing](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L433)
	-[compressed * tickSpacing](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L435)

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L431-L436


 - [ ] ID-81
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	-[inverse = (3 * denominator) ^ 2](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L117)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-82
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	-[inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L122)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-83
[FullMath.mulDiv(uint256,uint256,uint256)](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L67)
	-[inv *= 2 - denominator * inv](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L92)

node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106


 - [ ] ID-84
[ChainlinkPriceFeed.__calcConversionAmountEthRateAssetToUsdRateAsset(uint256,uint256,uint256,uint256,uint256,uint256)](node_modules/boc-contract-core/contracts/price-feeds/primitives/ChainlinkPriceFeed.sol#L297-L310) performs a multiplication on the result of a division:
	-[_intermediateStep = (_baseAssetAmount * _baseAssetRate * _ethPerUsdRate) / ETH_UNIT](node_modules/boc-contract-core/contracts/price-feeds/primitives/ChainlinkPriceFeed.sol#L307)
	-[(_intermediateStep * _quoteAssetUnit) / _baseAssetUnit / _quoteAssetRate](node_modules/boc-contract-core/contracts/price-feeds/primitives/ChainlinkPriceFeed.sol#L309)

node_modules/boc-contract-core/contracts/price-feeds/primitives/ChainlinkPriceFeed.sol#L297-L310


 - [ ] ID-85
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	-[inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L124)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-86
[DodoV1Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243) performs a multiplication on the result of a division:
	-[_quoteWithdrawAmount = (balanceOfQuoteLpToken() * _withdrawShares) / _totalShares](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L210)
	-[DodoVaultV1(_lpTokenPool).withdrawQuote((_quoteWithdrawAmount * _quoteExpectedTarget) / _totalQuoteCapital)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L232-L234)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243


 - [ ] ID-87
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	-[inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L126)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-88
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	-[inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L123)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-89
[ConvexIBUsdcStrategy.collateralAssets()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L392-L408) performs a multiplication on the result of a division:
	-[_collateralTokenAmount = (((balanceOfToken(address(_collateralC)) * _exchangeRateMantissa) * decimalUnitOfToken(_collateralToken)) * 1e18) / 1e16 / decimalUnitOfToken(address(_collateralC))](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L398-L401)
	-[_value = (_collateralTokenAmount * _collateralTokenPrice) / decimalUnitOfToken(_collateralToken) / 1e18 / 1e12](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L403-L407)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L392-L408


 - [ ] ID-90
[ConvexIBUsdcStrategy._borrowAvaiable(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L560-L567) performs a multiplication on the result of a division:
	-[_maxBorrowAmount = (liqudity * decimalUnitOfToken(_borrowToken)) / _borrowTokenPrice()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L563-L564)
	-[_borrowAvaible = (_maxBorrowAmount * borrowFactor) / BPS](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L566)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L560-L567


 - [ ] ID-91
[FullMath.mulDiv(uint256,uint256,uint256)](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L67)
	-[inv = (3 * denominator) ^ 2](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L87)

node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106


 - [ ] ID-92
[UniswapV3FullMath.mulDiv(uint256,uint256,uint256)](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L64)
	-[inv *= 2 - denominator * inv](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L89)

contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101


 - [ ] ID-93
[ConvexIBUsdcStrategy.increaseCollateral(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L664-L683) performs a multiplication on the result of a division:
	-[_needCollateral = ((((_overflowValue * 1e18) * BPS) / _rate / borrowFactor) * decimalUnitOfToken(_collateralToken)) / _collateralTokenPrice()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L672-L673)
	-[_removeLp = (_totalLp * _needCollateral) / _allUnderlying](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L676)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L664-L683


 - [ ] ID-94
[ConvexIBUsdcStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L726-L769) performs a multiplication on the result of a division:
	-[_repayAmount = (_currentBorrow * _withdrawShares) / _totalShares](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L746)
	-[_burnAmount = (balanceOfToken(address(_collateralC)) * _repayAmount) / _currentBorrow](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L760-L761)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L726-L769


 - [ ] ID-95
[Tick.tickSpacingToMaxLiquidityPerTick(int24)](node_modules/@uniswap/v3-core/contracts/libraries/Tick.sol#L44-L49) performs a multiplication on the result of a division:
	-[maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing](node_modules/@uniswap/v3-core/contracts/libraries/Tick.sol#L46)

node_modules/@uniswap/v3-core/contracts/libraries/Tick.sol#L44-L49


 - [ ] ID-96
[FullMath.mulDiv(uint256,uint256,uint256)](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106) performs a multiplication on the result of a division:
	-[prod0 = prod0 / twos](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L72)
	-[result = prod0 * inv](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L104)

node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106


 - [ ] ID-97
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	-[inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L121)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-98
[ConvexIBUsdcStrategy.exitCollateralInvestToCurvePool(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L636-L661) performs a multiplication on the result of a division:
	-[_exitCollateral = (_spaceValue * 1e18 * BPS * _collaterTokenPrecision) / _rate / borrowFactor / _collateralTokenPrice()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L646-L649)
	-[_exitCollateralC = (_exitCollateral * 1e16 * decimalUnitOfToken(_collaterCTokenAddr)) / _exchangeRateMantissa / _collaterTokenPrecision](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L651-L655)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L636-L661


 - [ ] ID-99
[FullMath.mulDiv(uint256,uint256,uint256)](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L67)
	-[inv *= 2 - denominator * inv](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L91)

node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106


 - [ ] ID-100
[ConvexIBUsdcStrategy.assetDelta()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L305-L356) performs a multiplication on the result of a division:
	-[_underlyingHoldOn = (ICurveMini(_curvePool).balances(1) * _rewardBalance) / _totalLp](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L312-L313)
	-[_useUnderlying = _underlyingHoldOn](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L340)
	-[_needUnderlyingValue = (_useUnderlying * _collateralTokenPrice()) / decimalUnitOfToken(COLLATERAL_TOKEN)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L348-L349)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L305-L356


 - [ ] ID-101
[FullMath.mulDiv(uint256,uint256,uint256)](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L67)
	-[inv *= 2 - denominator * inv](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L93)

node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106


 - [ ] ID-102
[UniswapV3FullMath.mulDiv(uint256,uint256,uint256)](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L64)
	-[inv *= 2 - denominator * inv](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L88)

contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101


 - [ ] ID-103
[ETHUniswapV3BaseStrategy.getSpecifiedRangesOfTick(int24)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L114-L123) performs a multiplication on the result of a division:
	-[_compressed = _tick / _tickSpacing](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L117)
	-[_tickFloor = _compressed * _tickSpacing](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L119)

contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L114-L123


 - [ ] ID-104
[ETHVault._rebase(uint256,uint256)](contracts/eth/vault/ETHVault.sol#L977-L1015) performs a multiplication on the result of a division:
	-[_fee = (_yield * _trusteeFeeBps) / MAX_BPS](contracts/eth/vault/ETHVault.sol#L995)
	-[_sharesAmount = (_fee * _totalShares) / (_totalAssets - _fee)](contracts/eth/vault/ETHVault.sol#L998)

contracts/eth/vault/ETHVault.sol#L977-L1015


 - [ ] ID-105
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	-[inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L125)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-106
[FullMath.mulDiv(uint256,uint256,uint256)](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L67)
	-[inv *= 2 - denominator * inv](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L94)

node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106


 - [ ] ID-107
[DodoV1Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243) performs a multiplication on the result of a division:
	-[_baseWithdrawAmount = (balanceOfBaseLpToken() * _withdrawShares) / _totalShares](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L209)
	-[DodoVaultV1(_lpTokenPool).withdrawBase((_baseWithdrawAmount * _baseExpectedTarget) / _totalBaseCapital)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L219-L221)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243


 - [ ] ID-108
[UniswapV3FullMath.mulDiv(uint256,uint256,uint256)](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101) performs a multiplication on the result of a division:
	-[prod0 = prod0 / twos](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L68)
	-[result = prod0 * inv](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L98)

contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101


 - [ ] ID-109
[Tick.tickSpacingToMaxLiquidityPerTick(int24)](node_modules/@uniswap/v3-core/contracts/libraries/Tick.sol#L44-L49) performs a multiplication on the result of a division:
	-[minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing](node_modules/@uniswap/v3-core/contracts/libraries/Tick.sol#L45)

node_modules/@uniswap/v3-core/contracts/libraries/Tick.sol#L44-L49


 - [ ] ID-110
[DodoV1Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243) performs a multiplication on the result of a division:
	-[_baseWithdrawAmount = (balanceOfBaseLpToken() * _withdrawShares) / _totalShares](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L209)
	-[DodoVaultV1(_lpTokenPool).withdrawBase((_baseWithdrawAmount * _baseExpectedTarget) / _totalBaseCapital)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L238-L240)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243


 - [ ] ID-111
[UniswapV3FullMath.mulDiv(uint256,uint256,uint256)](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L64)
	-[inv *= 2 - denominator * inv](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L90)

contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101


 - [ ] ID-112
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	-[prod0 = prod0 / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L105)
	-[result = prod0 * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L132)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-113
[FullMath.mulDiv(uint256,uint256,uint256)](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L67)
	-[inv *= 2 - denominator * inv](node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L96)

node_modules/@uniswap/v3-core/contracts/libraries/FullMath.sol#L14-L106


 - [ ] ID-114
[UniswapV3FullMath.mulDiv(uint256,uint256,uint256)](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L64)
	-[inv *= 2 - denominator * inv](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L86)

contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101


 - [ ] ID-115
[ConvexIBUsdtStrategy._borrowAvaiable(uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L447-L455) performs a multiplication on the result of a division:
	-[_maxBorrowAmount = (liqudity * decimalUnitOfToken(_borrowToken)) / _borrowTokenPrice](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L451-L452)
	-[_borrowAvaible = (_maxBorrowAmount * borrowFactor) / BPS](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L454)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L447-L455


 - [ ] ID-116
[Vault._rebase(uint256,uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1018-L1053) performs a multiplication on the result of a division:
	-[_fee = (_yield * _trusteeFeeBps) / MAX_BPS](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1036)
	-[_sharesAmount = (_fee * _totalShares) / (_totalAssets - _fee)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1039)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L1018-L1053


 - [ ] ID-117
[DodoV1Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243) performs a multiplication on the result of a division:
	-[_quoteWithdrawAmount = (balanceOfQuoteLpToken() * _withdrawShares) / _totalShares](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L210)
	-[DodoVaultV1(_lpTokenPool).withdrawQuote((_quoteWithdrawAmount * _quoteExpectedTarget) / _totalQuoteCapital)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L225-L227)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243


 - [ ] ID-118
[UniswapV3FullMath.mulDiv(uint256,uint256,uint256)](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L64)
	-[inv = (3 * denominator) ^ 2](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L82)

contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101


 - [ ] ID-119
[UniswapV3FullMath.mulDiv(uint256,uint256,uint256)](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101) performs a multiplication on the result of a division:
	-[denominator = denominator / twos](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L64)
	-[inv *= 2 - denominator * inv](contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L87)

contracts/external/uniswapV3/libraries/UniswapV3FullMath.sol#L15-L101


 - [ ] ID-120
[ConvexIBUsdcStrategy.increaseCollateral(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L664-L683) performs a multiplication on the result of a division:
	-[_needCollateral = ((((_overflowValue * 1e18) * BPS) / _rate / borrowFactor) * decimalUnitOfToken(_collateralToken)) / _collateralTokenPrice()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L672-L673)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L664-L683


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-121
Reentrancy in [UniswapV3Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L255-L269):
	External calls:
	- [harvest()](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L261)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L217)
	- [withdraw(baseMintInfo.tokenId,_withdrawShares,_totalShares)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L263)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [(_amount0,_amount1) = nonfungiblePositionManager.decreaseLiquidity(_params)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L298)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [withdraw(limitMintInfo.tokenId,_withdrawShares,_totalShares)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L264)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [(_amount0,_amount1) = nonfungiblePositionManager.decreaseLiquidity(_params)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L298)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	State variables written after the call(s):
	- [baseMintInfo = MintInfo(0,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L266)
	- [limitMintInfo = MintInfo(0,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L267)

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L255-L269


 - [ ] ID-122
Reentrancy in [ETHVault.endAdjustPosition()](contracts/eth/vault/ETHVault.sol#L415-L537):
	External calls:
	- [_totalShares = _rebase(_totalValueOfNow - _transferAssets,_totalShares)](contracts/eth/vault/ETHVault.sol#L502)
		- [IPegToken(pegTokenAddress).mintShares(_treasuryAddress,_sharesAmount)](contracts/eth/vault/ETHVault.sol#L1000)
	- [IPegToken(pegTokenAddress).mintShares(vaultBufferAddress,_sharesAmount)](contracts/eth/vault/ETHVault.sol#L511)
	- [IVaultBuffer(vaultBufferAddress).openDistribute()](contracts/eth/vault/ETHVault.sol#L525)
	- [isKeeper()](contracts/eth/vault/ETHVault.sol#L415)
		- [accessControlProxy.checkKeeperOrVaultOrGov(msg.sender)](node_modules/boc-contract-core/contracts/access-control/AccessControlMixin.sol#L35)
	State variables written after the call(s):
	- [adjustPositionPeriod = false](contracts/eth/vault/ETHVault.sol#L527)

contracts/eth/vault/ETHVault.sol#L415-L537


 - [ ] ID-123
Reentrancy in [ETHUniswapV3BaseStrategy.rebalance(int24)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279):
	External calls:
	- [harvest()](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L243)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
		- [nonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(baseMintInfo.tokenId,balanceOfToken(token0),balanceOfToken(token1),0,0,block.timestamp))](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L186-L193)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L34)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L247)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [__purge(limitMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L253)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L264)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	- [mintNewPosition(_tickCeil,_tickCeil + limitThreshold,_balance0,_balance1,false)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L274)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	State variables written after the call(s):
	- [mintNewPosition(_tickCeil,_tickCeil + limitThreshold,_balance0,_balance1,false)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L274)
		- [baseMintInfo = MintInfo(tokenId,_tickLower,_tickUpper)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L343)
	- [mintNewPosition(_tickCeil,_tickCeil + limitThreshold,_balance0,_balance1,false)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L274)
		- [limitMintInfo = MintInfo(tokenId,_tickLower,_tickUpper)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L345)

contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279


 - [ ] ID-124
Reentrancy in [VaultBuffer._distribute()](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L140-L168):
	External calls:
	- [_pegToken.safeTransfer(_account,_transferAmount)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L161)
	State variables written after the call(s):
	- [_burn(_account,_share)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L162)
		- [mTotalSupply -= _amount](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L411)

node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L140-L168


 - [ ] ID-125
Reentrancy in [Vault._replayToVault(uint256,uint256,address[],uint256[],uint256[])](node_modules/boc-contract-core/contracts/vault/Vault.sol#L894-L941):
	External calls:
	- [_totalAssetInVault = _totalAssetInVault + _repayFromVaultBuffer(_actualAsset - _totalAssetInVault,_trackedAssets,_assetPrices,_assetDecimals,_currentTotalAssets,_currentTotalShares)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L925-L934)
		- [IVaultBuffer(vaultBufferAddress).transferCashToVault(_transferAssets,_amounts)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L714)
		- [IPegToken(pegTokenAddress).mintShares(vaultBufferAddress,_totalTransferShares)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L721)
	- [_repayFromWithdrawQueue(_actualAsset - _totalAssetInVault)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L939)
		- [(_assets,_amounts) = IStrategy(_strategy).repay(_strategyWithdrawValue,_strategyTotalValue,0)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L648-L652)
	State variables written after the call(s):
	- [_repayFromWithdrawQueue(_actualAsset - _totalAssetInVault)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L939)
		- [totalDebt -= _totalWithdrawValue](node_modules/boc-contract-core/contracts/vault/Vault.sol#L670)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L894-L941


 - [ ] ID-126
Reentrancy in [ETHUniswapV3BaseStrategy.rebalance(int24)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279):
	External calls:
	- [harvest()](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L243)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
		- [nonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(baseMintInfo.tokenId,balanceOfToken(token0),balanceOfToken(token1),0,0,block.timestamp))](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L186-L193)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L34)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L247)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [__purge(limitMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L253)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L264)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	- [mintNewPosition(_tickFloor - limitThreshold,_tickFloor,_balance0,_balance1,false)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L272)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	State variables written after the call(s):
	- [mintNewPosition(_tickFloor - limitThreshold,_tickFloor,_balance0,_balance1,false)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L272)
		- [baseMintInfo = MintInfo(tokenId,_tickLower,_tickUpper)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L343)
	- [mintNewPosition(_tickFloor - limitThreshold,_tickFloor,_balance0,_balance1,false)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L272)
		- [limitMintInfo = MintInfo(tokenId,_tickLower,_tickUpper)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L345)

contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279


 - [ ] ID-127
Reentrancy in [ETHUniswapV3BaseStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L198-L205):
	External calls:
	- [withdraw(baseMintInfo.tokenId,_withdrawShares,_totalShares)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L199)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [(_amount0,_amount1) = nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_tokenId,_liquidity,0,0,block.timestamp))](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L219-L225)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [withdraw(limitMintInfo.tokenId,_withdrawShares,_totalShares)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L200)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [(_amount0,_amount1) = nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_tokenId,_liquidity,0,0,block.timestamp))](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L219-L225)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	State variables written after the call(s):
	- [baseMintInfo = MintInfo(0,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L202)
	- [limitMintInfo = MintInfo(0,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L203)

contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L198-L205


 - [ ] ID-128
Reentrancy in [ETHUniswapV3BaseStrategy.rebalance(int24)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279):
	External calls:
	- [harvest()](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L243)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
		- [nonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(baseMintInfo.tokenId,balanceOfToken(token0),balanceOfToken(token1),0,0,block.timestamp))](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L186-L193)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L34)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L247)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	State variables written after the call(s):
	- [baseMintInfo = MintInfo(0,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L248)

contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279


 - [ ] ID-129
Reentrancy in [ETHVault.redeem(address,uint256,uint256)](contracts/eth/vault/ETHVault.sol#L230-L258):
	External calls:
	- [(_assets,_amounts) = IETHStrategy(_strategy).repay(_amount,_strategyAssetValue,_outputCode)](contracts/eth/vault/ETHVault.sol#L238-L242)
	- [isKeeper()](contracts/eth/vault/ETHVault.sol#L234)
		- [accessControlProxy.checkKeeperOrVaultOrGov(msg.sender)](node_modules/boc-contract-core/contracts/access-control/AccessControlMixin.sol#L35)
	State variables written after the call(s):
	- [strategies[_strategy].totalDebt = _nowStrategyTotalDebt - _thisWithdrawValue](contracts/eth/vault/ETHVault.sol#L254)

contracts/eth/vault/ETHVault.sol#L230-L258


 - [ ] ID-130
Reentrancy in [ETHVaultAdmin._removeStrategy(address,bool)](contracts/eth/vault/ETHVaultAdmin.sol#L258-L290):
	External calls:
	- [IETHStrategy(_addr).repay(MAX_BPS,MAX_BPS,0)](contracts/eth/vault/ETHVaultAdmin.sol#L261-L265)
	State variables written after the call(s):
	- [delete strategies[_addr]](contracts/eth/vault/ETHVaultAdmin.sol#L287)

contracts/eth/vault/ETHVaultAdmin.sol#L258-L290


 - [ ] ID-131
Reentrancy in [UniswapV3Strategy.rebalance(int24)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366):
	External calls:
	- [harvest()](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L316)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L217)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L320)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [__purge(limitMintInfo.tokenId,type()(uint128).max,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L326)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L342-L348)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	State variables written after the call(s):
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L342-L348)
		- [baseMintInfo = MintInfo(_tokenId,_tickLower,_tickUpper)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L469-L473)
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L342-L348)
		- [limitMintInfo = MintInfo(_tokenId,_tickLower,_tickUpper)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L475-L479)

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366


 - [ ] ID-132
Reentrancy in [Vault.endAdjustPosition()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L395-L511):
	External calls:
	- [_totalShares = _rebase(_totalValueOfNow - _transferAssets,_totalShares)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L476)
		- [IPegToken(pegTokenAddress).mintShares(_treasuryAddress,_sharesAmount)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1041)
	- [IPegToken(pegTokenAddress).mintShares(vaultBufferAddress,_sharesAmount)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L485)
	- [isKeeper()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L395)
		- [accessControlProxy.checkKeeperOrVaultOrGov(msg.sender)](node_modules/boc-contract-core/contracts/access-control/AccessControlMixin.sol#L35)
	State variables written after the call(s):
	- [totalDebtOfBeforeAdjustPosition = 0](node_modules/boc-contract-core/contracts/vault/Vault.sol#L491)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L395-L511


 - [ ] ID-133
Reentrancy in [VaultAdmin._removeStrategy(address,bool)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260):
	External calls:
	- [IStrategy(_addr).repay(MAX_BPS,MAX_BPS,0)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L236-L240)
	State variables written after the call(s):
	- [delete strategies[_addr]](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L257)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260


 - [ ] ID-134
Reentrancy in [ETHVault.endAdjustPosition()](contracts/eth/vault/ETHVault.sol#L415-L537):
	External calls:
	- [_totalShares = _rebase(_totalValueOfNow - _transferAssets,_totalShares)](contracts/eth/vault/ETHVault.sol#L502)
		- [IPegToken(pegTokenAddress).mintShares(_treasuryAddress,_sharesAmount)](contracts/eth/vault/ETHVault.sol#L1000)
	- [IPegToken(pegTokenAddress).mintShares(vaultBufferAddress,_sharesAmount)](contracts/eth/vault/ETHVault.sol#L511)
	- [isKeeper()](contracts/eth/vault/ETHVault.sol#L415)
		- [accessControlProxy.checkKeeperOrVaultOrGov(msg.sender)](node_modules/boc-contract-core/contracts/access-control/AccessControlMixin.sol#L35)
	State variables written after the call(s):
	- [totalDebtOfBeforeAdjustPosition = 0](contracts/eth/vault/ETHVault.sol#L517)

contracts/eth/vault/ETHVault.sol#L415-L537


 - [ ] ID-135
Reentrancy in [UniswapV3Strategy.rebalance(int24)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366):
	External calls:
	- [harvest()](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L316)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L217)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L320)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	State variables written after the call(s):
	- [baseMintInfo = MintInfo(0,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L321)

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366


 - [ ] ID-136
Reentrancy in [ETHVault._replayToVault(uint256,uint256,address[],uint256[],uint256[])](contracts/eth/vault/ETHVault.sol#L856-L907):
	External calls:
	- [_totalAssetInVault = _totalAssetInVault + _repayFromVaultBuffer(_actualAsset - _totalAssetInVault,_trackedAssets,_assetPrices,_assetDecimals,_currentTotalAssets,_currentTotalShares)](contracts/eth/vault/ETHVault.sol#L891-L900)
		- [IVaultBuffer(vaultBufferAddress).transferCashToVault(_transferAssets,_amounts)](contracts/eth/vault/ETHVault.sol#L736)
		- [IPegToken(pegTokenAddress).mintShares(vaultBufferAddress,_totalTransferShares)](contracts/eth/vault/ETHVault.sol#L743)
	- [_repayFromWithdrawQueue(_actualAsset - _totalAssetInVault)](contracts/eth/vault/ETHVault.sol#L905)
		- [(_assets,_amounts) = IETHStrategy(_strategy).repay(_strategyWithdrawValue,_strategyTotalValue,0)](contracts/eth/vault/ETHVault.sol#L666-L670)
	State variables written after the call(s):
	- [_repayFromWithdrawQueue(_actualAsset - _totalAssetInVault)](contracts/eth/vault/ETHVault.sol#L905)
		- [totalDebt -= _totalWithdrawValue](contracts/eth/vault/ETHVault.sol#L689)

contracts/eth/vault/ETHVault.sol#L856-L907


 - [ ] ID-137
Reentrancy in [ETHVault._repayFromWithdrawQueue(uint256)](contracts/eth/vault/ETHVault.sol#L642-L690):
	External calls:
	- [(_assets,_amounts) = IETHStrategy(_strategy).repay(_strategyWithdrawValue,_strategyTotalValue,0)](contracts/eth/vault/ETHVault.sol#L666-L670)
	State variables written after the call(s):
	- [strategies[_strategy].totalDebt = _nowStrategyTotalDebt - _thisWithdrawValue](contracts/eth/vault/ETHVault.sol#L682)

contracts/eth/vault/ETHVault.sol#L642-L690


 - [ ] ID-138
Reentrancy in [ETHUniswapV3BaseStrategy.rebalance(int24)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279):
	External calls:
	- [harvest()](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L243)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
		- [nonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(baseMintInfo.tokenId,balanceOfToken(token0),balanceOfToken(token1),0,0,block.timestamp))](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L186-L193)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L34)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L247)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [__purge(limitMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L253)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	State variables written after the call(s):
	- [limitMintInfo = MintInfo(0,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L254)

contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279


 - [ ] ID-139
Reentrancy in [Vault.endAdjustPosition()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L395-L511):
	External calls:
	- [_totalShares = _rebase(_totalValueOfNow - _transferAssets,_totalShares)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L476)
		- [IPegToken(pegTokenAddress).mintShares(_treasuryAddress,_sharesAmount)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1041)
	- [IPegToken(pegTokenAddress).mintShares(vaultBufferAddress,_sharesAmount)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L485)
	- [IVaultBuffer(vaultBufferAddress).openDistribute()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L499)
	- [isKeeper()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L395)
		- [accessControlProxy.checkKeeperOrVaultOrGov(msg.sender)](node_modules/boc-contract-core/contracts/access-control/AccessControlMixin.sol#L35)
	State variables written after the call(s):
	- [adjustPositionPeriod = false](node_modules/boc-contract-core/contracts/vault/Vault.sol#L501)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L395-L511


 - [ ] ID-140
Reentrancy in [Vault._rebase(uint256,uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1018-L1053):
	External calls:
	- [IPegToken(pegTokenAddress).mintShares(_treasuryAddress,_sharesAmount)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1041)
	State variables written after the call(s):
	- [underlyingUnitsPerShare = _newUnderlyingUnitsPerShare](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1048)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L1018-L1053


 - [ ] ID-141
Reentrancy in [ETHUniswapV3BaseStrategy.rebalance(int24)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279):
	External calls:
	- [harvest()](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L243)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
		- [nonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(baseMintInfo.tokenId,balanceOfToken(token0),balanceOfToken(token1),0,0,block.timestamp))](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L186-L193)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L34)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L247)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [__purge(limitMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L253)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L264)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	- [mintNewPosition(_tickFloor - limitThreshold,_tickFloor,_balance0,_balance1,false)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L272)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	- [mintNewPosition(_tickCeil,_tickCeil + limitThreshold,_balance0,_balance1,false)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L274)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	State variables written after the call(s):
	- [lastTick = _tick](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L278)
	- [lastTimestamp = block.timestamp](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L277)

contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279


 - [ ] ID-142
Reentrancy in [UniswapV3Strategy.rebalance(int24)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366):
	External calls:
	- [harvest()](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L316)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L217)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L320)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [__purge(limitMintInfo.tokenId,type()(uint128).max,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L326)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L342-L348)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	- [mintNewPosition(_tickFloor - limitThreshold,_tickFloor,_balance0,_balance1,false)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L359)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	State variables written after the call(s):
	- [mintNewPosition(_tickFloor - limitThreshold,_tickFloor,_balance0,_balance1,false)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L359)
		- [baseMintInfo = MintInfo(_tokenId,_tickLower,_tickUpper)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L469-L473)
	- [mintNewPosition(_tickFloor - limitThreshold,_tickFloor,_balance0,_balance1,false)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L359)
		- [limitMintInfo = MintInfo(_tokenId,_tickLower,_tickUpper)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L475-L479)

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366


 - [ ] ID-143
Reentrancy in [UniswapV3Strategy.rebalance(int24)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366):
	External calls:
	- [harvest()](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L316)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L217)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L320)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [__purge(limitMintInfo.tokenId,type()(uint128).max,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L326)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L342-L348)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	- [mintNewPosition(_tickCeil,_tickCeil + limitThreshold,_balance0,_balance1,false)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L361)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	State variables written after the call(s):
	- [mintNewPosition(_tickCeil,_tickCeil + limitThreshold,_balance0,_balance1,false)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L361)
		- [baseMintInfo = MintInfo(_tokenId,_tickLower,_tickUpper)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L469-L473)
	- [mintNewPosition(_tickCeil,_tickCeil + limitThreshold,_balance0,_balance1,false)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L361)
		- [limitMintInfo = MintInfo(_tokenId,_tickLower,_tickUpper)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L475-L479)

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366


 - [ ] ID-144
Reentrancy in [Vault.redeem(address,uint256,uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L240-L267):
	External calls:
	- [(_assets,_amounts) = IStrategy(_strategy).repay(_amount,_strategyAssetValue,_outputCode)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L248-L252)
	- [isKeeper()](node_modules/boc-contract-core/contracts/vault/Vault.sol#L244)
		- [accessControlProxy.checkKeeperOrVaultOrGov(msg.sender)](node_modules/boc-contract-core/contracts/access-control/AccessControlMixin.sol#L35)
	State variables written after the call(s):
	- [strategies[_strategy].totalDebt = _nowStrategyTotalDebt - _thisWithdrawValue](node_modules/boc-contract-core/contracts/vault/Vault.sol#L264)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L240-L267


 - [ ] ID-145
Reentrancy in [UniswapV3Strategy.rebalance(int24)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366):
	External calls:
	- [harvest()](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L316)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L217)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L320)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [__purge(limitMintInfo.tokenId,type()(uint128).max,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L326)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	State variables written after the call(s):
	- [limitMintInfo = MintInfo(0,0,0)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L327)

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L315-L366


 - [ ] ID-146
Reentrancy in [ETHUniswapV3BaseStrategy.rebalance(int24)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279):
	External calls:
	- [harvest()](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L243)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
		- [nonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(baseMintInfo.tokenId,balanceOfToken(token0),balanceOfToken(token1),0,0,block.timestamp))](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L186-L193)
		- [vault.report(_rewardsTokens,_claimAmounts)](contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L34)
	- [__purge(baseMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L247)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [__purge(limitMintInfo.tokenId,type()(uint128).max,0,0)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L253)
		- [(__amount0,__amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(_nftId,address(this),_amount0,_amount1))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L45-L51)
		- [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)
		- [nonfungiblePositionManager.burn(_nftId)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L114)
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L264)
		- [(_tokenId,_liquidity,_amount0,_amount1) = nonfungiblePositionManager.mint(_params)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L79)
	State variables written after the call(s):
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L264)
		- [baseMintInfo = MintInfo(tokenId,_tickLower,_tickUpper)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L343)
	- [mintNewPosition(_tickLower,_tickUpper,_balance0,_balance1,true)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L264)
		- [limitMintInfo = MintInfo(tokenId,_tickLower,_tickUpper)](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L345)

contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L242-L279


 - [ ] ID-147
Reentrancy in [Vault._repayFromWithdrawQueue(uint256)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L623-L671):
	External calls:
	- [(_assets,_amounts) = IStrategy(_strategy).repay(_strategyWithdrawValue,_strategyTotalValue,0)](node_modules/boc-contract-core/contracts/vault/Vault.sol#L648-L652)
	State variables written after the call(s):
	- [strategies[_strategy].totalDebt = _nowStrategyTotalDebt - _thisWithdrawValue](node_modules/boc-contract-core/contracts/vault/Vault.sol#L663)

node_modules/boc-contract-core/contracts/vault/Vault.sol#L623-L671


 - [ ] ID-148
Reentrancy in [ETHVault._rebase(uint256,uint256)](contracts/eth/vault/ETHVault.sol#L977-L1015):
	External calls:
	- [IPegToken(pegTokenAddress).mintShares(_treasuryAddress,_sharesAmount)](contracts/eth/vault/ETHVault.sol#L1000)
	State variables written after the call(s):
	- [underlyingUnitsPerShare = _newUnderlyingUnitsPerShare](contracts/eth/vault/ETHVault.sol#L1010)

contracts/eth/vault/ETHVault.sol#L977-L1015


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-149
[AssetHelpersOldVersion.__pushFullAssetBalances(address,address[]).i](contracts/utils/AssetHelpersOldVersion.sol#L84) is a local variable never initialized

contracts/utils/AssetHelpersOldVersion.sol#L84


 - [ ] ID-150
[AssetHelpersOldVersion.__pullPartialAssetBalances(address,address[],uint256[]).i](contracts/utils/AssetHelpersOldVersion.sol#L67) is a local variable never initialized

contracts/utils/AssetHelpersOldVersion.sol#L67


 - [ ] ID-151
[AssetHelpersOldVersion.__pullFullAssetBalances(address,address[]).i](contracts/utils/AssetHelpersOldVersion.sol#L48) is a local variable never initialized

contracts/utils/AssetHelpersOldVersion.sol#L48


 - [ ] ID-152
[AssetHelpersOldVersion.__getAssetBalances(address,address[]).i](contracts/utils/AssetHelpersOldVersion.sol#L34) is a local variable never initialized

contracts/utils/AssetHelpersOldVersion.sol#L34


 - [ ] ID-153
[DodoStrategy.get3rdPoolAssets()._targetPoolTotalAssets](contracts/usd/strategies/dodo/DodoStrategy.sol#L98) is a local variable never initialized

contracts/usd/strategies/dodo/DodoStrategy.sol#L98


 - [ ] ID-154
[ConvexMetaPoolStrategy.curveRemoveLiquidity(uint256,uint256)._index](contracts/usd/strategies/convex/meta/ConvexMetaPoolStrategy.sol#L182) is a local variable never initialized

contracts/usd/strategies/convex/meta/ConvexMetaPoolStrategy.sol#L182


 - [ ] ID-155
[Convex3CrvStrategy.curveRemoveLiquidity(uint256,uint256).index](contracts/usd/strategies/convex/Convex3CrvStrategy.sol#L139) is a local variable never initialized

contracts/usd/strategies/convex/Convex3CrvStrategy.sol#L139


 - [ ] ID-156
[ETHBaseClaimableStrategy.harvest()._wantTokens](contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L26) is a local variable never initialized

contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L26


 - [ ] ID-157
[Vault._repayFromVaultBuffer(uint256,address[],uint256[],uint256[],uint256,uint256)._totalTransferValue](node_modules/boc-contract-core/contracts/vault/Vault.sol#L685) is a local variable never initialized

node_modules/boc-contract-core/contracts/vault/Vault.sol#L685


 - [ ] ID-158
[ConvexIBUsdcStrategy.harvest()._wantTokens](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L445) is a local variable never initialized

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L445


 - [ ] ID-159
[ConvexAaveStrategy.curveRemoveLiquidity(uint256,uint256)._index](contracts/usd/strategies/convex/ConvexAaveStrategy.sol#L145) is a local variable never initialized

contracts/usd/strategies/convex/ConvexAaveStrategy.sol#L145


 - [ ] ID-160
[Vault.lend(address,IExchangeAggregator.ExchangeToken[])._rewardTokens](node_modules/boc-contract-core/contracts/vault/Vault.sol#L324) is a local variable never initialized

node_modules/boc-contract-core/contracts/vault/Vault.sol#L324


 - [ ] ID-161
[ERC1967Upgrade._upgradeToAndCallUUPS(address,bytes,bool).slot](node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L92) is a local variable never initialized

node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L92


 - [ ] ID-162
[ETHBaseClaimableStrategy.harvest()._wantAmounts](contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L27) is a local variable never initialized

contracts/eth/strategies/ETHBaseClaimableStrategy.sol#L27


 - [ ] ID-163
[UniswapV3Strategy.harvest()._amount1_scope_1](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L212) is a local variable never initialized

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L212


 - [ ] ID-164
[Vault._exchangeAndCalculateReceivedAmounts(address,uint256[],address[],IExchangeAggregator.ExchangeToken[])._toTokenAmount](node_modules/boc-contract-core/contracts/vault/Vault.sol#L811) is a local variable never initialized

node_modules/boc-contract-core/contracts/vault/Vault.sol#L811


 - [ ] ID-165
[SqrtPriceMath.getNextSqrtPriceFromAmount0RoundingUp(uint160,uint128,uint256,bool).product_scope_0](node_modules/@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol#L49) is a local variable never initialized

node_modules/@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol#L49


 - [ ] ID-166
[Vault.lend(address,IExchangeAggregator.ExchangeToken[])._claimAmounts](node_modules/boc-contract-core/contracts/vault/Vault.sol#L325) is a local variable never initialized

node_modules/boc-contract-core/contracts/vault/Vault.sol#L325


 - [ ] ID-167
[Vault._transfer(uint256[],address[],uint256[],uint256[])._actualAmount](node_modules/boc-contract-core/contracts/vault/Vault.sol#L853) is a local variable never initialized

node_modules/boc-contract-core/contracts/vault/Vault.sol#L853


 - [ ] ID-168
[Aura3PoolStrategy._withdrawFromBalancer(uint256,uint256).index](contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L217) is a local variable never initialized

contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L217


 - [ ] ID-169
[ConvexIBUsdcStrategy.harvest()._rewardTokens](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L443) is a local variable never initialized

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L443


 - [ ] ID-170
[UniswapV3ActionsMixin.__uniswapV3Swap(address,address[],uint24[],uint256,uint256)._encodedPath](contracts/utils/actions/UniswapV3ActionsMixin.sol#L33) is a local variable never initialized

contracts/utils/actions/UniswapV3ActionsMixin.sol#L33


 - [ ] ID-171
[Vault.lend(address,IExchangeAggregator.ExchangeToken[])._lendValue](node_modules/boc-contract-core/contracts/vault/Vault.sol#L303) is a local variable never initialized

node_modules/boc-contract-core/contracts/vault/Vault.sol#L303


 - [ ] ID-172
[ETHVault._checkAndExchange(address,IExchangeAggregator.ExchangeToken[])._toAmount](contracts/eth/vault/ETHVault.sol#L1051) is a local variable never initialized

contracts/eth/vault/ETHVault.sol#L1051


 - [ ] ID-173
[UniswapV3Strategy.harvest()._amount0_scope_0](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L212) is a local variable never initialized

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L212


 - [ ] ID-174
[ETHVault._transfer(uint256[],address[],uint256[],uint256[])._actualAmount](contracts/eth/vault/ETHVault.sol#L830) is a local variable never initialized

contracts/eth/vault/ETHVault.sol#L830


 - [ ] ID-175
[ConvexIBUsdcStrategy.harvest()._rewardAmounts](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L444) is a local variable never initialized

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L444


 - [ ] ID-176
[ETHVault.lend(address,IExchangeAggregator.ExchangeToken[])._ethAmount](contracts/eth/vault/ETHVault.sol#L296) is a local variable never initialized

contracts/eth/vault/ETHVault.sol#L296


 - [ ] ID-177
[DodoV1Strategy.get3rdPoolAssets()._targetPoolTotalAssets](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L124) is a local variable never initialized

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L124


 - [ ] ID-178
[ETHVault._repayFromVaultBuffer(uint256,address[],uint256[],uint256[],uint256,uint256)._totalTransferValue](contracts/eth/vault/ETHVault.sol#L704) is a local variable never initialized

contracts/eth/vault/ETHVault.sol#L704


 - [ ] ID-179
[Vault._totalValueInVault(address[],uint256[],uint256[])._totalValueInVault](node_modules/boc-contract-core/contracts/vault/Vault.sol#L566) is a local variable never initialized

node_modules/boc-contract-core/contracts/vault/Vault.sol#L566


 - [ ] ID-180
[Vault._checkAndExchange(address,IExchangeAggregator.ExchangeToken[])._toAmount](node_modules/boc-contract-core/contracts/vault/Vault.sol#L1089) is a local variable never initialized

node_modules/boc-contract-core/contracts/vault/Vault.sol#L1089


 - [ ] ID-181
[ETHVault.lend(address,IExchangeAggregator.ExchangeToken[])._lendValue](contracts/eth/vault/ETHVault.sol#L295) is a local variable never initialized

contracts/eth/vault/ETHVault.sol#L295


 - [ ] ID-182
[ConvexIBUsdcStrategy.harvest()._wantAmounts](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L446) is a local variable never initialized

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L446


 - [ ] ID-183
[ETHVault._totalAssetInOwner(address[],uint256[],uint256[],address)._totalAssetInOwne](contracts/eth/vault/ETHVault.sol#L1246) is a local variable never initialized

contracts/eth/vault/ETHVault.sol#L1246


 - [ ] ID-184
[SqrtPriceMath.getNextSqrtPriceFromAmount0RoundingUp(uint160,uint128,uint256,bool).product](node_modules/@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol#L39) is a local variable never initialized

node_modules/@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol#L39


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-185
[ConvexUsdtStrategy.curveAddLiquidity(address[],uint256[])](contracts/usd/strategies/convex/ConvexUsdtStrategy.sol#L65-L88) ignores return value by [ICToken(cDAI).mint(_amounts[0])](contracts/usd/strategies/convex/ConvexUsdtStrategy.sol#L73)

contracts/usd/strategies/convex/ConvexUsdtStrategy.sol#L65-L88


 - [ ] ID-186
[ConvexIBUsdtStrategy._redeem(uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L545-L550) ignores return value by [IConvex(BOOSTER).withdraw(pId,_cvxLpAmount)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L547)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L545-L550


 - [ ] ID-187
[ConvexSusdStrategy.claimRewards()](contracts/usd/strategies/convex/ConvexSusdStrategy.sol#L137-L151) ignores return value by [IConvexReward(rewardPool).getReward()](contracts/usd/strategies/convex/ConvexSusdStrategy.sol#L142)

contracts/usd/strategies/convex/ConvexSusdStrategy.sol#L137-L151


 - [ ] ID-188
[ConvexBaseStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L48-L55) ignores return value by [getRewardPool().withdrawAndUnwrap(_lpAmount,false)](contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L52)

contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L48-L55


 - [ ] ID-189
[AccessControlEnumerable._grantRole(bytes32,address)](node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol#L52-L55) ignores return value by [_roleMembers[role].add(account)](node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol#L54)

node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol#L52-L55


 - [ ] ID-190
[VaultBuffer._burn(address,uint256)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L396-L416) ignores return value by [mBalances.remove(_account)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L406)

node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L396-L416


 - [ ] ID-191
[ConvexIBUsdcStrategy._borrowForex(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L618-L623) ignores return value by [_borrowC.borrow(_borrowAmount)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L621)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L618-L623


 - [ ] ID-192
[ConvexIBUsdcStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L726-L769) ignores return value by [ICurveMini(curvePool).exchange(0,1,_profit,0)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L766)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L726-L769


 - [ ] ID-193
[ConvexIBUsdtStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L567-L614) ignores return value by [IUniswapV2Router2(SUSHI_ROUTER_ADDR).swapExactTokensForTokens(_profit,0,rewardRoutes[_borrowToken],address(this),block.timestamp)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L597-L603)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L567-L614


 - [ ] ID-194
[ETHExchanger.rEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L90-L105) ignores return value by [IERC20(rETH).approve(UNISWAP_V3_ROUTER,0)](contracts/eth/exchanges/ETHExchanger.sol#L95)

contracts/eth/exchanges/ETHExchanger.sol#L90-L105


 - [ ] ID-195
[SushiKashiStakeStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/sushi/kashi/stake/SushiKashiStakeStrategy.sol#L147-L170) ignores return value by [bentoBox.withdraw(_want,address(this),address(this),0,_share)](contracts/usd/strategies/sushi/kashi/stake/SushiKashiStakeStrategy.sol#L169)

contracts/usd/strategies/sushi/kashi/stake/SushiKashiStakeStrategy.sol#L147-L170


 - [ ] ID-196
[MockEthStrategy.depositTo3rdPool(address[],uint256[])](contracts/eth/mock/MockEthStrategy.sol#L107-L114) ignores return value by [IERC20Upgradeable(stETH).approve(address(mock3rdPool),_amounts[1])](contracts/eth/mock/MockEthStrategy.sol#L112)

contracts/eth/mock/MockEthStrategy.sol#L107-L114


 - [ ] ID-197
[ConvexSETHStrategy.depositTo3rdPool(address[],uint256[])](contracts/eth/strategies/convex/ConvexSETHStrategy.sol#L129-L138) ignores return value by [BOOSTER.deposit(getPid(),_liquidity,true)](contracts/eth/strategies/convex/ConvexSETHStrategy.sol#L137)

contracts/eth/strategies/convex/ConvexSETHStrategy.sol#L129-L138


 - [ ] ID-198
[ETHVaultAdmin._removeStrategy(address,bool)](contracts/eth/vault/ETHVaultAdmin.sol#L258-L290) ignores return value by [strategySet.remove(_addr)](contracts/eth/vault/ETHVaultAdmin.sol#L288)

contracts/eth/vault/ETHVaultAdmin.sol#L258-L290


 - [ ] ID-199
[ConvexIBUsdtStrategy._mintCollateralCToken(uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L466-L477) ignores return value by [COLLATERAL_CTOKEN.mint(mintAmount)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L472)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L466-L477


 - [ ] ID-200
[HarvestHelper.batchHarvest(address[])](contracts/utils/HarvestHelper.sol#L18-L24) ignores return value by [IETHStrategy(_strategyAddrs[i]).harvest()](contracts/utils/HarvestHelper.sol#L21)

contracts/utils/HarvestHelper.sol#L18-L24


 - [ ] ID-201
[VaultAdmin._removeStrategy(address,bool)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260) ignores return value by [trackedAssetsMap.remove(_wantToken)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L251)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260


 - [ ] ID-202
[Harvester.collect(address[])](node_modules/boc-contract-core/contracts/harvester/Harvester.sol#L74-L80) ignores return value by [IStrategy(_strategy).harvest()](node_modules/boc-contract-core/contracts/harvester/Harvester.sol#L78)

node_modules/boc-contract-core/contracts/harvester/Harvester.sol#L74-L80


 - [ ] ID-203
[AuraWstETHWETHStrategy.claimRewards()](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L269-L301) ignores return value by [IRewardPool(_rewardPool).getReward()](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L282)

contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L269-L301


 - [ ] ID-204
[ERC1967Upgrade._upgradeToAndCallUUPS(address,bytes,bool)](node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L81-L99) ignores return value by [IERC1822Proxiable(newImplementation).proxiableUUID()](node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L92-L96)

node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L81-L99


 - [ ] ID-205
[IterableIntMap._plus(IterableIntMap.Map,address,int256)](node_modules/boc-contract-core/contracts/library/IterableIntMap.sol#L37-L40) ignores return value by [map._keys.add(key)](node_modules/boc-contract-core/contracts/library/IterableIntMap.sol#L39)

node_modules/boc-contract-core/contracts/library/IterableIntMap.sol#L37-L40


 - [ ] ID-206
[ETHVaultAdmin._removeStrategy(address,bool)](contracts/eth/vault/ETHVaultAdmin.sol#L258-L290) ignores return value by [trackedAssetsMap.remove(_wantToken)](contracts/eth/vault/ETHVaultAdmin.sol#L280)

contracts/eth/vault/ETHVaultAdmin.sol#L258-L290


 - [ ] ID-207
[ConvexIBUsdtStrategy._redeem(uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L545-L550) ignores return value by [IConvexReward(rewardPool).withdraw(_cvxLpAmount,false)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L546)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L545-L550


 - [ ] ID-208
[DodoV1Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243) ignores return value by [DodoVaultV1(_lpTokenPool).withdrawQuote((_quoteWithdrawAmount * _quoteExpectedTarget) / _totalQuoteCapital)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L225-L227)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243


 - [ ] ID-209
[StakeWiseEthSeth23000Strategy.swapRewardsToWants()](contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L36-L67) ignores return value by [IERC20(RETH2).approve(UNISWAP_V3_ROUTER,_balanceOfRETH2)](contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L46)

contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L36-L67


 - [ ] ID-210
[ConvexSaaveStrategy.claimRewards()](contracts/usd/strategies/convex/ConvexSaaveStrategy.sol#L143-L157) ignores return value by [IConvexReward(rewardPool).getReward()](contracts/usd/strategies/convex/ConvexSaaveStrategy.sol#L148)

contracts/usd/strategies/convex/ConvexSaaveStrategy.sol#L143-L157


 - [ ] ID-211
[DodoV1Strategy._depositQuoteToken(address,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L190-L201) ignores return value by [DodoVaultV1(_lpTokenPool).depositQuote(_amount)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L195)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L190-L201


 - [ ] ID-212
[DodoV1Strategy._depositBaseToken(address,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L177-L188) ignores return value by [DodoVaultV1(_lpTokenPool).depositBase(_amount)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L182)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L177-L188


 - [ ] ID-213
[VaultAdmin.removeAsset(address)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L149-L164) ignores return value by [assetSet.remove(_asset)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L155)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L149-L164


 - [ ] ID-214
[ConvexIBUsdcStrategy.exitCollateralInvestToCurvePool(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L636-L661) ignores return value by [CTokenInterface(_collaterCTokenAddr).redeem(MathUpgradeable.min(_exitCollateralC,balanceOfToken(_collaterCTokenAddr)))](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L656-L658)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L636-L661


 - [ ] ID-215
[ETHUniswapV3BaseStrategy.depositTo3rdPool(address[],uint256[])](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L174-L196) ignores return value by [nonfungiblePositionManager.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams(baseMintInfo.tokenId,balanceOfToken(token0),balanceOfToken(token1),0,0,block.timestamp))](contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L186-L193)

contracts/eth/strategies/uniswapv3/ETHUniswapV3BaseStrategy.sol#L174-L196


 - [ ] ID-216
[ETHVaultAdmin.addAsset(address)](contracts/eth/vault/ETHVaultAdmin.sol#L157-L165) ignores return value by [assetSet.add(_asset)](contracts/eth/vault/ETHVaultAdmin.sol#L159)

contracts/eth/vault/ETHVaultAdmin.sol#L157-L165


 - [ ] ID-217
[IterableIntMap._minus(IterableIntMap.Map,address,int256)](node_modules/boc-contract-core/contracts/library/IterableIntMap.sol#L49-L52) ignores return value by [map._keys.add(key)](node_modules/boc-contract-core/contracts/library/IterableIntMap.sol#L51)

node_modules/boc-contract-core/contracts/library/IterableIntMap.sol#L49-L52


 - [ ] ID-218
[ETHExchanger.eth2wstEth(address)](contracts/eth/exchanges/ETHExchanger.sol#L49-L62) ignores return value by [IERC20(stETH).approve(wstETH,_stEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L58)

contracts/eth/exchanges/ETHExchanger.sol#L49-L62


 - [ ] ID-219
[ConvexIBUsdcStrategy._mintCollateralCToken(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L578-L590) ignores return value by [COMPTROLLER.enterMarkets(_markets)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L589)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L578-L590


 - [ ] ID-220
[IterableUintMap._plus(IterableUintMap.Map,address,uint256)](node_modules/boc-contract-core/contracts/library/IterableUintMap.sol#L37-L40) ignores return value by [map._keys.add(key)](node_modules/boc-contract-core/contracts/library/IterableUintMap.sol#L39)

node_modules/boc-contract-core/contracts/library/IterableUintMap.sol#L37-L40


 - [ ] ID-221
[VaultAdmin.addAsset(address)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L137-L146) ignores return value by [IValueInterpreter(valueInterpreter).price(_asset)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L142)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L137-L146


 - [ ] ID-222
[MockEthStrategy.depositTo3rdPool(address[],uint256[])](contracts/eth/mock/MockEthStrategy.sol#L107-L114) ignores return value by [IERC20Upgradeable(stETH).approve(address(mock3rdPool),0)](contracts/eth/mock/MockEthStrategy.sol#L111)

contracts/eth/mock/MockEthStrategy.sol#L107-L114


 - [ ] ID-223
[ConvexIBUsdcStrategy.increaseCollateral(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L664-L683) ignores return value by [IConvexReward(rewardPool).withdraw(_removeLp,false)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L677)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L664-L683


 - [ ] ID-224
[UniswapV2LiquidityActionsMixin.__uniswapV2Redeem(address,address,uint256,address,address,uint256,uint256)](contracts/utils/actions/UniswapV2LiquidityActionsMixin.sol#L45-L66) ignores return value by [IUniswapV2Router2(UniswapV2Router2).removeLiquidity(_tokenA,_tokenB,_poolTokenAmount,_amountAMin,_amountBMin,_recipient,__uniswapV2GetActionDeadline())](contracts/utils/actions/UniswapV2LiquidityActionsMixin.sol#L57-L65)

contracts/utils/actions/UniswapV2LiquidityActionsMixin.sol#L45-L66


 - [ ] ID-225
[VaultAdmin._removeStrategy(address,bool)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260) ignores return value by [IStrategy(_addr).repay(MAX_BPS,MAX_BPS,0)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L236-L240)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260


 - [ ] ID-226
[ConvexBaseStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L64-L77) ignores return value by [BOOSTER.withdraw(pid,_lpAmount)](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L73)

contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L64-L77


 - [ ] ID-227
[VaultBuffer._transfer(address,address,uint256)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L337-L362) ignores return value by [mBalances.remove(_from)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L352)

node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L337-L362


 - [ ] ID-228
[ETHExchanger.stEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L38-L47) ignores return value by [ICurveFi(CURVE_ETH_STETH_POOL).exchange(1,0,_stEthAmount,0)](contracts/eth/exchanges/ETHExchanger.sol#L43)

contracts/eth/exchanges/ETHExchanger.sol#L38-L47


 - [ ] ID-229
[ConvexIBUsdcStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L726-L769) ignores return value by [_collateralC.redeem(_burnAmount)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L762)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L726-L769


 - [ ] ID-230
[ConvexIBUsdtStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L567-L614) ignores return value by [_collateralC.redeem(_burnAmount)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L593)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L567-L614


 - [ ] ID-231
[ExchangeAggregator.__addExchangeAdapters(address[])](node_modules/boc-contract-core/contracts/exchanges/ExchangeAggregator.sol#L102-L107) ignores return value by [exchangeAdapters.add(_exchangeAdapters[i])](node_modules/boc-contract-core/contracts/exchanges/ExchangeAggregator.sol#L104)

node_modules/boc-contract-core/contracts/exchanges/ExchangeAggregator.sol#L102-L107


 - [ ] ID-232
[StakeWiseEthSeth23000Strategy.swapRewardsToWants()](contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L36-L67) ignores return value by [IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(IUniswapV3.ExactInputSingleParams(RETH2,SETH2,500,address(this),block.timestamp,_balanceOfRETH2,0,0))](contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L47)

contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L36-L67


 - [ ] ID-233
[AuraREthWEthStrategy.swapRewardsToWants()](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L288-L327) ignores return value by [UNIROUTER2.swapExactTokensForTokens(_balanceOfAura,0,swapRewardRoutes[AURA_TOKEN],address(this),block.timestamp)](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L309-L315)

contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L288-L327


 - [ ] ID-234
[ConvexIBUsdcStrategy._redeem(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L771-L776) ignores return value by [IConvexReward(rewardPool).withdraw(_cvxLpAmount,false)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L772)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L771-L776


 - [ ] ID-235
[MockVault.redeem(address,uint256,uint256)](contracts/usd/mock/MockVault.sol#L37-L43) ignores return value by [IStrategy(_strategy).repay(_usdValue,_totalValue,_outputCode)](contracts/usd/mock/MockVault.sol#L42)

contracts/usd/mock/MockVault.sol#L37-L43


 - [ ] ID-236
[ConvexCompoundStrategy.curveAddLiquidity(address[],uint256[])](contracts/usd/strategies/convex/ConvexCompoundStrategy.sol#L88-L109) ignores return value by [ICToken(_cTokens[i]).mint(_amounts[i])](contracts/usd/strategies/convex/ConvexCompoundStrategy.sol#L101)

contracts/usd/strategies/convex/ConvexCompoundStrategy.sol#L88-L109


 - [ ] ID-237
[ConvexIBUsdtStrategy._invest(uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L489-L501) ignores return value by [IConvex(_booster).deposit(pId,_liquidity,true)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L499)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L489-L501


 - [ ] ID-238
[MockEthStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/eth/mock/MockEthStrategy.sol#L116-L121) ignores return value by [mock3rdPool.withdraw()](contracts/eth/mock/MockEthStrategy.sol#L120)

contracts/eth/mock/MockEthStrategy.sol#L116-L121


 - [ ] ID-239
[UniswapV3LiquidityActionsMixin.__purge(uint256,uint128,uint256,uint256)](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L87-L117) ignores return value by [nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams(_nftId,_liquidity,_amount0Min,_amount1Min,block.timestamp))](contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L102-L108)

contracts/utils/actions/UniswapV3LiquidityActionsMixin.sol#L87-L117


 - [ ] ID-240
[StargateSingleStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/stargate/StargateSingleStrategy.sol#L141-L153) ignores return value by [stargateRouterPool.instantRedeemLocal(uint16(poolId),_lpAmount,address(this))](contracts/usd/strategies/stargate/StargateSingleStrategy.sol#L151)

contracts/usd/strategies/stargate/StargateSingleStrategy.sol#L141-L153


 - [ ] ID-241
[ETHExchanger.wstEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L64-L77) ignores return value by [IERC20(stETH).approve(CURVE_ETH_STETH_POOL,0)](contracts/eth/exchanges/ETHExchanger.sol#L70)

contracts/eth/exchanges/ETHExchanger.sol#L64-L77


 - [ ] ID-242
[UniswapV3Strategy.depositTo3rdPool(address[],uint256[])](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L220-L253) ignores return value by [nonfungiblePositionManager.increaseLiquidity(_params)](contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L250)

contracts/usd/strategies/uniswapv3/UniswapV3Strategy.sol#L220-L253


 - [ ] ID-243
[DodoStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/dodo/DodoStrategy.sol#L149-L169) ignores return value by [DodoVault(lpTokenPool).sellShares(_withdrawAmount,address(this),0,0,,block.timestamp + 600)](contracts/usd/strategies/dodo/DodoStrategy.sol#L160-L167)

contracts/usd/strategies/dodo/DodoStrategy.sol#L149-L169


 - [ ] ID-244
[StakeWiseReth2Seth2500Strategy.swapRewardsToWants()](contracts/eth/strategies/stakewise/StakeWiseReth2Seth2500Strategy.sol#L36-L56) ignores return value by [IERC20(SWISE).approve(UNISWAP_V3_ROUTER,_balanceOfSwise)](contracts/eth/strategies/stakewise/StakeWiseReth2Seth2500Strategy.sol#L50)

contracts/eth/strategies/stakewise/StakeWiseReth2Seth2500Strategy.sol#L36-L56


 - [ ] ID-245
[ConvexIBUsdtStrategy._borrowForex(uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L504-L509) ignores return value by [_borrowC.borrow(_borrowAmount)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L507)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L504-L509


 - [ ] ID-246
[ERC1967Upgrade._upgradeBeaconToAndCall(address,bytes,bool)](node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L174-L184) ignores return value by [Address.functionDelegateCall(IBeacon(newBeacon).implementation(),data)](node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L182)

node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L174-L184


 - [ ] ID-247
[VaultAdmin._removeStrategy(address,bool)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260) ignores return value by [strategySet.remove(_addr)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L258)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L233-L260


 - [ ] ID-248
[ETHExchanger.stEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L38-L47) ignores return value by [IERC20(stETH).approve(CURVE_ETH_STETH_POOL,0)](contracts/eth/exchanges/ETHExchanger.sol#L40)

contracts/eth/exchanges/ETHExchanger.sol#L38-L47


 - [ ] ID-249
[UniswapV2ActionsMixin.__uniswapV2Swap(address,uint256,uint256,address[])](contracts/utils/actions/UniswapV2ActionsMixin.sol#L23-L39) ignores return value by [IUniswapV2Router2(UNISWAP_V2_ROUTER2).swapExactTokensForTokens(_outgoingAssetAmount,_minIncomingAssetAmount,_path,_recipient,__uniswapV2GetActionDeadline())](contracts/utils/actions/UniswapV2ActionsMixin.sol#L32-L38)

contracts/utils/actions/UniswapV2ActionsMixin.sol#L23-L39


 - [ ] ID-250
[ETHExchanger.wstEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L64-L77) ignores return value by [IERC20(stETH).approve(CURVE_ETH_STETH_POOL,_stEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L71)

contracts/eth/exchanges/ETHExchanger.sol#L64-L77


 - [ ] ID-251
[ConvexIBUsdtStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L567-L614) ignores return value by [IUniswapV2Router2(UNI_ROUTER_ADDR).swapExactTokensForTokens(_usdcBalance,0,rewardRoutes[USDC],address(this),block.timestamp)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L605-L611)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L567-L614


 - [ ] ID-252
[ETHExchanger.rEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L90-L105) ignores return value by [IERC20(rETH).approve(UNISWAP_V3_ROUTER,_rEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L96)

contracts/eth/exchanges/ETHExchanger.sol#L90-L105


 - [ ] ID-253
[AccessControlEnumerable._revokeRole(bytes32,address)](node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol#L60-L63) ignores return value by [_roleMembers[role].remove(account)](node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol#L62)

node_modules/@openzeppelin/contracts/access/AccessControlEnumerable.sol#L60-L63


 - [ ] ID-254
[ConvexIBUsdtStrategy._sellCrvAndCvx(uint256,uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L364-L430) ignores return value by [IUniswapV2Router2(SUSHI_ROUTER_ADDR).swapExactTokensForTokens(balanceOfToken(WETH),0,rewardRoutes[WETH],address(this),block.timestamp)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L408-L414)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L364-L430


 - [ ] ID-255
[VaultAdmin._addStrategy(address,uint256,uint256)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L198-L212) ignores return value by [strategySet.add(_strategy)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L211)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L198-L212


 - [ ] ID-256
[ERC1967Upgrade._upgradeToAndCall(address,bytes,bool)](node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L65-L74) ignores return value by [Address.functionDelegateCall(newImplementation,data)](node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L72)

node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L65-L74


 - [ ] ID-257
[ETHExchanger.eth2rEth(address)](contracts/eth/exchanges/ETHExchanger.sol#L79-L88) ignores return value by [IERC20(wETH).approve(UNISWAP_V3_ROUTER,_wethAmount)](contracts/eth/exchanges/ETHExchanger.sol#L85)

contracts/eth/exchanges/ETHExchanger.sol#L79-L88


 - [ ] ID-258
[ETHExchanger.eth2stEth(address)](contracts/eth/exchanges/ETHExchanger.sol#L28-L36) ignores return value by [ICurveFi(CURVE_ETH_STETH_POOL).exchange{value: _ethAmount}(0,1,_ethAmount,0)](contracts/eth/exchanges/ETHExchanger.sol#L32)

contracts/eth/exchanges/ETHExchanger.sol#L28-L36


 - [ ] ID-259
[ETHExchanger.eth2wstEth(address)](contracts/eth/exchanges/ETHExchanger.sol#L49-L62) ignores return value by [ICurveFi(CURVE_ETH_STETH_POOL).exchange{value: _ethAmount}(0,1,_ethAmount,0)](contracts/eth/exchanges/ETHExchanger.sol#L53)

contracts/eth/exchanges/ETHExchanger.sol#L49-L62


 - [ ] ID-260
[VaultBuffer._transfer(address,address,uint256)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L337-L362) ignores return value by [mBalances.set(_from,_newBalance)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L354)

node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L337-L362


 - [ ] ID-261
[AuraREthWEthStrategy.claimRewards()](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L265-L286) ignores return value by [IRewardPool(_rewardPool).getReward()](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L278)

contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L265-L286


 - [ ] ID-262
[AuraWstETHWETHStrategy.depositTo3rdPool(address[],uint256[])](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L196-L202) ignores return value by [AURA_BOOSTER.deposit(getPId(),_receiveLpAmount,true)](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L201)

contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L196-L202


 - [ ] ID-263
[ConvexIBUsdcStrategy._redeem(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L771-L776) ignores return value by [IConvex(BOOSTER).withdraw(pId,_cvxLpAmount)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L773)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L771-L776


 - [ ] ID-264
[MockVault.redeem(address,uint256,uint256)](contracts/eth/mock/MockVault.sol#L61-L71) ignores return value by [IETHStrategy(_strategy).repay(_usdValue,_totalValue,_outputCode)](contracts/eth/mock/MockVault.sol#L70)

contracts/eth/mock/MockVault.sol#L61-L71


 - [ ] ID-265
[AuraREthWEthStrategy.swapRewardsToWants()](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L288-L327) ignores return value by [UNIROUTER2.swapExactTokensForTokens(_balanceOfBal,0,swapRewardRoutes[BAL],address(this),block.timestamp)](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L295-L301)

contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L288-L327


 - [ ] ID-266
[YearnV2Strategy.depositTo3rdPool(address[],uint256[])](contracts/eth/strategies/yearn/v2/YearnV2Strategy.sol#L80-L90) ignores return value by [yVault.deposit(_amounts[0])](contracts/eth/strategies/yearn/v2/YearnV2Strategy.sol#L89)

contracts/eth/strategies/yearn/v2/YearnV2Strategy.sol#L80-L90


 - [ ] ID-267
[ETHVaultAdmin._removeStrategy(address,bool)](contracts/eth/vault/ETHVaultAdmin.sol#L258-L290) ignores return value by [IETHStrategy(_addr).repay(MAX_BPS,MAX_BPS,0)](contracts/eth/vault/ETHVaultAdmin.sol#L261-L265)

contracts/eth/vault/ETHVaultAdmin.sol#L258-L290


 - [ ] ID-268
[ETHVaultAdmin._addStrategy(address,uint256,uint256)](contracts/eth/vault/ETHVaultAdmin.sol#L223-L237) ignores return value by [strategySet.add(strategy)](contracts/eth/vault/ETHVaultAdmin.sol#L236)

contracts/eth/vault/ETHVaultAdmin.sol#L223-L237


 - [ ] ID-269
[ConvexIBUsdcStrategy._invest(uint256,uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L603-L615) ignores return value by [IConvex(_booster).deposit(pId,_liquidity,true)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L613)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L603-L615


 - [ ] ID-270
[ConvexBaseStrategy.claimRewards()](contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L58-L78) ignores return value by [getRewardPool().getReward()](contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L70)

contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L58-L78


 - [ ] ID-271
[StakeWiseEthSeth23000Strategy.swapRewardsToWants()](contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L36-L67) ignores return value by [IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(IUniswapV3.ExactInputSingleParams(SWISE,SETH2,3000,address(this),block.timestamp,_balanceOfSwise,0,0))](contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L55)

contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L36-L67


 - [ ] ID-272
[ConvexIBUsdcStrategy.harvest()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L433-L483) ignores return value by [IConvexReward(_rewardPool).getReward()](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L448)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L433-L483


 - [ ] ID-273
[AuraREthWEthStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L220-L229) ignores return value by [IRewardPool(getRewardPool()).redeem(_withdrawAmount,address(this),address(this))](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L227)

contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L220-L229


 - [ ] ID-274
[ETHExchanger.eth2wstEth(address)](contracts/eth/exchanges/ETHExchanger.sol#L49-L62) ignores return value by [IERC20(stETH).approve(wstETH,0)](contracts/eth/exchanges/ETHExchanger.sol#L57)

contracts/eth/exchanges/ETHExchanger.sol#L49-L62


 - [ ] ID-275
[AuraWstETHWETHStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L224-L233) ignores return value by [IRewardPool(getRewardPool()).redeem(_withdrawAmount,address(this),address(this))](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L231)

contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L224-L233


 - [ ] ID-276
[ConvexBaseStrategy.depositTo3rdPool(address[],uint256[])](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L47-L59) ignores return value by [BOOSTER.deposit(pid,_liquidity,true)](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L57)

contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L47-L59


 - [ ] ID-277
[ConvexIBUsdtStrategy._mintCollateralCToken(uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L466-L477) ignores return value by [COMPTROLLER.enterMarkets(_markets)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L476)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L466-L477


 - [ ] ID-278
[ConvexIBUsdcStrategy.increaseCollateral(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L664-L683) ignores return value by [IConvex(BOOSTER).withdraw(pId,_removeLp)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L678)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L664-L683


 - [ ] ID-279
[VaultBuffer._burn(address,uint256)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L396-L416) ignores return value by [mBalances.set(_account,newBalance)](node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L408)

node_modules/boc-contract-core/contracts/vault/VaultBuffer.sol#L396-L416


 - [ ] ID-280
[ConvexIBUsdcStrategy._repayForex(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L626-L633) ignores return value by [_borrowC.repayBorrow(_repayAmount)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L632)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L626-L633


 - [ ] ID-281
[ConvexIBUsdtStrategy._sellCrvAndCvx(uint256,uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L364-L430) ignores return value by [ICurveMini(curveUsdcIbforexPool).exchange(1,0,_usdcBalanceAfterSellWeth,0)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L428)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L364-L430


 - [ ] ID-282
[ETHVaultAdmin.removeAsset(address)](contracts/eth/vault/ETHVaultAdmin.sol#L168-L192) ignores return value by [trackedAssetsMap.remove(_asset)](contracts/eth/vault/ETHVaultAdmin.sol#L188)

contracts/eth/vault/ETHVaultAdmin.sol#L168-L192


 - [ ] ID-283
[ETHExchanger.stEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L38-L47) ignores return value by [IERC20(stETH).approve(CURVE_ETH_STETH_POOL,_stEthAmount)](contracts/eth/exchanges/ETHExchanger.sol#L41)

contracts/eth/exchanges/ETHExchanger.sol#L38-L47


 - [ ] ID-284
[StakeWiseEthSeth23000Strategy.swapRewardsToWants()](contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L36-L67) ignores return value by [IERC20(SWISE).approve(UNISWAP_V3_ROUTER,_balanceOfSwise)](contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L54)

contracts/eth/strategies/stakewise/StakeWiseEthSeth23000Strategy.sol#L36-L67


 - [ ] ID-285
[IterableUintMap._minus(IterableUintMap.Map,address,uint256)](node_modules/boc-contract-core/contracts/library/IterableUintMap.sol#L49-L52) ignores return value by [map._keys.add(key)](node_modules/boc-contract-core/contracts/library/IterableUintMap.sol#L51)

node_modules/boc-contract-core/contracts/library/IterableUintMap.sol#L49-L52


 - [ ] ID-286
[StakeWiseReth2Seth2500Strategy.swapRewardsToWants()](contracts/eth/strategies/stakewise/StakeWiseReth2Seth2500Strategy.sol#L36-L56) ignores return value by [IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(IUniswapV3.ExactInputSingleParams(SWISE,SETH2,3000,address(this),block.timestamp,_balanceOfSwise,0,0))](contracts/eth/strategies/stakewise/StakeWiseReth2Seth2500Strategy.sol#L51)

contracts/eth/strategies/stakewise/StakeWiseReth2Seth2500Strategy.sol#L36-L56


 - [ ] ID-287
[AuraREthWEthStrategy.depositTo3rdPool(address[],uint256[])](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L192-L198) ignores return value by [AURA_BOOSTER.deposit(getPId(),_receiveLpAmount,true)](contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L197)

contracts/eth/strategies/aura/AuraREthWEthStrategy.sol#L192-L198


 - [ ] ID-288
[ConvexBaseStrategy.swapRewardsToWants()](contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L80-L103) ignores return value by [ROUTER2.swapExactTokensForTokens(_rewardAmount,0,uniswapRewardRoutes[_rewardTokens[i]],address(this),block.timestamp)](contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L93)

contracts/eth/strategies/convex/ConvexBaseStrategy.sol#L80-L103


 - [ ] ID-289
[ETHExchanger.wstEth2Eth(address,uint256)](contracts/eth/exchanges/ETHExchanger.sol#L64-L77) ignores return value by [ICurveFi(CURVE_ETH_STETH_POOL).exchange(1,0,_stEthAmount,0)](contracts/eth/exchanges/ETHExchanger.sol#L73)

contracts/eth/exchanges/ETHExchanger.sol#L64-L77


 - [ ] ID-290
[ExchangeAggregator.removeExchangeAdapters(address[])](node_modules/boc-contract-core/contracts/exchanges/ExchangeAggregator.sol#L43-L54) ignores return value by [exchangeAdapters.remove(_exchangeAdapters[i])](node_modules/boc-contract-core/contracts/exchanges/ExchangeAggregator.sol#L51)

node_modules/boc-contract-core/contracts/exchanges/ExchangeAggregator.sol#L43-L54


 - [ ] ID-291
[AuraWstETHWETHStrategy.swapRewardsToWants()](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L303-L358) ignores return value by [UNIROUTER2.swapExactTokensForTokens(_balanceOfBal,0,swapRewardRoutes[BAL],address(this),block.timestamp)](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L310-L316)

contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L303-L358


 - [ ] ID-292
[ConvexBaseStrategy.claimRewards()](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L79-L92) ignores return value by [IConvexReward(rewardPool).getReward()](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L85)

contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L79-L92


 - [ ] ID-293
[Aura3PoolStrategy.depositTo3rdPool(address[],uint256[])](contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L171-L177) ignores return value by [AURA_BOOSTER.deposit(getPId(),_receiveLpAmount,true)](contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L176)

contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L171-L177


 - [ ] ID-294
[ETHExchanger.eth2rEth(address)](contracts/eth/exchanges/ETHExchanger.sol#L79-L88) ignores return value by [IERC20(wETH).approve(UNISWAP_V3_ROUTER,0)](contracts/eth/exchanges/ETHExchanger.sol#L84)

contracts/eth/exchanges/ETHExchanger.sol#L79-L88


 - [ ] ID-295
[DodoV1Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243) ignores return value by [DodoVaultV1(_lpTokenPool).withdrawBase((_baseWithdrawAmount * _baseExpectedTarget) / _totalBaseCapital)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L219-L221)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243


 - [ ] ID-296
[ETHVaultAdmin.addAsset(address)](contracts/eth/vault/ETHVaultAdmin.sol#L157-L165) ignores return value by [IPriceOracleConsumer(priceProvider).priceInUSD(_asset)](contracts/eth/vault/ETHVaultAdmin.sol#L162)

contracts/eth/vault/ETHVaultAdmin.sol#L157-L165


 - [ ] ID-297
[Aura3PoolStrategy.claimRewards()](contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L242-L265) ignores return value by [IRewardPool(_rewardPool).getReward()](contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L248)

contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L242-L265


 - [ ] ID-298
[AuraWstETHWETHStrategy.swapRewardsToWants()](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L303-L358) ignores return value by [SUSHIROUTER2.swapExactTokensForTokens(_balanceOfLdo,0,swapRewardRoutes[LDO],address(this),block.timestamp)](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L338-L344)

contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L303-L358


 - [ ] ID-299
[ConvexIBUsdtStrategy.harvest()](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L315-L359) ignores return value by [IConvexReward(rewardPool).getReward()](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L321)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L315-L359


 - [ ] ID-300
[DodoV1Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243) ignores return value by [DodoVaultV1(_lpTokenPool).withdrawBase((_baseWithdrawAmount * _baseExpectedTarget) / _totalBaseCapital)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L238-L240)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243


 - [ ] ID-301
[Aura3PoolStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L199-L208) ignores return value by [IRewardPool(getRewardPool()).redeem(_withdrawAmount,address(this),address(this))](contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L206)

contracts/usd/strategies/aura/Aura3PoolStrategy.sol#L199-L208


 - [ ] ID-302
[ConvexIBUsdtStrategy._repayForex(uint256)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L512-L519) ignores return value by [_borrowC.repayBorrow(_repayAmount)](contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L518)

contracts/usd/strategies/convex/ib/ConvexIBUsdtStrategy.sol#L512-L519


 - [ ] ID-303
[VaultAdmin.addAsset(address)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L137-L146) ignores return value by [assetSet.add(_asset)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L139)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L137-L146


 - [ ] ID-304
[ConvexBaseStrategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L64-L77) ignores return value by [IConvexReward(rewardPool).withdraw(_lpAmount,false)](contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L72)

contracts/usd/strategies/convex/ConvexBaseStrategy.sol#L64-L77


 - [ ] ID-305
[DodoV1Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243) ignores return value by [DodoVaultV1(_lpTokenPool).withdrawQuote((_quoteWithdrawAmount * _quoteExpectedTarget) / _totalQuoteCapital)](contracts/usd/strategies/dodo/DodoV1Strategy.sol#L232-L234)

contracts/usd/strategies/dodo/DodoV1Strategy.sol#L203-L243


 - [ ] ID-306
[ConvexIBUsdcStrategy._mintCollateralCToken(uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L578-L590) ignores return value by [CTokenInterface(_collateralC).mint(_mintAmount)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L585)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L578-L590


 - [ ] ID-307
[ConvexrETHwstETHStrategy.depositTo3rdPool(address[],uint256[])](contracts/eth/strategies/convex/ConvexrETHwstETHStrategy.sol#L139-L168) ignores return value by [BOOSTER.deposit(getPid(),_liquidity,true)](contracts/eth/strategies/convex/ConvexrETHwstETHStrategy.sol#L166)

contracts/eth/strategies/convex/ConvexrETHwstETHStrategy.sol#L139-L168


 - [ ] ID-308
[ConvexStETHStrategy.depositTo3rdPool(address[],uint256[])](contracts/eth/strategies/convex/ConvexStETHStrategy.sol#L132-L153) ignores return value by [BOOSTER.deposit(getPid(),_liquidity,true)](contracts/eth/strategies/convex/ConvexStETHStrategy.sol#L151)

contracts/eth/strategies/convex/ConvexStETHStrategy.sol#L132-L153


 - [ ] ID-309
[YearnV2Strategy.withdrawFrom3rdPool(uint256,uint256,uint256)](contracts/eth/strategies/yearn/v2/YearnV2Strategy.sol#L92-L101) ignores return value by [yVault.withdraw((_balanceOf * _withdrawShares) / _totalShares)](contracts/eth/strategies/yearn/v2/YearnV2Strategy.sol#L100)

contracts/eth/strategies/yearn/v2/YearnV2Strategy.sol#L92-L101


 - [ ] ID-310
[ConvexIBUsdcStrategy._sellCrvAndCvx(uint256,uint256)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L488-L547) ignores return value by [IUniswapV2Router2(SUSHI_ROUTER_ADDR).swapExactTokensForTokens(balanceOfToken(WETH),0,rewardRoutes[WETH],address(this),block.timestamp)](contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L528-L534)

contracts/usd/strategies/convex/ib-usdc/ConvexIBUsdcStrategy.sol#L488-L547


 - [ ] ID-311
[ConvexUsdtStrategy.curveAddLiquidity(address[],uint256[])](contracts/usd/strategies/convex/ConvexUsdtStrategy.sol#L65-L88) ignores return value by [ICToken(cUSDC).mint(_amounts[1])](contracts/usd/strategies/convex/ConvexUsdtStrategy.sol#L77)

contracts/usd/strategies/convex/ConvexUsdtStrategy.sol#L65-L88


 - [ ] ID-312
[ETHVaultAdmin.removeAsset(address)](contracts/eth/vault/ETHVaultAdmin.sol#L168-L192) ignores return value by [assetSet.remove(_asset)](contracts/eth/vault/ETHVaultAdmin.sol#L178)

contracts/eth/vault/ETHVaultAdmin.sol#L168-L192


 - [ ] ID-313
[AuraWstETHWETHStrategy.swapRewardsToWants()](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L303-L358) ignores return value by [UNIROUTER2.swapExactTokensForTokens(_balanceOfAura,0,swapRewardRoutes[AURA_TOKEN],address(this),block.timestamp)](contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L324-L330)

contracts/eth/strategies/aura/AuraWstETHWETHStrategy.sol#L303-L358


 - [ ] ID-314
[DodoPoolActionsMixin.__deposit(uint256)](contracts/utils/actions/DodoPoolActionsMixin.sol#L26-L29) ignores return value by [DodoVault(lpTokenPool).approve(STAKE_POOL_ADDRESS,_amount)](contracts/utils/actions/DodoPoolActionsMixin.sol#L27)

contracts/utils/actions/DodoPoolActionsMixin.sol#L26-L29


 - [ ] ID-315
[VaultAdmin.removeAsset(address)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L149-L164) ignores return value by [trackedAssetsMap.remove(_asset)](node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L160)

node_modules/boc-contract-core/contracts/vault/VaultAdmin.sol#L149-L164


