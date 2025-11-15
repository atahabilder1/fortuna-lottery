// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IBetVerifier} from "../verifiers/IBetVerifier.sol";

/// @title MockBetVerifier
/// @notice Mock verifier for local testing - always returns true
/// @dev DO NOT USE IN PRODUCTION - this is for testing only
contract MockBetVerifier is IBetVerifier {
    /// @notice Always returns true for testing
    function verifyProof(
        uint256[8] calldata,
        uint256,
        uint256,
        uint256
    ) external pure override returns (bool) {
        return true;
    }
}
