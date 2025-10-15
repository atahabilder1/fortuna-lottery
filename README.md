# 🎟️ Fortuna Lottery

> A full-stack decentralized lottery application implementing the Chinese Lottery (weighted random selection) on Base Sepolia, featuring Chainlink VRF for provably fair randomness.

[![Solidity](https://img.shields.io/badge/Solidity-0.8.25-blue)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Latest-red)](https://book.getfoundry.sh/)
[![Next.js](https://img.shields.io/badge/Next.js-14-black)](https://nextjs.org/)
[![NestJS](https://img.shields.io/badge/NestJS-10-E0234E)](https://nestjs.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📖 Overview

Fortuna Lottery is a decentralized application that modernizes the traditional **Chinese Lottery** (also known as Chinese Auction or Penny Social). Unlike standard auctions where the highest bidder wins, this system uses **weighted random selection** — participants' winning chances are proportional to the tokens they place on items.

**Example:** If an item has 50 tokens total and you place 10 tokens, you have a 20% chance to win.

### 🎯 Why This Project?

This portfolio project demonstrates:
- **Smart contract development** with Solidity 0.8.25
- **Blockchain integration** using Chainlink VRF v2.5 for verifiable randomness
- **Modern frontend** with Next.js 14, wagmi v2, and RainbowKit
- **Backend architecture** with NestJS, Prisma, and PostgreSQL
- **Full-stack Web3 development** from smart contracts to UI/UX
- **Production-ready code** with comprehensive tests and documentation

## ✨ Features

### Smart Contract
- ✅ Chinese Lottery mechanics with weighted random selection
- ✅ Chainlink VRF v2.5 for provably fair randomness
- ✅ Gas-optimized batch token placement
- ✅ Comprehensive error handling and security patterns
- ✅ Full test coverage (12 tests passing)

### Frontend
- ✅ Wallet connection with RainbowKit (MetaMask, WalletConnect, Coinbase)
- ✅ Real-time lottery data from blockchain
- ✅ Participant registration and token placement
- ✅ Live win probability calculations
- ✅ Responsive design with TailwindCSS

### Backend
- ✅ Blockchain event indexing with viem
- ✅ PostgreSQL database with Prisma ORM
- ✅ Real-time event watching and syncing
- ✅ RESTful API with Swagger documentation
- ✅ Automatic database updates on chain events

## 🛠️ Tech Stack

<table>
  <tr>
    <td><b>Smart Contracts</b></td>
    <td>Solidity 0.8.25 • Foundry • Chainlink VRF v2.5 • OpenZeppelin v5</td>
  </tr>
  <tr>
    <td><b>Frontend</b></td>
    <td>Next.js 14 • React 18 • TypeScript • wagmi v2 • RainbowKit • viem • TailwindCSS</td>
  </tr>
  <tr>
    <td><b>Backend</b></td>
    <td>NestJS • Node.js 22 • PostgreSQL • Prisma • viem • TypeScript</td>
  </tr>
  <tr>
    <td><b>Deployment</b></td>
    <td>Base Sepolia • Vercel (Frontend) • Railway/Render (Backend)</td>
  </tr>
</table>

## 🚀 Quick Start

### Prerequisites
- Node.js v22+
- Foundry
- PostgreSQL (for backend)
- Base Sepolia ETH ([faucet](https://faucet.circle.com/))

### Installation

```bash
# Clone repository
git clone https://github.com/atahabilder1/fortuna-lottery.git
cd fortuna-lottery

# Install dependencies
forge install
cd frontend && npm install && cd ..
cd backend && npm install && cd ..
```

### Smart Contract

```bash
# Compile
forge build

# Test
forge test -vv

# Deploy (requires .env configuration)
forge script script/DeployLottery.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast --verify
```

### Frontend

```bash
cd frontend
cp .env.example .env
# Add CONTRACT_ADDRESS and WALLET_CONNECT_PROJECT_ID
npm run dev
# Open http://localhost:3000
```

### Backend

```bash
cd backend
cp .env.example .env
# Configure DATABASE_URL, CONTRACT_ADDRESS, RPC_URL
npm run prisma:generate
npm run prisma:push
npm run start:dev
# API at http://localhost:3001
```

📚 **Detailed setup instructions:** [docs/SETUP.md](docs/SETUP.md)

## 📂 Project Structure

```
fortuna-lottery/
├── contracts/          # Solidity smart contracts
│   └── FortunaLottery.sol
├── script/             # Deployment scripts
├── test/               # Contract tests
├── frontend/           # Next.js application
│   ├── app/            # App Router pages
│   ├── components/     # React components
│   └── lib/contracts/  # Contract ABIs and hooks
├── backend/            # NestJS API server
│   ├── src/
│   │   ├── lottery/    # Lottery module
│   │   ├── prisma/     # Database service
│   │   └── indexer/    # Event indexer
│   └── prisma/         # Database schema
└── docs/               # Documentation
    ├── SETUP.md        # Setup guide
    └── architecture.md # Technical details
```

## 🎨 How It Works

1. **Lottery Creation** - Owner creates a lottery with items and token allocation
2. **Registration** - Participants register to receive tokens
3. **Token Placement** - Users distribute tokens across items (weighted bets)
4. **Winner Selection** - Chainlink VRF generates random number for fair selection
5. **Result** - Winner determined by weighted probability

### Weighted Selection Example

**Item A** has 30 total tokens:
- Alice: 10 tokens → **33.3%** win chance
- Bob: 5 tokens → **16.7%** win chance
- Carol: 15 tokens → **50%** win chance

VRF generates random number, and the winner is selected proportionally.

## 🔐 Security

- ✅ ReentrancyGuard for critical functions
- ✅ Chainlink ownership pattern for access control
- ✅ Input validation on all parameters
- ✅ Custom errors for gas efficiency
- ✅ Immutable VRF configuration
- ✅ Comprehensive test coverage

## 📊 Testing

```bash
# Run all tests
forge test -vv

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

**Test Results:** 12/12 tests passing ✅

## 📖 Documentation

- **[Setup Guide](docs/SETUP.md)** - Detailed installation and deployment instructions
- **[Architecture](docs/architecture.md)** - Technical design and implementation details
- **Smart Contract** - See [contracts/FortunaLottery.sol](contracts/FortunaLottery.sol)
- **Tests** - See [test/FortunaLottery.t.sol](test/FortunaLottery.t.sol)

## 🌐 Deployment

- **Network:** Base Sepolia (Testnet)
- **Contract:** Deploy with `forge script` (see [SETUP.md](docs/SETUP.md))
- **Frontend:** Deploy to Vercel with one click
- **Backend:** Deploy to Railway or Render

## 🛣️ Roadmap

- [ ] Multi-token support (ERC20/ERC721 prizes)
- [ ] Automatic winner selection at lottery end time
- [ ] Mainnet deployment (Base L2)
- [ ] Mobile app with React Native
- [ ] DAO governance for lottery parameters
- [ ] Advanced analytics dashboard

## 👨‍💻 Author

**Anik Tahabilder**
Blockchain Researcher | Smart Contract Security | Full-stack Web3 Developer

- GitHub: [@atahabilder1](https://github.com/atahabilder1)
- Portfolio: [anik.dev](https://anik.dev) *(coming soon)*

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

### ⭐ Star this repo if you find it helpful!

Built with ❤️ using Solidity, Foundry, Next.js, and Chainlink VRF

</div>
