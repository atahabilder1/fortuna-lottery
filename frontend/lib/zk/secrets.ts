/**
 * ZK Secrets Management
 * Handles generation and secure storage of ZK lottery secrets
 */

import { BetSecrets, StoredBet } from './types';

const STORAGE_KEY = 'fortuna_lottery_zk_bets';

/**
 * Generate cryptographically secure random secrets for a bet
 */
export function generateSecrets(): BetSecrets {
  const randomBytes = new Uint8Array(96); // 32 bytes each for secret, nullifier, salt
  crypto.getRandomValues(randomBytes);

  return {
    secret: bytesToBigInt(randomBytes.slice(0, 32)),
    nullifier: bytesToBigInt(randomBytes.slice(32, 64)),
    salt: bytesToBigInt(randomBytes.slice(64, 96)),
  };
}

/**
 * Convert bytes to bigint
 */
function bytesToBigInt(bytes: Uint8Array): bigint {
  let result = BigInt(0);
  for (let i = 0; i < bytes.length; i++) {
    result = (result << BigInt(8)) + BigInt(bytes[i]);
  }
  return result;
}

/**
 * Store a bet in local storage
 * In production, consider encrypting with user's wallet signature
 */
export function storeBet(bet: StoredBet): void {
  const existing = getBets();
  existing.push(bet);

  // Store as JSON - secrets are stored as strings for JSON compatibility
  if (typeof window !== 'undefined') {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(existing));
  }
}

/**
 * Get all stored bets
 */
export function getBets(): StoredBet[] {
  if (typeof window === 'undefined') return [];

  const stored = localStorage.getItem(STORAGE_KEY);
  if (!stored) return [];

  try {
    return JSON.parse(stored);
  } catch {
    return [];
  }
}

/**
 * Get bets for a specific lottery
 */
export function getBetsForLottery(lotteryId: number): StoredBet[] {
  return getBets().filter((b) => b.lotteryId === lotteryId);
}

/**
 * Get bets for a specific item in a lottery
 */
export function getBetsForItem(lotteryId: number, itemId: number): StoredBet[] {
  return getBets().filter(
    (b) => b.lotteryId === lotteryId && b.itemId === itemId
  );
}

/**
 * Find a winning bet based on the winning position
 */
export function findWinningBet(
  lotteryId: number,
  itemId: number,
  winningPosition: number
): StoredBet | null {
  const bets = getBetsForItem(lotteryId, itemId);

  for (const bet of bets) {
    if (
      winningPosition >= bet.ticketRange.start &&
      winningPosition < bet.ticketRange.end
    ) {
      return bet;
    }
  }

  return null;
}

/**
 * Update a bet with merkle path information
 */
export function updateBetWithMerklePath(
  commitment: string,
  merkleIndex: number,
  merklePath: string[],
  merklePathIndices: number[]
): void {
  const bets = getBets();
  const index = bets.findIndex((b) => b.commitment === commitment);

  if (index !== -1) {
    bets[index].merkleIndex = merkleIndex;
    bets[index].merklePath = merklePath;
    bets[index].merklePathIndices = merklePathIndices;

    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(bets));
    }
  }
}

/**
 * Clear all stored bets
 */
export function clearAllBets(): void {
  if (typeof window !== 'undefined') {
    localStorage.removeItem(STORAGE_KEY);
  }
}

/**
 * Clear bets for a specific lottery
 */
export function clearLotteryBets(lotteryId: number): void {
  const remaining = getBets().filter((b) => b.lotteryId !== lotteryId);
  if (typeof window !== 'undefined') {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(remaining));
  }
}

/**
 * Export bets as encrypted backup
 * In production, encrypt with user's wallet signature
 */
export function exportBets(): string {
  const bets = getBets();
  return btoa(JSON.stringify(bets));
}

/**
 * Import bets from backup
 */
export function importBets(backup: string): boolean {
  try {
    const bets = JSON.parse(atob(backup));
    if (Array.isArray(bets)) {
      if (typeof window !== 'undefined') {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(bets));
      }
      return true;
    }
    return false;
  } catch {
    return false;
  }
}

/**
 * Reconstruct BetSecrets from stored string format
 */
export function reconstructSecrets(stored: StoredBet['secrets']): BetSecrets {
  return {
    secret: BigInt(stored.secret),
    nullifier: BigInt(stored.nullifier),
    salt: BigInt(stored.salt),
  };
}
