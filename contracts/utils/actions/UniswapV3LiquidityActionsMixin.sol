// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '../AssetHelpers.sol';
import './../../external/uniswapV3/INonfungiblePositionManager.sol';
import './../../external/uniswapV3/libraries/PositionValue.sol';
import 'hardhat/console.sol';

/// @title UniswapV3LiquidityActionsMixin Contract
/// @notice Mixin contract for interacting with Uniswap v3
abstract contract UniswapV3LiquidityActionsMixin is AssetHelpers {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event UniV3Initialized(address token0, address token1, uint24 fee);
    event UniV3NFTPositionAdded(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event UniV3NFTPositionRemoved(uint256 indexed tokenId);
    event UniV3NFTCollect(uint256 nftId, uint256 amount0, uint256 amount1);

    INonfungiblePositionManager constant internal nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IUniswapV3Pool public pool;

    address internal token0;
    address internal token1;
    uint24 internal fee;

    function _initializeUniswapV3Liquidity(address _pool) internal {
        pool = IUniswapV3Pool(_pool);
        token0 = pool.token0();
        token1 = pool.token1();
        fee = pool.fee();

        // Approve the NFT manager once for the max of each token
        IERC20Upgradeable(token0).safeApprove(address(nonfungiblePositionManager), type(uint256).max);
        IERC20Upgradeable(token1).safeApprove(address(nonfungiblePositionManager), type(uint256).max);
        emit UniV3Initialized(token0, token1, fee);
    }

    // PRIVATE FUNCTIONS

    /// @dev Adds liquidity to the uniswap position
    function __addLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams memory _params)
    internal returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    )
    {
        return nonfungiblePositionManager.increaseLiquidity(_params);
    }

    function __collectAll(uint256 _nftId) internal returns (uint256, uint256){
        return __collect(_nftId, type(uint128).max, type(uint128).max);
    }

    /// @dev Collects all uncollected amounts from the nft position and sends it to the vaultProxy
    function __collect(uint256 _nftId, uint128 _amount0, uint128 _amount1) internal returns (uint256 amount0, uint256 amount1){
        (amount0, amount1) =  nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId : _nftId,
            recipient : address(this),
            amount0Max : _amount0,
            amount1Max : _amount1
            })
        );
        emit UniV3NFTCollect(_nftId, amount0, amount1);
    }

    /// @dev Helper to get the total liquidity of an nft position.
    /// Uses a low-level staticcall() and truncated decoding of `.positions()`
    /// in order to avoid compilation error.
    function __getLiquidityForNFT(uint256 _nftId) internal view returns (uint128 liquidity_) {
        (bool success, bytes memory returnData) = getNonFungibleTokenManager().staticcall(
            abi.encodeWithSelector(INonfungiblePositionManager.positions.selector, _nftId)
        );
        require(success, string(returnData));

        (,,,,,,, liquidity_) = abi.decode(
            returnData,
            (uint96, address, address, address, uint24, int24, int24, uint128)
        );

        return liquidity_;
    }

    /// @dev Mints a new uniswap position, receiving an nft as a receipt
    function __mint(INonfungiblePositionManager.MintParams memory _params) internal returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ){
        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(_params);
        emit UniV3NFTPositionAdded(tokenId, liquidity, amount0, amount1);
    }

    /// @dev Removes liquidity from the uniswap position and transfers the tokens back to the vault
    function __removeLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams memory _params)
    internal
    returns (uint256, uint256)
    {
        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.decreaseLiquidity(_params);
        console.log('__removeLiquidity,amount0:%d,amount1:%d',amount0,amount1);
        if (amount0 > 0 || amount1 > 0) {
            (amount0,amount1) = __collect(_params.tokenId, uint128(amount0), uint128(amount1));
            console.log('__collect,amount0:%d,amount1:%d',amount0,amount1);
        }
        return (amount0,amount1);
    }

    function __getPositionTotal(uint256 _nftId, uint160 _sqrtPriceX96) internal view returns (uint256, uint256){
        return PositionValue.total(
            nonfungiblePositionManager,
            _nftId,
            _sqrtPriceX96
        );
    }

    function __getSqrtPriceX96(uint256 _nftId) internal view returns (uint160 sqrtPriceX96){
        (sqrtPriceX96,,,,,,) = pool.slot0();
    }

    /// @notice Gets the `NON_FUNGIBLE_TOKEN_MANAGER` variable
    /// @return nonFungibleTokenManager_ The `NON_FUNGIBLE_TOKEN_MANAGER` variable value
    function getNonFungibleTokenManager() public view returns (address nonFungibleTokenManager_) {
        return address(nonfungiblePositionManager);
    }
}
