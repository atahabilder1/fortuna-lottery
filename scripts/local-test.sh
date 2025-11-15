#!/bin/bash

# Fortuna Lottery - Local Testing Script
# This script sets up a complete local testing environment

set -e

echo "=========================================="
echo "  Fortuna Lottery - Local Test Setup"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check prerequisites
echo -e "\n${YELLOW}Step 1: Checking prerequisites...${NC}"

if ! command -v forge &> /dev/null; then
    echo "Foundry not found. Install with: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi
echo -e "${GREEN}✓ Foundry installed${NC}"

if ! command -v anvil &> /dev/null; then
    echo "Anvil not found. Run: foundryup"
    exit 1
fi
echo -e "${GREEN}✓ Anvil installed${NC}"

# Step 2: Build contracts
echo -e "\n${YELLOW}Step 2: Building contracts...${NC}"
forge build

echo -e "${GREEN}✓ Contracts compiled${NC}"

# Step 3: Run tests
echo -e "\n${YELLOW}Step 3: Running smart contract tests...${NC}"
forge test -vv

echo -e "${GREEN}✓ All tests passed${NC}"

# Step 4: Start Anvil in background
echo -e "\n${YELLOW}Step 4: Starting local blockchain (Anvil)...${NC}"

# Kill any existing Anvil process
pkill -f "anvil" 2>/dev/null || true
sleep 1

anvil --block-time 1 &
ANVIL_PID=$!
echo "Anvil started with PID: $ANVIL_PID"
sleep 2

echo -e "${GREEN}✓ Anvil running on http://localhost:8545${NC}"

# Step 5: Deploy contracts locally
echo -e "\n${YELLOW}Step 5: Deploying contracts to local chain...${NC}"

forge script script/DeployLocalZK.s.sol \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --verbosity 2

echo -e "${GREEN}✓ Contracts deployed${NC}"

# Summary
echo -e "\n=========================================="
echo -e "  ${GREEN}Local Test Environment Ready!${NC}"
echo -e "=========================================="
echo ""
echo "Local blockchain: http://localhost:8545"
echo ""
echo "Test accounts (with 10000 ETH each):"
echo "  Account 0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "  Account 1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
echo "  Account 2: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
echo ""
echo "Private key for Account 0 (use in MetaMask):"
echo "  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
echo ""
echo "To stop Anvil: kill $ANVIL_PID"
echo ""
echo "Next steps:"
echo "  1. Update frontend/.env with the contract address above"
echo "  2. Run 'cd frontend && npm run dev'"
echo "  3. Connect MetaMask to http://localhost:8545 (Chain ID: 31337)"
echo "  4. Import the test account using the private key above"
echo ""
