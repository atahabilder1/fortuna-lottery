// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title IBetVerifier
/// @notice Interface for the Groth16 bet commitment verifier
interface IBetVerifier {
    /// @notice Verify a bet commitment proof
    /// @param proof The Groth16 proof (8 elements: a[2], b[2][2], c[2])
    /// @param lotteryId The lottery ID (public input)
    /// @param commitment The computed commitment (public output)
    /// @param nullifierHash The nullifier hash (public output)
    /// @return True if the proof is valid
    function verifyProof(
        uint256[8] calldata proof,
        uint256 lotteryId,
        uint256 commitment,
        uint256 nullifierHash
    ) external view returns (bool);
}
