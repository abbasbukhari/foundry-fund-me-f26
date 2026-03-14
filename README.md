# FundMe — Foundry

A crowdfunding smart contract built on Ethereum, written in Solidity and tested with Foundry.

This repo is my personal learning implementation of the FundMe contract from the **Cyfrin Foundry Blockchain Developer Course** by [Patrick Collins](https://twitter.com/PatrickAlphaC). The original course repo is [Cyfrin/foundry-fund-me-cu](https://github.com/Cyfrin/foundry-fund-me-cu/tree/main).

---

## What this contract does

- Anyone can fund the contract by sending ETH, as long as it's worth at least **$5 USD**
- The USD value is checked in real-time using a **Chainlink price feed** (no hardcoded rates)
- Only the **owner** (the address that deployed the contract) can withdraw all funds
- All funders and their contribution amounts are tracked on-chain

---

## How it works

```
User sends ETH
      │
      ▼
fund() checks ETH value in USD via Chainlink
      │
   ≥ $5?
   /     \
 yes      no → revert "You need to spend more ETH!"
  │
  ▼
Record funder + amount
      │
      ▼
Owner calls withdraw()
      │
      ▼
Reset all funder balances → clear funders array → send full balance to owner
```

---

## Contracts

### `src/FundMe.sol`
The main contract. Key concepts covered:
- Chainlink price feeds via `AggregatorV3Interface`
- `using Library for type` syntax
- `mapping` and dynamic arrays for state tracking
- `modifier` for access control (`onlyOwner`)
- Custom errors for gas-efficient reverts
- `.call` for ETH transfers (preferred over `.transfer` / `.send`)
- `receive()` and `fallback()` to handle direct ETH sends

### `src/PriceConverter.sol`
A stateless Solidity library written by Patrick Collins. Provides:
- `getPrice()` — fetches live ETH/USD price from Chainlink (Sepolia testnet)
- `getConversionRate(uint256 ethAmount)` — converts a wei amount to its USD value

---

## About this repo

The code follows Patrick's course, but I took time to **deeply annotate every concept** that wasn't immediately obvious to me as a beginner. The inline comments in both `.sol` files break down:

- Why `.call` is used instead of `.transfer`
- How tuple destructuring works with bare commas
- How Chainlink's `latestRoundData()` return values map to real data
- Why `immutable` is used over `constant` for `i_owner`
- How `using PriceConverter for uint256` changes the calling syntax

If you're also a beginner following this course and the code feels overwhelming — check `NOTES.md` in this repo. It's a plain-English summary of every concept that tripped me up.

---

## Getting Started

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/)

### Install

```shell
git clone <your-repo-url>
cd foundry-fund-me-f26
forge install
```

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Deploy (Sepolia)

```shell
forge script script/DeployFundMe.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

> The Chainlink price feed address in this contract is hardcoded for the **Sepolia testnet**.
> If deploying to a different network, update the address in `PriceConverter.sol`.
> See all addresses at: https://docs.chain.link/data-feeds/price-feeds/addresses

---

## Tools

| Tool | Purpose |
|---|---|
| [Foundry / Forge](https://book.getfoundry.sh/) | Build, test, deploy |
| [Chainlink](https://chain.link/) | On-chain ETH/USD price feed |
| [Sepolia Faucet](https://sepoliafaucet.com/) | Test ETH for deployment |

---

## Credits

Original contract and course by **Patrick Collins** — [Cyfrin](https://github.com/Cyfrin).

- Course repo: [Cyfrin/foundry-fund-me-cu](https://github.com/Cyfrin/foundry-fund-me-cu/tree/main)
- Full course: [Cyfrin Updraft](https://updraft.cyfrin.io/)
- Patrick on Twitter: [@PatrickAlphaC](https://twitter.com/PatrickAlphaC)

---

## License

MIT