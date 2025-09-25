# 🎟️ Fortuna Lottery

**Fortuna Lottery** is a decentralized application (dApp) implementing a modernized version of the **Chinese Lottery (a.k.a. Chinese Auction, Penny Social, Basket Raffle)**.  
It is deployed on the **Base Sepolia testnet** and showcases full-stack blockchain development with **cutting-edge 2025 tools**.

---

## 🧩 What is a Chinese Lottery?

Unlike a traditional auction where the highest bidder wins, in a **Chinese Lottery**:

- Each participant is given a fixed number of **tokens** at the start of the event (e.g., 10 tokens).  
- Multiple items are available for bidding.  
- Participants distribute their tokens across the items however they choose:  
  - Example: 5 tokens on Item A, 3 tokens on Item B, 2 tokens on Item C.  
  - They may place **0 tokens** on some items.  
- The **winner is chosen randomly**, but **probability is proportional to the number of tokens placed**:  
  - If an item has 50 tokens total and Alice placed 10, her winning chance is 10/50 = 20%.  

This makes the process a **probabilistic raffle** instead of a highest-bidder auction.  
It is fair, fun, and demonstrates randomness-based smart contract logic.

---

## 🛠️ Tech Stack (2025)

### Smart Contracts
- **Solidity ^0.8.25**  
- **Foundry** for building, testing, fuzzing, and deploying  
- **Chainlink VRF v2.5** for provably fair randomness  
- **OpenZeppelin Contracts v5** for secure standards  
- **Deployed on Base Sepolia (Coinbase OP Stack L2 testnet)**  

### Frontend
- **Next.js 14 (React 18, App Router)**  
- **TailwindCSS + Shadcn UI** (modern UI)  
- **wagmi v2 + RainbowKit + viem** (wallet connection & contract interaction)  
- **Hosted on Vercel (free tier)**  

### Backend (optional but impressive)
- **Node.js v22** runtime  
- **NestJS** framework (modular, enterprise-grade)  
- **PostgreSQL + Prisma** (database & ORM)  
- **Subsquid indexer** (lightweight alternative to The Graph)  
- **Hosted on Render or Railway (free tier)**  

### DevOps / Infra
- **GitHub Actions** (CI/CD for tests & linting)  
- **Alchemy / Infura RPC** for Base Sepolia access  
- **Slither + Echidna + Foundry Fuzzing** for security testing  

---

## 📂 Repository Structure

```bash
fortuna-lottery/
│
├── contracts/               # Solidity smart contracts
│   ├── FortunaLottery.sol   # main lottery contract
│   ├── mocks/               # mock VRF for local testing
│   └── interfaces/          # VRF & utility interfaces
│
├── script/                  # Foundry deployment scripts
│   └── DeployLottery.s.sol
│
├── test/                    # Foundry tests
│   └── FortunaLottery.t.sol
│
├── frontend/                # Next.js 14 app
│   ├── app/                 # App Router pages
│   │   ├── page.tsx         # homepage
│   │   ├── lottery/page.tsx # lottery dashboard
│   │   └── profile/page.tsx # user profile
│   └── components/          # reusable UI
│
├── backend/ (optional)      # NestJS/Express backend
│   ├── src/
│   │   └── lottery/
│   │       ├── lottery.controller.ts
│   │       └── lottery.service.ts
│   └── prisma/schema.prisma # DB schema
│
├── docs/                    # Documentation
│   └── architecture.md      # detailed design & diagrams
│
├── .github/workflows/       # GitHub Actions (CI/CD)
│   └── ci.yml
│
├── .gitignore               # ignores node_modules, builds, envs
├── foundry.toml             # Foundry config
├── package.json             # root configs (optional tooling)
└── README.md                # project overview (this file)
```

---

## ⚙️ Setup & Installation

### Prerequisites
- [Node.js v22+](https://nodejs.org/)  
- [Foundry](https://book.getfoundry.sh/) (`curl -L https://foundry.paradigm.xyz | bash`)  
- [Base Sepolia faucet](https://faucet.circle.com/) for test ETH  
- [Chainlink VRF subscription](https://docs.chain.link/) on Base Sepolia  

### Clone Repository
```bash
git clone https://github.com/atahabilder1/fortuna-lottery.git
cd fortuna-lottery
```

---

### Smart Contract (Foundry)

Compile:
```bash
forge build
```

Test:
```bash
forge test -vv
```

Deploy to Base Sepolia:
```bash
forge script script/DeployLottery.s.sol   --rpc-url $BASE_SEPOLIA_RPC   --broadcast   --verify
```

---

### Frontend (Next.js)

```bash
cd frontend
npm install
npm run dev
```

Then open: `http://localhost:3000`

---

### Backend (Optional)

```bash
cd backend
npm install
npm run start:dev
```

---

## 🔑 Environment Variables

`.env` (not checked into GitHub):

```ini
# Foundry
BASE_SEPOLIA_RPC=https://base-sepolia.g.alchemy.com/v2/your-key
PRIVATE_KEY=0x....

# Frontend
NEXT_PUBLIC_CONTRACT_ADDRESS=0x...

# Backend
DATABASE_URL=postgresql://user:pass@localhost:5432/lottery
```

---

## 📜 .gitignore

```gitignore
# Node
node_modules/
npm-debug.log
yarn.lock
package-lock.json

# Env
.env
.env.*

# Foundry
cache/
out/

# Backend
/dist
/prisma/migrations

# OS
.DS_Store
Thumbs.db
```

---

## 🎯 Features Demonstrated
- Chinese Lottery mechanics (probabilistic auction)  
- Secure randomness (Chainlink VRF)  
- Frontend integration with wallets (RainbowKit + wagmi)  
- Testnet deployment (Base Sepolia)  
- Full-stack indexing (NestJS + PostgreSQL + Subsquid)  
- Cutting-edge tooling (Foundry, Next.js 14, Tailwind, viem)  

---

## 📸 Screenshots
*(Add after deployment: homepage, bidding page, winner reveal page)*

---

## 🧑‍💻 Author
**Anik Tahabilder**  
- Blockchain Researcher | Smart Contract Security | Full-stack Web3 Developer  
- [GitHub](https://github.com/atahabilder1) | [LinkedIn](#)  

---

## 📜 License
[MIT](./LICENSE)
