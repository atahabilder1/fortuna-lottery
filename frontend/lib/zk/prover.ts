/**
 * ZK Prover
 * Handles proof generation for private lottery betting
 *
 * Note: In production, this would use snarkjs to generate actual ZK proofs
 * For local testing with mock verifiers, we generate placeholder proofs
 */

import { BetSecrets, ProofResult, WinnerProofResult, StoredBet } from './types';
import {
  computeCommitment,
  computeNullifierHash,
  computeClaimNullifierHash,
} from './hash';
import { generateSecrets, storeBet, reconstructSecrets } from './secrets';

/**
 * Generate a bet commitment proof
 * Returns the proof, commitment, and nullifier hash
 */
export async function generateBetProof(
  lotteryId: number,
  itemId: number,
  tokenAmount: number,
  totalTokensBefore: number
): Promise<{
  proof: bigint[];
  commitment: bigint;
  nullifierHash: bigint;
  secrets: BetSecrets;
  ticketRange: { start: number; end: number };
}> {
  // Generate fresh secrets
  const secrets = generateSecrets();

  // Compute commitment: Poseidon(secret, nullifier, itemId, tokenAmount, salt)
  const commitment = computeCommitment(
    secrets.secret,
    secrets.nullifier,
    itemId,
    tokenAmount,
    secrets.salt
  );

  // Compute nullifier hash: Poseidon(nullifier, lotteryId)
  const nullifierHash = computeNullifierHash(secrets.nullifier, lotteryId);

  // Calculate ticket range
  const ticketRange = {
    start: totalTokensBefore,
    end: totalTokensBefore + tokenAmount,
  };

  // In production, generate actual Groth16 proof here using snarkjs
  // For now, generate placeholder proof for mock verifier
  const proof = generatePlaceholderProof();

  // Store bet locally for later claim
  const storedBet: StoredBet = {
    lotteryId,
    itemId,
    tokenAmount,
    commitment: commitment.toString(),
    nullifierHash: nullifierHash.toString(),
    secrets: {
      secret: secrets.secret.toString(),
      nullifier: secrets.nullifier.toString(),
      salt: secrets.salt.toString(),
    },
    ticketRange,
    merkleIndex: -1, // Will be updated after transaction confirms
    createdAt: Date.now(),
  };

  storeBet(storedBet);

  return {
    proof,
    commitment,
    nullifierHash,
    secrets,
    ticketRange,
  };
}

/**
 * Generate a winner claim proof
 * Proves ownership of the winning ticket without revealing identity
 */
export async function generateWinnerProof(
  storedBet: StoredBet,
  winningPosition: number,
  merkleRoot: bigint,
  recipientAddress: string
): Promise<WinnerProofResult> {
  // Reconstruct secrets from stored bet
  const secrets = reconstructSecrets(storedBet.secrets);

  // Compute claim nullifier hash: Poseidon(Poseidon(nullifier, lotteryId), itemId)
  const claimNullifierHash = computeClaimNullifierHash(
    secrets.nullifier,
    storedBet.lotteryId,
    storedBet.itemId
  );

  // In production, generate actual Groth16 proof here using snarkjs
  // This would prove:
  // 1. Commitment is in Merkle tree
  // 2. Commitment covers the winning position
  // 3. Claim nullifier is correctly derived
  const proof = generatePlaceholderProof();

  return {
    proof,
    claimNullifierHash,
  };
}

/**
 * Generate placeholder proof for mock verifier testing
 * In production, replace with actual snarkjs proof generation
 */
function generatePlaceholderProof(): bigint[] {
  // Groth16 proof has 8 elements: [a[0], a[1], b[0][0], b[0][1], b[1][0], b[1][1], c[0], c[1]]
  return Array(8)
    .fill(null)
    .map(() => BigInt(Math.floor(Math.random() * 1e18)));
}

/**
 * Format proof for contract call
 * Converts bigint array to format expected by Solidity
 */
export function formatProofForContract(
  proof: bigint[]
): `0x${string}`[] {
  return proof.map((p) => `0x${p.toString(16).padStart(64, '0')}` as `0x${string}`);
}

/**
 * Verify a proof locally (for debugging)
 * In production, verification happens on-chain
 */
export function verifyProofLocally(
  proof: bigint[],
  publicInputs: bigint[]
): boolean {
  // With mock verifier, always return true
  // In production, use snarkjs.groth16.verify()
  return proof.length === 8 && publicInputs.length > 0;
}

/**
 * Check if user has any winning bets for an item
 */
export function checkForWinningBet(
  lotteryId: number,
  itemId: number,
  winningPosition: number
): StoredBet | null {
  // Import here to avoid circular dependency
  const { findWinningBet } = require('./secrets');
  return findWinningBet(lotteryId, itemId, winningPosition);
}
