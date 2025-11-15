# Fortuna Lottery

A privacy-preserving decentralized lottery platform built on Ethereum, combining the fairness of Chainlink VRF with the privacy of zero-knowledge proofs.

## Table of Contents

- [Introduction](#introduction)
- [How It Works](#how-it-works)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Smart Contracts](#smart-contracts)
- [Zero-Knowledge Proofs](#zero-knowledge-proofs)
- [Frontend Application](#frontend-application)
- [Backend Services](#backend-services)
- [Testing](#testing)
- [Deployment](#deployment)
- [Documentation](#documentation)
- [License](#license)

---

## Introduction

Fortuna Lottery reimagines the traditional lottery by solving two fundamental problems: fairness and privacy.

Traditional lotteries suffer from trust issues. Participants must believe the operator isn't manipulating results. Even blockchain-based lotteries, while transparent, expose every participant's betting strategy to the world. If you place a large bet, everyone sees it. Your competitors can adjust their strategy. Your financial behavior becomes public record.

Fortuna solves both problems. Chainlink VRF provides cryptographically verifiable randomness that no one can manipulate. Zero-knowledge proofs hide your bets while still proving their validity. You can participate, win, and claim prizes without anyone knowing which bets were yours.

The system implements a weighted lottery mechanism, sometimes called a Chinese Auction. Unlike winner-takes-all lotteries, your winning probability is proportional to your participation. Place 20% of the tokens on an item, and you have a 20% chance of winning it. This creates a fair, skill-based dynamic where strategy matters but luck still plays a role.

---

## How It Works

The lottery operates in four phases, each designed to balance transparency with privacy.

### Phase 1: Registration

When a lottery opens, participants connect their wallets and register. Upon registration, each participant receives an allocation of tokens. These tokens are the currency of the lottery, distributed equally to ensure fair starting conditions.

Registration is the only public action. Your wallet address is recorded on-chain, confirming you're a participant. Everything after this point is private.

### Phase 2: Private Betting

This is where zero-knowledge proofs work their magic. When you decide to place tokens on an item, your browser generates a cryptographic commitment. Think of it as placing your bet inside a locked box that only you can open.

The commitment is a hash of your bet details combined with random secrets:

```
commitment = Hash(secret, nullifier, itemId, tokenAmount, salt)
```

Only the commitment goes on-chain. The actual bet details stay in your browser. The smart contract knows a bet was placed and updates the total token count for that item, but it cannot determine who placed it or how many tokens they used.

Your secrets are stored locally in your browser. Guard them carefully, as they're your proof of ownership if you win.

### Phase 3: Random Selection

When the lottery ends, the owner triggers winner selection for each item. This is where Chainlink VRF ensures fairness.

The contract requests a random number from Chainlink's decentralized oracle network. This number is generated off-chain by multiple independent nodes, then verified on-chain. No single party can predict or manipulate it.

The winning position is calculated as:

```
winningPosition = randomNumber % totalTokensOnItem
```

If an item received 100 tokens total, the winning position will be between 0 and 99. Whoever's bet range includes this position wins.

### Phase 4: Anonymous Claiming

Winners claim their prizes using zero-knowledge proofs. Your browser generates a proof demonstrating:

1. You know the secret values behind a commitment in the Merkle tree
2. Your bet's ticket range includes the winning position
3. You haven't claimed this prize before (nullifier check)

The contract verifies this proof without learning which commitment is yours. You can even specify a different wallet address to receive the prize, adding another layer of privacy.

---

## Technology Stack

The project spans blockchain, cryptography, and web development.

| Layer | Technologies |
|-------|--------------|
| Smart Contracts | Solidity 0.8.25, Foundry, OpenZeppelin |
| Randomness | Chainlink VRF v2.5 |
| Zero-Knowledge | Circom 2.1.6, Groth16, Poseidon Hash |
| Frontend | Next.js 14, React 18, TypeScript |
| Web3 Integration | wagmi v2, viem, RainbowKit |
| Backend | NestJS 10, Node.js 22 |
| Database | PostgreSQL, Prisma ORM |
| Styling | TailwindCSS |
| Network | Base Sepolia (L2 Testnet) |

---

## Project Structure

```
fortuna-lottery/
├── circuits/                    # Zero-knowledge circuits
│   ├── commitment/             # Bet commitment proofs
│   ├── winner/                 # Winner claim proofs
│   ├── merkle/                 # Merkle tree verification
│   └── poseidon/               # Hash function
├── contracts/                   # Solidity smart contracts
│   ├── FortunaLottery.sol      # Public lottery (original)
│   ├── FortunaLotteryZK.sol    # Private lottery (ZK-enabled)
│   ├── lib/                    # Shared libraries
│   ├── verifiers/              # Proof verification
│   └── mocks/                  # Testing mocks
├── frontend/                    # Next.js application
│   ├── app/                    # Pages and routing
│   ├── components/             # React components
│   └── lib/                    # Utilities and hooks
│       ├── contracts/          # Contract integration
│       └── zk/                 # ZK proof generation
├── backend/                     # NestJS API server
│   ├── src/
│   │   ├── lottery/            # Lottery endpoints
│   │   ├── indexer/            # Event indexing
│   │   └── prisma/             # Database access
│   └── prisma/                 # Schema definitions
├── test/                        # Contract tests
├── script/                      # Deployment scripts
└── docs/                        # Documentation
```

---

## Getting Started

### Prerequisites

Ensure you have the following installed:

- [Node.js](https://nodejs.org/) v22 or higher
- [Foundry](https://book.getfoundry.sh/) for smart contract development
- [PostgreSQL](https://www.postgresql.org/) for the backend database

### Local Development

The fastest way to explore the project is running everything locally. This requires no external services or blockchain interaction.

**Step 1: Clone and install dependencies**

```bash
git clone https://github.com/atahabilder1/fortuna-lottery.git
cd fortuna-lottery

forge install
cd frontend && npm install && cd ..
cd backend && npm install && cd ..
```

**Step 2: Start a local blockchain**

Open a terminal and run:

```bash
anvil
```

This starts a local Ethereum node with pre-funded test accounts.

**Step 3: Deploy contracts**

In another terminal:

```bash
forge script script/DeployLocalZK.s.sol --rpc-url http://localhost:8545 --broadcast
```

Note the deployed contract address from the output.

**Step 4: Start the frontend**

```bash
cd frontend
echo "NEXT_PUBLIC_CONTRACT_ADDRESS=<address-from-step-3>" > .env
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

**Step 5: Connect a wallet**

Configure MetaMask with the local network:
- Network Name: Anvil Local
- RPC URL: http://localhost:8545
- Chain ID: 31337

Import a test account using this private key:
```
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

This account has 10,000 test ETH.

---

## Smart Contracts

The project includes two lottery implementations: a transparent version for understanding the mechanics, and a privacy-preserving version using zero-knowledge proofs.

### FortunaLottery.sol

The original implementation with full transparency. Useful for learning and testing basic functionality.

Key functions:
- `createLottery()` - Initialize a new lottery with items
- `registerParticipant()` - Join and receive tokens
- `placeTokens()` - Bet tokens on items
- `requestWinner()` - Trigger VRF for random selection

### FortunaLotteryZK.sol

The privacy-enhanced version using ZK proofs.

Key functions:
- `register()` - Join the lottery (public)
- `placeBetZK()` - Submit encrypted bet with proof
- `claimPrize()` - Claim winnings anonymously

### Supporting Contracts

- `IncrementalMerkleTree.sol` - Efficient on-chain Merkle tree
- `PoseidonT3.sol` - SNARK-friendly hash function
- Mock contracts for local testing without external dependencies

For detailed contract documentation, see [docs/architecture.md](docs/architecture.md).

---

## Zero-Knowledge Proofs

The ZK system enables private betting and anonymous prize claims.

### Circuits

Written in Circom, the circuits define what can be proven:

**Bet Commitment Circuit** (`circuits/commitment/bet_commitment.circom`)

Proves that a commitment was correctly formed from valid bet data without revealing the data itself.

**Winner Proof Circuit** (`circuits/winner/winner_proof.circom`)

Proves ownership of the winning ticket by demonstrating:
- Knowledge of a commitment's preimage
- Merkle tree membership
- Winning position falls within the bet's range
- Nullifier uniqueness

### Cryptographic Primitives

**Poseidon Hash**: A hash function designed for efficiency inside ZK circuits. Standard hashes like SHA-256 require thousands of constraints; Poseidon needs only hundreds.

**Merkle Trees**: All commitments are stored in an on-chain Merkle tree. This allows proving membership with logarithmic proof size regardless of the number of participants.

**Nullifiers**: Unique values derived from secrets that prevent double-claiming without revealing identity.

For circuit compilation and setup instructions, see [circuits/README.md](circuits/README.md).

---

## Frontend Application

The frontend is built with Next.js 14 using the App Router pattern.

### Key Features

- Wallet connection supporting MetaMask, WalletConnect, and Coinbase Wallet
- Real-time lottery data from on-chain reads
- Client-side ZK proof generation
- Local secret management for bet privacy

### Architecture

The application follows a modular structure:

- `app/` - Page components and routing
- `components/` - Reusable UI elements
- `lib/contracts/` - Contract ABIs and React hooks
- `lib/zk/` - Zero-knowledge proof utilities

### ZK Integration

The `lib/zk/` module handles all cryptographic operations:

- `secrets.ts` - Generate and store betting secrets securely
- `hash.ts` - Poseidon hash implementation for commitments
- `prover.ts` - Generate proofs for betting and claiming

---

## Backend Services

The NestJS backend provides event indexing and API services.

### Event Indexer

The indexer watches blockchain events and maintains a synchronized database:

- Listens to lottery creation, registration, and betting events
- Tracks Merkle tree state for proof generation
- Stores commitment-to-position mappings

### API Endpoints

RESTful endpoints for querying lottery data:

```
GET /lottery              - List all lotteries
GET /lottery/:id          - Lottery details
GET /lottery/:id/items    - Items in a lottery
GET /lottery/:id/participants - Registered participants
```

Swagger documentation available at `/api` when running locally.

### Database Schema

Prisma manages the PostgreSQL database with models for:

- Lotteries and their configuration
- Items and token totals
- Participants and allocations
- Commitments and Merkle positions (ZK)

---

## Testing

### Smart Contract Tests

Run the Foundry test suite:

```bash
forge test -vv
```

The test suite includes 25 tests covering:
- Lottery creation and configuration
- Participant registration
- Token placement (public and ZK)
- Winner selection mechanics
- Prize claiming with proofs
- Edge cases and access control

For gas profiling:

```bash
forge test --gas-report
```

### Local Integration Testing

The `scripts/local-test.sh` script automates full integration testing:

```bash
./scripts/local-test.sh
```

This compiles contracts, runs tests, starts Anvil, and deploys for manual testing.

---

## Deployment

### Testnet Deployment

For Base Sepolia testnet deployment:

1. Get test ETH from [faucet.circle.com](https://faucet.circle.com/)
2. Create a Chainlink VRF subscription at [vrf.chain.link](https://vrf.chain.link/)
3. Fund the subscription with test LINK from [faucets.chain.link](https://faucets.chain.link/)

Configure environment variables:

```bash
export BASE_SEPOLIA_RPC=https://sepolia.base.org
export PRIVATE_KEY=your_private_key
```

Deploy:

```bash
forge script script/DeployLottery.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast
```

Add the deployed contract as a VRF consumer in the Chainlink dashboard.

For complete deployment instructions, see [docs/SETUP.md](docs/SETUP.md).

---

## Documentation

- [Setup Guide](docs/SETUP.md) - Installation and configuration
- [Architecture](docs/architecture.md) - Technical design details
- [Circuit Documentation](circuits/README.md) - ZK circuit specifications

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

Developed by [Anik Tahabilder](https://github.com/atahabilder1)
