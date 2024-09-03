// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "src/interfaces/IERC20.sol";

/// @title SafeTransferLib
/// @notice Library for safe ETH and ERC20 transfers.
library SafeTransferLib {
    error ETHTransferFailed();
    error ERC20OperationFailed();

    /**
     * @dev Send `amount` of ETH and returns whether the transfer succeeded.
     */
    function tryTransferETH(address to, uint256 amount) internal returns (bool success) {
        assembly {
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }
    }

    /**
     * @dev Send `amount` of ETH and revert if the transfer failed.
     */
    function safeTransferETH(address to, uint256 amount) internal {
        bool success = tryTransferETH(to, amount);
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /**
     * @dev Forcefully send `amount` of ETH to the recipient with SELFDESTRUCT.
            This will not trigger the recipient's receive or fallback function.
     */
    function forceTransferETH(address to, uint256 amount) internal {
        bool success;
        assembly {
            mstore(0x00, to) // Store the address in scratch space
            mstore8(0x0b, 0x73) // Opcode `PUSH20`
            mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`
            success := create(amount, 0x0b, 0x16)
        }

        // CREATE only fails if this contract has insufficient ETH to send
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /**
     * @dev Send `amount` of `token`. Revert if the transfer failed.
     */
    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        _callOptionalReturnWithRevert(token, abi.encodeCall(token.transfer, (to, amount)));
    }

    /**
     * @dev Transfer `amount` of `token` from `from` to `to`. Revert if the transfer failed.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        _callOptionalReturnWithRevert(token, abi.encodeCall(token.transferFrom, (from, to, amount)));
    }
    
    /**
     * @dev Set an allowance for `token` of `amount`. Revert if the approval failed.
     *      This does not work when called with `amount = 0` for tokens that revert on zero approval (eg. BNB).
     */
    function safeApprove(IERC20 token, address to, uint256 amount) internal {
        bytes memory approveData = abi.encodeCall(token.approve, (to, amount));
        bool success = _callOptionalReturn(token, approveData);

        // If the original approval fails, call approve(to, 0) before retrying
        // For tokens that revert on non-zero to non-zero approval (eg. USDT)
        if (!success) {
            _callOptionalReturnWithRevert(token, abi.encodeCall(token.approve, (to, 0)));
            _callOptionalReturnWithRevert(token, approveData);
        }
    }

    function _callOptionalReturnWithRevert(IERC20 token, bytes memory data) internal {
        bool success = _callOptionalReturn(token, data);
        if (!success) {
            revert ERC20OperationFailed();
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) internal returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        
        return success && (
            returndata.length == 0
            ? address(token).code.length != 0  // If returndata is empty, token must have code
            : abi.decode(returndata, (bool))   // If returndata is not empty, it must be true
        );
    }
}
