# Fortuna Lottery ZK Circuits

Zero-knowledge circuits for private lottery betting using Circom 2.1.6.

## Circuits

### 1. Bet Commitment (`commitment/bet_commitment.circom`)
Proves a valid bet commitment without revealing bet details.

**Private Inputs:**
- `secret` - Random 256-bit secret
- `nullifier` - Unique identifier for this bet
- `itemId` - Which lottery item
- `tokenAmount` - Number of tokens placed
- `salt` - Additional randomness

**Public Inputs:**
- `lotteryId` - The lottery identifier

**Outputs:**
- `commitment` - Hash of all bet data
- `nullifierHash` - For preventing double-use

### 2. Winner Proof (`winner/winner_proof.circom`)
Proves ownership of the winning ticket without revealing identity.

**Private Inputs:**
- All bet commitment inputs
- `pathElements` - Merkle path to root
- `pathIndices` - Path direction indices
- `ticketStartPosition` - Start of ticket range

**Public Inputs:**
- `lotteryId` - Lottery identifier
- `winningItemId` - Item that won
- `merkleRoot` - Commitment tree root
- `winningPosition` - VRF random result
- `claimNullifierHash` - Prevents double claims
- `recipientAddress` - Where to send prize

## Compilation

```bash
# Install circom
npm install -g circom snarkjs

# Compile bet commitment circuit
circom circuits/commitment/bet_commitment.circom --r1cs --wasm --sym -o build/

# Compile winner proof circuit
circom circuits/winner/winner_proof.circom --r1cs --wasm --sym -o build/

# Generate proving keys (requires Powers of Tau)
snarkjs groth16 setup build/bet_commitment.r1cs pot_final.ptau bet_commitment.zkey
snarkjs groth16 setup build/winner_proof.r1cs pot_final.ptau winner_proof.zkey

# Export Solidity verifiers
snarkjs zkey export solidityverifier bet_commitment.zkey contracts/verifiers/BetVerifier.sol
snarkjs zkey export solidityverifier winner_proof.zkey contracts/verifiers/WinnerVerifier.sol
```
