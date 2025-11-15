/**
 * ZK Lottery Types
 * Type definitions for zero-knowledge proof lottery operations
 */

export interface BetSecrets {
  secret: bigint;
  nullifier: bigint;
  salt: bigint;
}

export interface StoredBet {
  lotteryId: number;
  itemId: number;
  tokenAmount: number;
  commitment: string;
  nullifierHash: string;
  secrets: {
    secret: string;
    nullifier: string;
    salt: string;
  };
  ticketRange: {
    start: number;
    end: number;
  };
  merkleIndex: number;
  merklePath?: string[];
  merklePathIndices?: number[];
  createdAt: number;
}

export interface BetProofInput {
  secrets: BetSecrets;
  itemId: number;
  tokenAmount: number;
  lotteryId: number;
}

export interface WinnerProofInput {
  secrets: BetSecrets;
  itemId: number;
  tokenAmount: number;
  lotteryId: number;
  merkleRoot: bigint;
  winningPosition: number;
  ticketStartPosition: number;
  merklePath: string[];
  merklePathIndices: number[];
  recipientAddress: string;
}

export interface Groth16Proof {
  pi_a: [string, string, string];
  pi_b: [[string, string], [string, string], [string, string]];
  pi_c: [string, string, string];
  protocol: string;
  curve: string;
}

export interface ProofResult {
  proof: bigint[];
  commitment: bigint;
  nullifierHash: bigint;
}

export interface WinnerProofResult {
  proof: bigint[];
  claimNullifierHash: bigint;
}

export interface MerkleProof {
  pathElements: string[];
  pathIndices: number[];
  root: string;
}
