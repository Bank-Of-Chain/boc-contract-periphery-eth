// // SPDX-License-Identifier: MIT

// pragma solidity >=0.8.0 <0.9.0;


// import "./AuraBaseStrategy.sol";

// contract AuraAave3PoolStrategy is AuraBaseStrategy {
//     using SafeERC20Upgradeable for IERC20Upgradeable;

//     struct AavePoolInfo {
//         uint256 index;
//         bytes32 poolKey;
//         address lpToken;
//     }

//     mapping(address => AavePoolInfo) aavePoolMap;

//     function initialize(address _vault, address _harvester) public {
//         bytes32 _poolKey = 0x7b50775383d3d6f0215a8f290f2c9e2eebbeceb20000000000000000000000fe;
//         uint256 _pId = 4;
//         address _poolLpToken = 0x7B50775383d3D6f0215A8F290f2C9e2eEBBEceb2;
//         address _rewardPool = 0xCC2F52b57247f2bC58FeC182b9a60dAC5963D010;
//         address[] memory _wants = new address[](3);
//         _wants[0] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //DAI
//         _wants[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC
//         _wants[2] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; //USDT
//         super._initialize(_vault, _harvester, _poolKey, _pId, _poolLpToken, _rewardPool, _wants);

//         isWantRatioIgnorable = true;

//         //DAI poolKey (bb-a-DAI),
//         aavePoolMap[0x6B175474E89094C44Da98b954EedeAC495271d0F] = AavePoolInfo({
//             index: 3,
//             poolKey: 0x804cdb9116a10bb78768d3252355a1b18067bf8f0000000000000000000000fb,
//             lpToken: 0x804CdB9116a10bB78768D3252355a1b18067bF8f
//         });
//         //USDC poolKey (bb-a-USDC)
//         aavePoolMap[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = AavePoolInfo({
//             index: 2,
//             poolKey: 0x9210f1204b5a24742eba12f710636d76240df3d00000000000000000000000fc,
//             lpToken: 0x9210F1204b5a24742Eba12f710636D76240dF3d0
//         });
//         //USDT poolKey (bb-a-USDT)
//         aavePoolMap[0xdAC17F958D2ee523a2206206994597C13D831ec7] = AavePoolInfo({
//             index: 0,
//             poolKey: 0x2bbf681cc4eb09218bee85ea2a5d3d13fa40fc0c0000000000000000000000fd,
//             lpToken: 0x2BBf681cC4eb09218BEe85EA2a5d3D13Fa40fC0C
//         });

//         // uint256 uintMax = type(uint256).max;
//         // for (uint256 i = 0; i < _wants.length; i++) {
//         //     address token = _wants[i];
//         //     // for enter balancer vault
//         //     IERC20Upgradeable(token).safeApprove(address(BALANCER_VAULT), uintMax);
//         // }
//     }

//     function getVersion() external pure override returns (string memory) {
//         return "1.0.0";
//     }

//     function name() external pure override returns (string memory) {
//         return "AuraAave3PoolStrategy";
//     }

//     function getWantsInfo()
//         external
//         view
//         override
//         returns (address[] memory _assets, uint256[] memory _ratios)
//     {
//         // (_assets, _ratios, ) = BALANCER_VAULT.getPoolTokens(poolKey);
//         _assets = new address[](3);
//         _assets[0] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
//         _assets[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
//         _assets[2] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
//         _ratios = new uint256[](3);
//         _ratios[0] = 1 ether;
//         _ratios[1] = 1 ether;
//         _ratios[2] = 1 ether;
//     }

//     /// @notice 3rd prototcol's pool total assets in USD.
//     function get3rdPoolAssets() external view override returns (uint256 poolAssets) {
//         // uint256 totalAssets;
//         // (address[] memory tokens, uint256[] memory balances, ) = BALANCER_VAULT.getPoolTokens(
//         //     poolKey
//         // );
//         // for (uint8 i = 0; i < tokens.length; i++) {
//         //     totalAssets += queryTokenValue(tokens[i], balances[i]);
//         // }
//         // return totalAssets;
//     }

//     function _depositToBalancer(address[] memory _assets, uint256[] memory _amounts)
//         internal
//         override
//         returns (uint256 receiveLpAmount)
//     {
//         IAsset[] memory assets = _getPoolAssets(poolKey);
//         uint256[] memory amounts = new uint256[](assets.length);
//         for(uint256 i = 0;i < wants.length;i++){
//             address underlyingToken = wants[i];
//             (uint256 index,uint256 amount) = _underlyingTokenToAaveLpToken(underlyingToken);
//             amounts[index] = amount;
//         }
//         IBalancerVault.JoinPoolRequest memory joinRequest = IBalancerVault.JoinPoolRequest({
//             assets: assets,
//             maxAmountsIn: amounts,
//             userData: abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amounts, 0),
//             fromInternalBalance: false
//         });

//         BALANCER_VAULT.joinPool(poolKey, address(this), address(this), joinRequest);
//         receiveLpAmount = balanceOfToken(poolLpToken);
//     }

//     function _withdrawFromBalancer(uint256 _exitAmount) internal override {
//         address payable recipient = payable(address(this));
//         IAsset[] memory poolAssets = _getPoolAssets(poolKey);
//         uint256[] memory minAmountsOut = new uint256[](poolAssets.length);
//         IBalancerVault.ExitPoolRequest memory exitRequest = IBalancerVault.ExitPoolRequest({
//             assets: poolAssets,
//             minAmountsOut: minAmountsOut,
//             userData: abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, _exitAmount),
//             toInternalBalance: false
//         });
//         BALANCER_VAULT.exitPool(poolKey, address(this), recipient, exitRequest);
//     }

//     function _underlyingTokenToAaveLpToken(address _underlyingToken)
//         internal
//         returns (uint256 index,uint256 lpAmount)
//     {
//         AavePoolInfo memory aavePoolInfos = aavePoolMap[_underlyingToken];
//         require(aavePoolInfos.poolKey[0] != 0, "unsupport token!");

//         IAsset[] memory poolAssets = _getPoolAssets(aavePoolInfos.poolKey);
//         uint256[] memory amounts = new uint256[](poolAssets.length);
//         for (uint256 i = 0; i < amounts.length; i++) {
//             amounts[i] = balanceOfToken(address(poolAssets[i]));
//             console.log('wrap asset:%s,amount:%d',address(poolAssets[i]),amounts[i]);
//             // if (amounts[i] > 0){
//             //     address asset = address(poolAssets[i]);
//             //     IERC20Upgradeable(asset).safeApprove(address(BALANCER_VAULT), 0);
//             //     IERC20Upgradeable(asset).safeApprove(address(BALANCER_VAULT), amounts[i]);
//             // }
//         }

//         IBalancerVault.JoinPoolRequest memory joinRequest = IBalancerVault.JoinPoolRequest({
//             assets: poolAssets,
//             maxAmountsIn: amounts,
//             userData: abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amounts, 0),
//             fromInternalBalance: false
//         });
//         BALANCER_VAULT.joinPool(aavePoolInfos.poolKey, address(this), address(this), joinRequest);

//         index = aavePoolInfos.index;
//         lpAmount = balanceOfToken(aavePoolInfos.lpToken);
//         console.log('aave pool lpAmount:',lpAmount);
//     }
// }
