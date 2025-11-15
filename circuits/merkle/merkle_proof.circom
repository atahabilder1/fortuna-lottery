pragma circom 2.1.6;

include "../poseidon/poseidon.circom";

// Selector: outputs left, right based on s
// if s == 0: left = in[0], right = in[1]
// if s == 1: left = in[1], right = in[0]
template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0;
    out[0] <== (in[1] - in[0]) * s + in[0];
    out[1] <== (in[0] - in[1]) * s + in[1];
}

// Merkle tree proof verification
// Proves that a leaf is part of a Merkle tree with given root
template MerkleProof(levels) {
    signal input leaf;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    signal input root;

    component selectors[levels];
    component hashers[levels];

    signal levelHashes[levels + 1];
    levelHashes[0] <== leaf;

    for (var i = 0; i < levels; i++) {
        selectors[i] = DualMux();
        selectors[i].in[0] <== levelHashes[i];
        selectors[i].in[1] <== pathElements[i];
        selectors[i].s <== pathIndices[i];

        hashers[i] = PoseidonHash2();
        hashers[i].in[0] <== selectors[i].out[0];
        hashers[i].in[1] <== selectors[i].out[1];

        levelHashes[i + 1] <== hashers[i].out;
    }

    // Verify computed root matches expected root
    root === levelHashes[levels];
}

// Compute Merkle root from leaf and path
template MerkleRoot(levels) {
    signal input leaf;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    signal output root;

    component selectors[levels];
    component hashers[levels];

    signal levelHashes[levels + 1];
    levelHashes[0] <== leaf;

    for (var i = 0; i < levels; i++) {
        selectors[i] = DualMux();
        selectors[i].in[0] <== levelHashes[i];
        selectors[i].in[1] <== pathElements[i];
        selectors[i].s <== pathIndices[i];

        hashers[i] = PoseidonHash2();
        hashers[i].in[0] <== selectors[i].out[0];
        hashers[i].in[1] <== selectors[i].out[1];

        levelHashes[i + 1] <== hashers[i].out;
    }

    root <== levelHashes[levels];
}
