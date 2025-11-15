// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title IWinnerVerifier
/// @notice Interface for the Groth16 winner proof verifier
interface IWinnerVerifier {
    /// @notice Verify a winner claim proof
    /// @param proof The Groth16 proof (8 elements)
    /// @param lotteryId The lottery ID
    /// @param winningItemId The item that won
    /// @param merkleRoot The commitment tree root
    /// @param winningPosition The VRF random position
    /// @param claimNullifierHash The claim nullifier hash
    /// @param recipientAddress The prize recipient address
    /// @return True if the proof is valid
    function verifyProof(
        uint256[8] calldata proof,
        uint256 lotteryId,
        uint256 winningItemId,
        uint256 merkleRoot,
        uint256 winningPosition,
        uint256 claimNullifierHash,
        uint256 recipientAddress
    ) external view returns (bool);
}
