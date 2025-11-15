// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PoseidonT3} from "./PoseidonT3.sol";

/// @title IncrementalMerkleTree
/// @notice Gas-efficient append-only Merkle tree using Poseidon hash
/// @dev Supports up to 2^TREE_DEPTH leaves (about 1M with depth 20)
abstract contract IncrementalMerkleTree {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Depth of the Merkle tree
    uint256 public constant TREE_DEPTH = 20;

    /// @notice Maximum number of leaves (2^20 = 1,048,576)
    uint256 public constant MAX_LEAVES = 1 << TREE_DEPTH;

    /// @notice Zero value used for empty leaves
    uint256 public constant ZERO_VALUE = uint256(keccak256("fortuna_lottery_zero")) % PoseidonT3.FIELD_MODULUS;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Current number of leaves in the tree
    uint256 public nextLeafIndex;

    /// @notice Current root of the Merkle tree
    uint256 public currentRoot;

    /// @notice Filled subtrees at each level (for efficient insertion)
    uint256[TREE_DEPTH] public filledSubtrees;

    /// @notice Pre-computed zero hashes at each level
    uint256[TREE_DEPTH] public zeros;

    /// @notice History of valid roots (for delayed proof verification)
    mapping(uint256 => bool) public isKnownRoot;

    /// @notice Array of historical roots
    uint256[] public rootHistory;

    /// @notice Maximum number of roots to keep in history
    uint256 public constant ROOT_HISTORY_SIZE = 100;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LeafInserted(uint256 indexed leafIndex, uint256 leaf, uint256 newRoot);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error MerkleTree__TreeIsFull();
    error MerkleTree__InvalidRoot();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        // Pre-compute zero hashes
        zeros[0] = ZERO_VALUE;
        for (uint256 i = 1; i < TREE_DEPTH; i++) {
            zeros[i] = PoseidonT3.hash(zeros[i - 1], zeros[i - 1]);
        }

        // Initialize filled subtrees with zeros
        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            filledSubtrees[i] = zeros[i];
        }

        // Initial root is hash of all zeros
        currentRoot = zeros[TREE_DEPTH - 1];
        isKnownRoot[currentRoot] = true;
        rootHistory.push(currentRoot);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Insert a new leaf into the tree
    /// @param leaf The leaf value to insert
    /// @return newRoot The new Merkle root after insertion
    function _insert(uint256 leaf) internal returns (uint256 newRoot) {
        if (nextLeafIndex >= MAX_LEAVES) {
            revert MerkleTree__TreeIsFull();
        }

        uint256 currentIndex = nextLeafIndex;
        uint256 currentHash = leaf;

        // Traverse up the tree
        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            if (currentIndex % 2 == 0) {
                // Current node is a left child
                // Store it and hash with zero sibling
                filledSubtrees[i] = currentHash;
                currentHash = PoseidonT3.hash(currentHash, zeros[i]);
            } else {
                // Current node is a right child
                // Hash with the stored left sibling
                currentHash = PoseidonT3.hash(filledSubtrees[i], currentHash);
            }
            currentIndex /= 2;
        }

        // Update root
        currentRoot = currentHash;
        newRoot = currentHash;

        // Add to root history
        isKnownRoot[newRoot] = true;
        rootHistory.push(newRoot);

        // Prune old roots if necessary
        if (rootHistory.length > ROOT_HISTORY_SIZE) {
            // Mark old root as invalid (optional - can keep all roots valid)
            // isKnownRoot[rootHistory[rootHistory.length - ROOT_HISTORY_SIZE - 1]] = false;
        }

        emit LeafInserted(nextLeafIndex, leaf, newRoot);

        nextLeafIndex++;

        return newRoot;
    }

    /// @notice Check if a root is valid
    /// @param root The root to check
    /// @return True if the root is valid
    function _isValidRoot(uint256 root) internal view returns (bool) {
        return isKnownRoot[root];
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the current root
    function getRoot() external view returns (uint256) {
        return currentRoot;
    }

    /// @notice Get the number of leaves
    function getLeafCount() external view returns (uint256) {
        return nextLeafIndex;
    }

    /// @notice Get zero hash at a level
    function getZeroHash(uint256 level) external view returns (uint256) {
        require(level < TREE_DEPTH, "Level out of bounds");
        return zeros[level];
    }

    /// @notice Get filled subtree at a level
    function getFilledSubtree(uint256 level) external view returns (uint256) {
        require(level < TREE_DEPTH, "Level out of bounds");
        return filledSubtrees[level];
    }
}
