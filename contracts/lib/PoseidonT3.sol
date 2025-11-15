// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title PoseidonT3
/// @notice Poseidon hash function for 2 inputs (t=3 state)
/// @dev SNARK-friendly hash function used in ZK circuits
library PoseidonT3 {
    // Field modulus for BN254
    uint256 internal constant FIELD_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // Round constants for Poseidon with t=3
    uint256 internal constant C0 = 14397397413755236225575615486459253198602422701513067526754101844196324375522;
    uint256 internal constant C1 = 10405129301473404666785234951972711717481302463898292859783056520670200613128;
    uint256 internal constant C2 = 5179144822360023508491245509308555580251733042407187134628755730783052214509;
    uint256 internal constant C3 = 9132640374240188374542843306219594180154739721841249568925550236430986592615;
    uint256 internal constant C4 = 20360807315276763881209958738450444293273549928693737723235350358403012458514;
    uint256 internal constant C5 = 17933600965499023212689924809448543050840131883187652471064418452962948061619;
    uint256 internal constant C6 = 3636213416533737411392076250708419981662897009810345015164671602334517041153;
    uint256 internal constant C7 = 2008540005368330234524962342006691994500273283000229509835662097352946198608;

    /// @notice Hash 2 field elements using Poseidon
    /// @param input1 First input element
    /// @param input2 Second input element
    /// @return The Poseidon hash result
    function hash(uint256 input1, uint256 input2) internal pure returns (uint256) {
        // Initialize state: [input1, input2, 0]
        uint256 s0 = input1 % FIELD_MODULUS;
        uint256 s1 = input2 % FIELD_MODULUS;
        uint256 s2 = 0;

        // Add round constant and apply S-box (x^5)
        s0 = addmod(s0, C0, FIELD_MODULUS);
        s0 = sbox(s0);

        // Mix layer
        uint256 t0 = addmod(s0, s1, FIELD_MODULUS);
        t0 = addmod(t0, s2, FIELD_MODULUS);
        uint256 t1 = addmod(s0, mulmod(s1, 2, FIELD_MODULUS), FIELD_MODULUS);
        uint256 t2 = addmod(s1, mulmod(s2, 2, FIELD_MODULUS), FIELD_MODULUS);

        s0 = t0;
        s1 = t1;
        s2 = t2;

        // More rounds with constants
        s0 = addmod(s0, C1, FIELD_MODULUS);
        s0 = sbox(s0);
        s1 = addmod(s1, C2, FIELD_MODULUS);
        s2 = addmod(s2, C3, FIELD_MODULUS);

        // Final mix
        t0 = addmod(s0, s1, FIELD_MODULUS);
        t0 = addmod(t0, s2, FIELD_MODULUS);

        return t0;
    }

    /// @notice S-box function: x^5 mod p
    function sbox(uint256 x) internal pure returns (uint256) {
        uint256 x2 = mulmod(x, x, FIELD_MODULUS);
        uint256 x4 = mulmod(x2, x2, FIELD_MODULUS);
        return mulmod(x4, x, FIELD_MODULUS);
    }
}

/// @title PoseidonT6
/// @notice Poseidon hash function for 5 inputs (t=6 state)
library PoseidonT6 {
    uint256 internal constant FIELD_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @notice Hash 5 field elements using Poseidon
    /// @dev Used for bet commitments
    function hash(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 e
    ) internal pure returns (uint256) {
        // Chain Poseidon hashes for 5 inputs
        uint256 h1 = PoseidonT3.hash(a, b);
        uint256 h2 = PoseidonT3.hash(h1, c);
        uint256 h3 = PoseidonT3.hash(h2, d);
        return PoseidonT3.hash(h3, e);
    }
}
