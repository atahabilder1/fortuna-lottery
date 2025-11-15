pragma circom 2.1.6;

include "../poseidon/poseidon.circom";
include "../merkle/merkle_proof.circom";
include "../lib/comparators.circom";

// Winner Proof Circuit
// Proves that the prover owns a commitment in the Merkle tree
// that covers the winning ticket position, without revealing identity

template WinnerProof(merkleTreeDepth) {
    // Private inputs (known only to the winner)
    signal input secret;
    signal input nullifier;
    signal input itemId;
    signal input tokenAmount;
    signal input salt;
    signal input pathElements[merkleTreeDepth];
    signal input pathIndices[merkleTreeDepth];
    signal input ticketStartPosition;  // Where this bet's tickets start

    // Public inputs
    signal input lotteryId;
    signal input winningItemId;        // The item that won (from VRF)
    signal input merkleRoot;           // Final commitment tree root
    signal input winningPosition;      // Random position from VRF
    signal input claimNullifierHash;   // To prevent double claims
    signal input recipientAddress;     // Where to send the prize

    // Constraint 1: The bet must be for the winning item
    component itemCheck = IsEqual();
    itemCheck.in[0] <== itemId;
    itemCheck.in[1] <== winningItemId;
    itemCheck.out === 1;

    // Constraint 2: Recompute the commitment
    component commitmentHasher = PoseidonHash5();
    commitmentHasher.in[0] <== secret;
    commitmentHasher.in[1] <== nullifier;
    commitmentHasher.in[2] <== itemId;
    commitmentHasher.in[3] <== tokenAmount;
    commitmentHasher.in[4] <== salt;
    signal commitment;
    commitment <== commitmentHasher.out;

    // Constraint 3: Verify commitment is in the Merkle tree
    component merkleProof = MerkleProof(merkleTreeDepth);
    merkleProof.leaf <== commitment;
    for (var i = 0; i < merkleTreeDepth; i++) {
        merkleProof.pathElements[i] <== pathElements[i];
        merkleProof.pathIndices[i] <== pathIndices[i];
    }
    merkleProof.root <== merkleRoot;

    // Constraint 4: Winning position must be >= ticketStartPosition
    component geStart = GreaterEqThan(64);
    geStart.in[0] <== winningPosition;
    geStart.in[1] <== ticketStartPosition;
    geStart.out === 1;

    // Constraint 5: Winning position must be < ticketStartPosition + tokenAmount
    signal ticketEndPosition;
    ticketEndPosition <== ticketStartPosition + tokenAmount;
    component ltEnd = LessThan(64);
    ltEnd.in[0] <== winningPosition;
    ltEnd.in[1] <== ticketEndPosition;
    ltEnd.out === 1;

    // Constraint 6: Verify claim nullifier hash matches
    // claimNullifierHash = Poseidon(nullifier, lotteryId, itemId)
    component claimHasher1 = PoseidonHash2();
    claimHasher1.in[0] <== nullifier;
    claimHasher1.in[1] <== lotteryId;

    component claimHasher2 = PoseidonHash2();
    claimHasher2.in[0] <== claimHasher1.out;
    claimHasher2.in[1] <== itemId;

    claimNullifierHash === claimHasher2.out;

    // Note: recipientAddress is a public input that the winner chooses
    // The contract will send the prize to this address
    // This enables anonymous claiming - winner can use a fresh address
}

// Main component with 20-level Merkle tree (supports ~1M commitments)
component main {public [
    lotteryId,
    winningItemId,
    merkleRoot,
    winningPosition,
    claimNullifierHash,
    recipientAddress
]} = WinnerProof(20);
