# Fortuna Lottery Architecture

## Overview

Fortuna Lottery implements a decentralized **Chinese Lottery** (also known as Chinese Auction or Penny Social) on the Base Sepolia testnet. Unlike traditional auctions where the highest bidder wins, this system uses **weighted random selection** where participants' winning chances are proportional to the tokens they place on items.

## System Architecture

### Smart Contract (`FortunaLottery.sol`)

The core contract manages the entire lottery lifecycle and integrates with Chainlink VRF for provably fair randomness.

#### Key Components

1. **Lottery Management**
   - Create lotteries with multiple items
   - Set start/end times and token allocations
   - End lotteries early (owner only)

2. **Participant System**
   - Registration gives participants a fixed number of tokens
   - Tokens can be distributed across multiple items
   - Supports batch token placement for gas efficiency

3. **Random Winner Selection**
   - Chainlink VRF v2.5 integration
   - Weighted probability based on tokens placed
   - Provably fair and verifiable randomness

## Contract Structure

### Data Models

#### Lottery
```solidity
struct Lottery {
    uint256 id;
    string name;
    uint256 tokensPerParticipant;
    uint256 startTime;
    uint256 endTime;
    uint256 itemCount;
    bool isActive;
    mapping(uint256 => LotteryItem) items;
    mapping(address => ParticipantInfo) participants;
    address[] participantList;
}
```

#### LotteryItem
```solidity
struct LotteryItem {
    string name;
    string description;
    uint256 totalTokens;
    address winner;
    bool winnerSelected;
}
```

#### ParticipantInfo
```solidity
struct ParticipantInfo {
    uint256 totalTokens;
    uint256 tokensUsed;
    mapping(uint256 => uint256) tokensPerItem;
    bool registered;
}
```

## Lottery Lifecycle

### 1. Creation Phase
- **Owner** creates a lottery with:
  - Name and time window
  - Array of items (names and descriptions)
  - Tokens per participant
- Contract assigns unique lottery ID
- Lottery becomes active

### 2. Registration Phase
- Participants call `registerParticipant(lotteryId)`
- Receive fixed number of tokens
- Can only register once per lottery
- Must be within lottery time window

### 3. Token Distribution Phase
- Participants distribute tokens across items
- Can use `placeTokens()` for single items
- Can use `placeTokensBatch()` for multiple items
- Tokens are tracked per participant per item
- Cannot exceed allocated token amount

### 4. Winner Selection Phase (Post-Lottery)
- **Owner** calls `requestWinner(lotteryId, itemId)`
- Contract requests random number from Chainlink VRF
- VRF Coordinator processes request
- Callback to `fulfillRandomWords()` with randomness
- Winner selected using weighted algorithm
- Winner address stored permanently

## Chainlink VRF Integration

### Configuration (Base Sepolia)
- **VRF Coordinator:** `0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE`
- **Key Hash:** `0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8` (30 gwei)
- **Request Confirmations:** 3 blocks
- **Callback Gas Limit:** 200,000 gas

### VRF Flow
1. Owner requests winner for an item
2. Contract calls VRF Coordinator with request parameters
3. VRF Coordinator generates random number off-chain
4. After confirmations, VRF calls back with random number
5. Contract uses randomness to select winner
6. Winner assigned and event emitted

## Winner Selection Algorithm

The weighted selection ensures fair probability distribution:

```
1. Calculate total tokens placed on item
2. Generate random position: randomNumber % totalTokens
3. Iterate through participants:
   - Track cumulative tokens
   - When cumulative >= random position, that participant wins
```

### Example

**Item A** has:
- Alice: 10 tokens (0-9)
- Bob: 5 tokens (10-14)
- Carol: 15 tokens (15-29)
- **Total:** 30 tokens

**Random number:** 18 (mod 30)
- Cumulative after Alice: 10 (< 18, continue)
- Cumulative after Bob: 15 (< 18, continue)
- Cumulative after Carol: 30 (>= 18, **Carol wins!**)

**Probabilities:**
- Alice: 10/30 = 33.3%
- Bob: 5/30 = 16.7%
- Carol: 15/30 = 50.0%

## Security Features

1. **ReentrancyGuard** - Prevents reentrancy attacks on token operations
2. **Access Control** - Chainlink ownership pattern for admin functions
3. **Input Validation** - Comprehensive checks on all parameters
4. **Custom Errors** - Gas-efficient error handling
5. **Immutable VRF Config** - Prevents tampering with randomness source

## Gas Optimization

- Uses `calldata` for array parameters
- Batch token placement reduces transaction count
- Efficient storage patterns with mappings
- Custom errors instead of string reverts
- Immutable variables for constants

## Testing

### Test Coverage (`FortunaLottery.t.sol`)

-  Lottery creation and validation
-  Participant registration (single and duplicate prevention)
-  Token placement (single and batch)
-  Multi-participant scenarios
-  Lottery ending and state transitions
-  Access control for owner functions
-  Error conditions and edge cases

**12 tests, 100% passing**

## Deployment

### Prerequisites
1. Base Sepolia ETH (from faucet)
2. Chainlink VRF subscription (vrf.chain.link)
3. Environment variables configured

### Deployment Steps
```bash
# 1. Set environment variables
export BASE_SEPOLIA_RPC="https://sepolia.base.org"
export PRIVATE_KEY="your_private_key"
export VRF_SUBSCRIPTION_ID="your_subscription_id"

# 2. Deploy contract
forge script script/DeployLottery.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify

# 3. Add contract as VRF consumer
# Go to vrf.chain.link/base-sepolia
# Add deployed contract address to subscription
```

## Frontend Architecture

### Tech Stack
- **Next.js 14** with App Router
- **wagmi v2** for blockchain interactions
- **RainbowKit** for wallet connection
- **viem** for Ethereum utilities
- **TailwindCSS** for styling

### Key Features
- Wallet connection with multiple providers
- Real-time contract data reading
- Participant registration flow
- Token placement interface
- Live win probability calculations
- Responsive design for all devices

### Components
- `LotteryList`: Displays all active lotteries
- `LotteryCard`: Individual lottery preview card
- `LotteryItems`: Shows items within a lottery
- `WalletButton`: Custom RainbowKit wallet connector

### Contract Integration
Uses custom React hooks from `lib/contracts/hooks.ts`:
- `useCurrentLotteryId()` - Get total lottery count
- `useLotteryInfo(lotteryId)` - Fetch lottery details
- `useItemInfo(lotteryId, itemId)` - Get item information
- `useParticipantInfo(lotteryId, address)` - User participation data
- `useRegisterParticipant()` - Register for lottery
- `usePlaceTokens()` - Place tokens on items
- `usePlaceTokensBatch()` - Batch token placement

## Backend Architecture

### Tech Stack
- **NestJS** framework
- **Prisma ORM** with PostgreSQL
- **viem** for blockchain event indexing
- **TypeScript** for type safety

### Database Schema (Prisma)

```prisma
model Lottery {
  id                   Int      @id @default(autoincrement())
  contractLotteryId    Int      @unique
  name                 String
  tokensPerParticipant Int
  startTime            DateTime
  endTime              DateTime
  itemCount            Int
  isActive             Boolean
  items                LotteryItem[]
  participants         Participant[]
}

model LotteryItem {
  id                Int     @id @default(autoincrement())
  lotteryId         Int
  contractItemId    Int
  name              String
  description       String
  totalTokens       Int
  winner            String?
  winnerSelected    Boolean
  lottery           Lottery @relation(fields: [lotteryId], references: [id])
}

model Participant {
  id           Int
  lotteryId    Int
  address      String
  totalTokens  Int
  tokensUsed   Int
  registered   Boolean
  lottery      Lottery @relation(fields: [lotteryId], references: [id])
}
```

### Event Indexing Service

The `IndexerService` automatically:
1. **Indexes historical events** on startup from START_BLOCK
2. **Watches for new events** in real-time
3. **Syncs to PostgreSQL** via Prisma

**Events tracked:**
- `LotteryCreated` - New lottery created
- `ParticipantRegistered` - User registers
- `TokensPlaced` - Tokens placed on items
- `WinnerSelected` - Winner chosen by VRF

### API Endpoints

- `GET /lottery` - List all lotteries
- `GET /lottery/:id` - Get lottery by ID
- `GET /lottery/:id/items` - Get lottery items
- `GET /lottery/:id/participants` - Get participants

Swagger documentation at `/api`

## System Integration Flow

```
User Wallet
    ↓
Frontend (Next.js)
    ↓
Smart Contract (Base Sepolia)
    ↓
Blockchain Events
    ↓
Backend Indexer (NestJS)
    ↓
PostgreSQL Database
    ↓
REST API
    ↓
Frontend / External Apps
```

## Future Enhancements

### Smart Contract
- Multi-token support (ERC20/ERC721 prizes)
- Automatic winner selection at end time
- Participant refunds for cancelled lotteries
- Lottery templates for recurring events

### Frontend
- Winner announcement animations
- Historical lottery archive
- Advanced filtering and search
- User analytics dashboard

### Backend
- WebSocket for live updates
- Caching layer (Redis)
- GraphQL API option
- Admin dashboard

## Technical Stack

### Blockchain
- **Network:** Base Sepolia (Coinbase L2 testnet)
- **Language:** Solidity 0.8.25
- **Framework:** Foundry
- **Oracles:** Chainlink VRF v2.5
- **Libraries:** OpenZeppelin Contracts v5

### Development Tools
- **Testing:** Forge (Foundry)
- **Deployment:** Forge Scripts
- **Verification:** Basescan API
- **Version Control:** Git/GitHub

## Contract Address

**Base Sepolia:** (Deploy with script)

To deploy:
```bash
forge script script/DeployLottery.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast
```

## Resources

- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [Chainlink VRF Docs](https://docs.chain.link/vrf)
- [Foundry Book](https://book.getfoundry.sh/)
- [Base Documentation](https://docs.base.org/)
- [Contract Source](../contracts/FortunaLottery.sol)
- [Tests](../test/FortunaLottery.t.sol)

## License

MIT License - See [LICENSE](../LICENSE) for details.
