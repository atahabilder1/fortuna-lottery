/**
 * ZK Library Exports
 * Central export point for all ZK functionality
 */

// Types
export type {
  BetSecrets,
  StoredBet,
  BetProofInput,
  WinnerProofInput,
  Groth16Proof,
  ProofResult,
  WinnerProofResult,
  MerkleProof,
} from './types';

// Hash functions
export {
  poseidonHash2,
  poseidonHash5,
  computeCommitment,
  computeNullifierHash,
  computeClaimNullifierHash,
} from './hash';

// Secrets management
export {
  generateSecrets,
  storeBet,
  getBets,
  getBetsForLottery,
  getBetsForItem,
  findWinningBet,
  updateBetWithMerklePath,
  clearAllBets,
  clearLotteryBets,
  exportBets,
  importBets,
  reconstructSecrets,
} from './secrets';

// Prover
export {
  generateBetProof,
  generateWinnerProof,
  formatProofForContract,
  verifyProofLocally,
  checkForWinningBet,
} from './prover';
