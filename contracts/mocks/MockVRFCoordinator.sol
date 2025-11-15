// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title MockVRFCoordinator
/// @notice Mock VRF Coordinator for local testing
/// @dev Allows instant random number fulfillment for testing
contract MockVRFCoordinator {
    uint256 private requestCounter;
    mapping(uint256 => address) private requestToConsumer;
    mapping(uint256 => uint256) private requestToSubId;

    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint256 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        bytes extraArgs,
        address indexed sender
    );

    event RandomWordsFulfilled(
        uint256 indexed requestId,
        uint256 outputSeed,
        uint256 indexed subId,
        uint96 payment,
        bool nativePayment,
        bool success,
        bool onlyPremium
    );

    /// @notice Request random words (mock implementation)
    function requestRandomWords(
        bytes32 keyHash,
        uint256 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        bytes calldata extraArgs
    ) external returns (uint256 requestId) {
        requestId = ++requestCounter;
        requestToConsumer[requestId] = msg.sender;
        requestToSubId[requestId] = subId;

        emit RandomWordsRequested(
            keyHash,
            requestId,
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, requestId))),
            subId,
            requestConfirmations,
            callbackGasLimit,
            numWords,
            extraArgs,
            msg.sender
        );

        return requestId;
    }

    /// @notice Fulfill random words manually (for testing)
    /// @param requestId The request to fulfill
    /// @param randomWords The random values to return
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
        address consumer = requestToConsumer[requestId];
        require(consumer != address(0), "Request not found");

        // Call the consumer's fulfillRandomWords function
        (bool success, ) = consumer.call(
            abi.encodeWithSignature("rawFulfillRandomWords(uint256,uint256[])", requestId, randomWords)
        );

        emit RandomWordsFulfilled(
            requestId,
            randomWords[0],
            requestToSubId[requestId],
            0,
            false,
            success,
            false
        );
    }

    /// @notice Fulfill with a pseudo-random value based on block data
    function fulfillRandomWordsWithBlockHash(uint256 requestId) external {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            requestId,
            block.timestamp
        )));

        this.fulfillRandomWords(requestId, randomWords);
    }
}
