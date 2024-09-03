// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "src/interfaces/IERC20.sol";
import {ERC20} from "src/tokens/ERC20.sol";
import {SafeTransferLib} from "src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "src/utils/FixedPointMathLib.sol";
import {ICallbacks} from "./interfaces/ICallbacks.sol";

/// @title ConstantSumPair
/// @notice A minimal x + y = k AMM.
contract ConstantSumPair is ERC20 {
    using SafeTransferLib for IERC20;
    using FixedPointMathLib for uint256;

    address public immutable owner;

    IERC20 public immutable tokenX;
    IERC20 public immutable tokenY;

    uint256 public k;

    uint256 public price;

    // ======================================== CONSTRUCTOR ========================================

    constructor() {
        owner = msg.sender;
    }

    // ======================================== MODIFIERS ========================================

    /**
     * @notice Enforces the x + y = k invariant
     */
    modifier invariant() {
        _;

        require(_computeK() >= k, "K");
    }

    // ======================================== PERMISSIONED FUNCTIONS ========================================

    /**
     * @notice Set the price for the AMM.
     *
     * @param _price  The price of tokenY in tokenX. Has 18 decimals.
     */
    function setPrice(uint256 _price) external {
        require(msg.sender == owner, "OWNER");

        price = _price;
        k = _computeK();
    }

    // ======================================== MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Add liquidity to the pair and mint LP tokens.
     *
     * @param deltaK  The amount of liquidity added.
     */
    function addK(uint256 deltaK) external invariant returns (uint256 shares) {
        shares = k == 0 ? deltaK : deltaK.mulDivDown(totalSupply, k);

        k += deltaK;
        _mint(msg.sender, shares);
    }

    /**
     * @notice Remove liquidity form the pair and burn LP tokens.
     *
     * @param amountXOut  The amount of tokenX to withdraw.
     * @param amountYOut  The amount of tokenY to withdraw.
     * @param deltaK      The amount of liquidity removed.
     */
    function removeK(uint256 amountXOut, uint256 amountYOut, uint256 deltaK)
        external
        invariant
        returns (uint256 shares)
    {
        shares = deltaK.mulDivUp(totalSupply, k);

        k -= deltaK;
        _burn(msg.sender, shares);

        tokenX.safeTransfer(msg.sender, amountXOut);
        tokenY.safeTransfer(msg.sender, amountYOut);
    }

    /**
     * @notice Transfer tokens out from the pair.
     *
     * @param amountXOut  The amount of tokenX to transfer out.
     * @param amountYOut  The amount of tokenY to transfer out.
     * @param data        Data passed to caller in the onTokensReceived callback.
     */
    function transferTokens(uint256 amountXOut, uint256 amountYOut, bytes calldata data) external invariant {
        if (amountXOut != 0) tokenX.safeTransfer(msg.sender, amountXOut);
        if (amountYOut != 0) tokenY.safeTransfer(msg.sender, amountYOut);

        if (data.length != 0) {
            ICallbacks(msg.sender).onTokensReceived(msg.sender, amountXOut, amountYOut, data);
        }
    }

    // ======================================== VIEW FUNCTIONS ========================================

    function name() public pure override returns (string memory) {
        return "ConstantSumPairLiquidity";
    }

    function symbol() public pure override returns (string memory) {
        return "CSPL";
    }

    // ======================================== VIEW FUNCTIONS ========================================

    function _computeK() internal view returns (uint256) {
        uint256 reserveX = tokenX.balanceOf(address(this));
        uint256 reserveY = tokenY.balanceOf(address(this));

        return reserveX + reserveY.divWadDown(price);
    }
}
