// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ICallbacks {
    function onTokensReceived(address sender, uint256 amountXOut, uint256 amountYOut, bytes calldata data) external;
}
