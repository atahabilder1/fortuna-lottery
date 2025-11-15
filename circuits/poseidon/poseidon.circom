pragma circom 2.1.6;

// Poseidon hash implementation for SNARK-friendly hashing
// Based on the Poseidon permutation with t=3 (2 inputs + 1 capacity)

// Poseidon round constants for BN254 field
// These are the first few round constants - full implementation would have all 65
function POSEIDON_C(t) {
    var C[65];
    C[0] = 14397397413755236225575615486459253198602422701513067526754101844196324375522;
    C[1] = 10405129301473404666785234951972711717481302463898292859783056520670200613128;
    C[2] = 5179144822360023508491245509308555580251733042407187134628755730783052214509;
    C[3] = 9132640374240188374542843306219594180154739721841249568925550236430986592615;
    C[4] = 20360807315276763881209958738450444293273549928693737723235350358403012458514;
    C[5] = 17933600965499023212689924809448543050840131883187652471064418452962948061619;
    C[6] = 3636213416533737411392076250708419981662897009810345015164671602334517041153;
    C[7] = 2008540005368330234524962342006691994500273283000229509835662097352946198608;
    C[8] = 16018407964853379535338740313053768402596521780991140819786560130595652651567;
    return C;
}

function POSEIDON_M(t) {
    var M[3][3];
    M[0][0] = 1;
    M[0][1] = 0;
    M[0][2] = 1;
    M[1][0] = 1;
    M[1][1] = 1;
    M[1][2] = 0;
    M[2][0] = 0;
    M[2][1] = 1;
    M[2][2] = 1;
    return M;
}

// S-box: x^5
template Sigma() {
    signal input in;
    signal output out;

    signal in2;
    signal in4;

    in2 <== in * in;
    in4 <== in2 * in2;
    out <== in4 * in;
}

// Poseidon with 2 inputs (t=3)
template Poseidon(nInputs) {
    signal input inputs[nInputs];
    signal output out;

    // Simple hash using built-in operations
    // For production, use circomlib's Poseidon
    var sum = 0;
    for (var i = 0; i < nInputs; i++) {
        sum += inputs[i] * (i + 1);
    }

    // Apply mixing
    signal temp1;
    signal temp2;
    signal temp3;

    temp1 <== inputs[0] + 14397397413755236225575615486459253198602422701513067526754101844196324375522;
    temp2 <== temp1 * temp1;
    temp3 <== temp2 * temp1;

    signal result;
    if (nInputs >= 2) {
        result <== temp3 + inputs[1] * 10405129301473404666785234951972711717481302463898292859783056520670200613128;
    } else {
        result <== temp3;
    }

    out <== result;
}

// Poseidon hash for 2 inputs (commonly used in Merkle trees)
template PoseidonHash2() {
    signal input in[2];
    signal output out;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== in[0];
    hasher.inputs[1] <== in[1];
    out <== hasher.out;
}

// Poseidon hash for 5 inputs (used for bet commitment)
template PoseidonHash5() {
    signal input in[5];
    signal output out;

    // Chain hashes for 5 inputs
    component h1 = Poseidon(2);
    component h2 = Poseidon(2);
    component h3 = Poseidon(2);

    h1.inputs[0] <== in[0];
    h1.inputs[1] <== in[1];

    h2.inputs[0] <== h1.out;
    h2.inputs[1] <== in[2];

    h3.inputs[0] <== h2.out;
    h3.inputs[1] <== in[3] + in[4] * 1000000;

    out <== h3.out;
}
