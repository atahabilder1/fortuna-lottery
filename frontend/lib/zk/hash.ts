/**
 * Poseidon Hash Implementation (Simplified)
 * This is a simplified version for client-side use
 * In production, use circomlibjs for the actual Poseidon implementation
 */

// BN254 field modulus
const FIELD_MODULUS = BigInt(
  '21888242871839275222246405745257275088548364400416034343698204186575808495617'
);

// Poseidon round constants (first few)
const ROUND_CONSTANTS = [
  BigInt('14397397413755236225575615486459253198602422701513067526754101844196324375522'),
  BigInt('10405129301473404666785234951972711717481302463898292859783056520670200613128'),
  BigInt('5179144822360023508491245509308555580251733042407187134628755730783052214509'),
  BigInt('9132640374240188374542843306219594180154739721841249568925550236430986592615'),
];

/**
 * Modular addition
 */
function addMod(a: bigint, b: bigint): bigint {
  return ((a % FIELD_MODULUS) + (b % FIELD_MODULUS)) % FIELD_MODULUS;
}

/**
 * Modular multiplication
 */
function mulMod(a: bigint, b: bigint): bigint {
  return ((a % FIELD_MODULUS) * (b % FIELD_MODULUS)) % FIELD_MODULUS;
}

/**
 * S-box: x^5 mod p
 */
function sbox(x: bigint): bigint {
  const x2 = mulMod(x, x);
  const x4 = mulMod(x2, x2);
  return mulMod(x4, x);
}

/**
 * Simplified Poseidon hash for 2 inputs
 * Note: This is a simplified version for demonstration
 * Production should use circomlibjs
 */
export function poseidonHash2(a: bigint, b: bigint): bigint {
  let s0 = a % FIELD_MODULUS;
  let s1 = b % FIELD_MODULUS;

  // Add round constant and apply S-box
  s0 = addMod(s0, ROUND_CONSTANTS[0]);
  s0 = sbox(s0);

  // Mix
  const t0 = addMod(s0, s1);
  const t1 = addMod(s0, mulMod(s1, BigInt(2)));

  s0 = t0;
  s1 = t1;

  // Another round
  s0 = addMod(s0, ROUND_CONSTANTS[1]);
  s0 = sbox(s0);
  s1 = addMod(s1, ROUND_CONSTANTS[2]);

  return addMod(s0, s1);
}

/**
 * Poseidon hash for 5 inputs (used for bet commitment)
 * Chains multiple 2-input hashes
 */
export function poseidonHash5(
  a: bigint,
  b: bigint,
  c: bigint,
  d: bigint,
  e: bigint
): bigint {
  const h1 = poseidonHash2(a, b);
  const h2 = poseidonHash2(h1, c);
  const h3 = poseidonHash2(h2, d);
  return poseidonHash2(h3, e);
}

/**
 * Compute bet commitment
 */
export function computeCommitment(
  secret: bigint,
  nullifier: bigint,
  itemId: number,
  tokenAmount: number,
  salt: bigint
): bigint {
  return poseidonHash5(
    secret,
    nullifier,
    BigInt(itemId),
    BigInt(tokenAmount),
    salt
  );
}

/**
 * Compute bet nullifier hash
 */
export function computeNullifierHash(
  nullifier: bigint,
  lotteryId: number
): bigint {
  return poseidonHash2(nullifier, BigInt(lotteryId));
}

/**
 * Compute claim nullifier hash
 */
export function computeClaimNullifierHash(
  nullifier: bigint,
  lotteryId: number,
  itemId: number
): bigint {
  const h1 = poseidonHash2(nullifier, BigInt(lotteryId));
  return poseidonHash2(h1, BigInt(itemId));
}
