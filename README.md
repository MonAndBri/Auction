# Auction
TP Final Módulo 2 . Curso Ethereum - ETH Kipu
# 🛎️ Auction Smart Contract

## Overview

This Solidity smart contract implements a basic **time-limited auction** system with built-in bidding logic, refund management, and owner commissions. The auction allows participants to place bids that are at least **5% higher than the current highest bid**, with an optional **10-minute extension** if a bid is placed near the end of the auction period.

---

## 📚 Features

- Bidding with automatic highest bid tracking
- 7-day auction window with last-minute bid extension
- Partial refunds for non-winning bids
- Owner commission collection (2% of refunded bids)
- Full refund logic after auction ends
- Access control for owner-only functions

---

## ⚙️ Tech Stack

- **Solidity** `^0.8.0`
- No external dependencies (but easily extensible with OpenZeppelin, Hardhat, Foundry, etc.)

---

## 🧠 Contract Summary

| Function           | Description                                                  |
|--------------------|--------------------------------------------------------------|
| `bid()`            | Allows users to place bids at least 5% higher than previous  |
| `showWiner()`      | Returns the current winning bidder and their bid             |
| `showOffers()`     | Returns all bids placed so far                               |
| `refund()`         | Refunds all non-winning bidders and calculates commission    |
| `partialRefund()`  | Allows a bidder to withdraw previous lower offers            |
| `withdraw()`       | Transfers final funds (commissions + winner bid) to the owner |
| `getMaxOffer()`    | Returns the maximum offer from a given address               |

---

## 🧪 How to Use

1. **Clone the Repo**
   ```bash
   git clone https://github.com/your-org/auction-contract.git
   cd auction-contract
