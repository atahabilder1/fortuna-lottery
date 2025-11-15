pragma circom 2.1.6;

include "../poseidon/poseidon.circom";
include "../lib/comparators.circom";

// Bet Commitment Circuit
// Proves that a commitment is validly formed for a lottery bet
// without revealing the actual bet details

template BetCommitment() {
    // Private inputs (known only to the bettor)
    signal input secret;           // Random secret (256 bits)
    signal input nullifier;        // Unique nullifier for this bet
    signal input itemId;           // Which item tokens are placed on
    signal input tokenAmount;      // Number of tokens placed
    signal input salt;             // Additional randomness

    // Public inputs
    signal input lotteryId;        // Public lottery identifier

    // Public outputs
    signal output commitment;      // Hash of all bet data
    signal output nullifierHash;   // Hash for tracking (prevents double-use)

    // Constraint 1: tokenAmount must be positive (> 0)
    component tokenCheck = GreaterThan(64);
    tokenCheck.in[0] <== tokenAmount;
    tokenCheck.in[1] <== 0;
    tokenCheck.out === 1;

    // Constraint 2: itemId must be reasonable (< 2^32)
    component itemCheck = LessThan(32);
    itemCheck.in[0] <== itemId;
    itemCheck.in[1] <== 4294967296; // 2^32
    itemCheck.out === 1;

    // Compute commitment = Poseidon(secret, nullifier, itemId, tokenAmount, salt)
    component commitmentHasher = PoseidonHash5();
    commitmentHasher.in[0] <== secret;
    commitmentHasher.in[1] <== nullifier;
    commitmentHasher.in[2] <== itemId;
    commitmentHasher.in[3] <== tokenAmount;
    commitmentHasher.in[4] <== salt;
    commitment <== commitmentHasher.out;

    // Compute nullifier hash = Poseidon(nullifier, lotteryId)
    // This allows tracking without revealing the actual nullifier
    component nullifierHasher = PoseidonHash2();
    nullifierHasher.in[0] <== nullifier;
    nullifierHasher.in[1] <== lotteryId;
    nullifierHash <== nullifierHasher.out;
}

component main {public [lotteryId]} = BetCommitment();
