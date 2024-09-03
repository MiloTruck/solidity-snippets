# Solidity Snippets

A collection of commonly seen contracts, re-written to prioritize simplicity and readability.

## Contracts

All contracts are located in the `src` directory.

```ml
interfaces
├─ IERC20 — "Interface of the ERC-20 standard"

snippets
├─ ConstantSumPair - "A minimal x + y = k AMM"

tokens
├─ ERC20 — "Minimal ERC20 implementation"

utils
├─ FixedPointMathLib — "Library to manage fixed-point arithmetic"
├─ SafeTransferLib — "Library for safe ETH and ERC20 transfers"
├─ VoteHistoryLib — "Library to store and retrieve vote history based on block number"
```

## Installation

To install with [**Foundry**](https://github.com/gakonst/foundry):

```sh
forge install MiloTruck/solidity-snippets
```

## Safety

This codebase was written for demonstration purposes. It has not been audited and should not be used in production.

## Acknowledgements

This repository is inspired by or directly modified from many sources, primarily:

- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Solmate](https://github.com/transmissions11/solmate)
- [Solady](https://github.com/Vectorized/solady)