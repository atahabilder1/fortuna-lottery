# Setup Guide

Complete setup instructions for running Fortuna Lottery locally or deploying to production.

## Prerequisites

- [Node.js v22+](https://nodejs.org/)
- [Foundry](https://book.getfoundry.sh/) - `curl -L https://foundry.paradigm.xyz | bash`
- [PostgreSQL](https://www.postgresql.org/) (for backend, optional for local testing)

**For Testnet Deployment (Free):**
- [Base Sepolia ETH](https://faucet.circle.com/) - Free from faucet
- [Test LINK tokens](https://faucets.chain.link/base-sepolia) - Free from faucet
- [Chainlink VRF Subscription](https://vrf.chain.link/)

---

## Local Testing (Fastest, Free)

Run everything locally with no blockchain costs using Anvil (local Ethereum node).

### Option 1: One-Command Setup

```bash
# Run everything automatically
./scripts/local-test.sh
```

### Option 2: Manual Setup

**Terminal 1 - Start Local Blockchain:**
```bash
anvil
```

**Terminal 2 - Deploy Contracts:**
```bash
# Deploy ZK lottery with mock verifiers
forge script script/DeployLocalZK.s.sol --rpc-url http://localhost:8545 --broadcast
```

**Terminal 3 - Start Frontend:**
```bash
cd frontend
# Update .env with contract address from deployment output
npm run dev
```

### Connect MetaMask to Local Chain

1. Open MetaMask → Settings → Networks → Add Network
2. Enter:
   - Network Name: `Anvil Local`
   - RPC URL: `http://localhost:8545`
   - Chain ID: `31337`
   - Currency: `ETH`
3. Import test account with private key:
   ```
   0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```
   (This account has 10,000 test ETH)

---

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/atahabilder1/fortuna-lottery.git
cd fortuna-lottery
```

### 2. Install Dependencies

```bash
# Install Foundry dependencies
forge install

# Install frontend dependencies
cd frontend && npm install && cd ..

# Install backend dependencies
cd backend && npm install && cd ..
```

## Smart Contract Setup

### Compile Contracts

```bash
forge build
```

### Run Tests

```bash
# Run all tests
forge test -vv

# Run tests with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test testCreateLottery -vvvv
```

### Deploy to Base Sepolia

1. Create a `.env` file in the root directory:

```bash
BASE_SEPOLIA_RPC=https://base-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY
PRIVATE_KEY=0xYOUR_PRIVATE_KEY
ETHERSCAN_API_KEY=YOUR_BASESCAN_API_KEY
```

2. Ensure you have:
   - Base Sepolia ETH in your wallet
   - A Chainlink VRF subscription created at [vrf.chain.link](https://vrf.chain.link/)

3. Deploy the contract:

```bash
forge script script/DeployLottery.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify
```

4. Add the deployed contract as a consumer to your Chainlink VRF subscription:
   - Go to [vrf.chain.link](https://vrf.chain.link/)
   - Select your subscription
   - Click "Add consumer"
   - Enter your deployed contract address

### Deploy ZK Version (Privacy-Enabled)

The ZK version requires mock verifiers for testing (production would need compiled circuits):

```bash
# Deploy with mock verifiers (for testing)
forge script script/DeployLocalZK.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify
```

This deploys:
- `FortunaLotteryZK` - Main ZK lottery contract
- `MockBetVerifier` - Mock bet proof verifier
- `MockWinnerVerifier` - Mock winner proof verifier
- `MockVRFCoordinator` - Mock VRF for testing

---

## Frontend Setup

### Environment Configuration

Create `frontend/.env`:

```bash
NEXT_PUBLIC_CONTRACT_ADDRESS=0xYOUR_DEPLOYED_CONTRACT_ADDRESS
NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=your_walletconnect_project_id
```

Get a WalletConnect Project ID:
- Visit [WalletConnect Cloud](https://cloud.walletconnect.com/)
- Create a new project
- Copy the Project ID

### Run Development Server

```bash
cd frontend
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build for Production

```bash
npm run build
npm start
```

### Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variables in Vercel dashboard
```

## Backend Setup

### Database Configuration

1. Install PostgreSQL (if not already installed)

2. Create a database:

```bash
psql -U postgres
CREATE DATABASE fortuna_lottery;
\q
```

### Environment Configuration

Create `backend/.env`:

```bash
DATABASE_URL="postgresql://postgres:password@localhost:5432/fortuna_lottery?schema=public"
PORT=3001
CONTRACT_ADDRESS=0xYOUR_DEPLOYED_CONTRACT_ADDRESS
RPC_URL=https://sepolia.base.org
START_BLOCK=0
```

**Environment Variables:**
- `DATABASE_URL`: PostgreSQL connection string
- `PORT`: Backend server port
- `CONTRACT_ADDRESS`: Deployed FortunaLottery contract address
- `RPC_URL`: Base Sepolia RPC endpoint (can use public or Alchemy/Infura)
- `START_BLOCK`: Block number to start indexing from (use deployment block number)

### Initialize Database

```bash
cd backend

# Generate Prisma client
npm run prisma:generate

# Push schema to database
npm run prisma:push

# (Optional) Open Prisma Studio to view database
npx prisma studio
```

### Run Development Server

```bash
npm run start:dev
```

The backend will start on `http://localhost:3001` and automatically:
- Connect to PostgreSQL
- Index historical blockchain events from START_BLOCK
- Watch for new events in real-time
- Sync lottery data to database

### API Endpoints

Once running, you can access:

- `GET http://localhost:3001/lottery` - List all lotteries
- `GET http://localhost:3001/lottery/:id` - Get lottery details
- `GET http://localhost:3001/lottery/:id/items` - Get lottery items
- `GET http://localhost:3001/lottery/:id/participants` - Get participants

Swagger documentation available at: `http://localhost:3001/api`

### Deploy Backend

**Option 1: Railway**

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

Add environment variables in Railway dashboard.

**Option 2: Render**

1. Create a new Web Service on [Render](https://render.com)
2. Connect your GitHub repository
3. Set build command: `cd backend && npm install && npm run build`
4. Set start command: `cd backend && npm run start:prod`
5. Add environment variables
6. Add PostgreSQL database in Render and connect

## Troubleshooting

### Smart Contract

**Issue:** `forge: command not found`
- Run `foundryup` to install/update Foundry

**Issue:** VRF callback fails
- Ensure contract is added as consumer in VRF subscription
- Check subscription has enough LINK tokens
- Verify correct VRF Coordinator address for Base Sepolia

### Frontend

**Issue:** Wallet connection fails
- Check WalletConnect Project ID is set correctly
- Ensure you're on Base Sepolia network in your wallet
- Clear browser cache and reconnect

**Issue:** Contract reads fail
- Verify contract address is correct in `.env`
- Check you're connected to Base Sepolia network
- Ensure contract is deployed and verified

### Backend

**Issue:** Database connection fails
- Check PostgreSQL is running: `sudo systemctl status postgresql`
- Verify DATABASE_URL format is correct
- Test connection: `psql $DATABASE_URL`

**Issue:** Event indexing not working
- Verify CONTRACT_ADDRESS is correct
- Check RPC_URL is accessible
- Ensure START_BLOCK is not too far back (may take time to sync)
- Check backend logs for errors

**Issue:** Prisma errors
- Run `npm run prisma:generate` to regenerate client
- Run `npx prisma db push --force-reset` to reset database (warning: deletes data)

## Development Tips

### Smart Contract Development

```bash
# Watch mode for tests
forge test --watch

# Coverage report
forge coverage

# Gas snapshots
forge snapshot

# Format code
forge fmt
```

### Frontend Development

```bash
# Type checking
npm run type-check

# Linting
npm run lint

# Build analysis
npm run build -- --profile
```

### Backend Development

```bash
# View database
npx prisma studio

# Create migration
npx prisma migrate dev --name migration_name

# Reset database
npx prisma migrate reset
```

## Next Steps

After setup:

1. **Test the smart contract** - Run tests and understand the lottery mechanics
2. **Explore the frontend** - Connect wallet and interact with UI
3. **Check the backend** - View Swagger docs and test API endpoints
4. **Read the architecture** - See [architecture.md](./architecture.md) for technical details
5. **Deploy** - Follow deployment guides for mainnet/production

## Support

For issues or questions:
- Check [architecture.md](./architecture.md) for technical details
- Review contract source code and tests
- Open an issue on GitHub
