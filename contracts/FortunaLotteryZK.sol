// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IncrementalMerkleTree} from "./lib/IncrementalMerkleTree.sol";
import {PoseidonT3, PoseidonT6} from "./lib/PoseidonT3.sol";
import {IBetVerifier} from "./verifiers/IBetVerifier.sol";
import {IWinnerVerifier} from "./verifiers/IWinnerVerifier.sol";

/// @title FortunaLotteryZK
/// @notice Privacy-preserving lottery using zero-knowledge proofs
/// @dev Integrates with Chainlink VRF for randomness and ZK proofs for privacy
contract FortunaLotteryZK is ReentrancyGuard, Ownable, IncrementalMerkleTree {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZK__InvalidProof();
    error ZK__NullifierAlreadyUsed();
    error ZK__LotteryNotActive();
    error ZK__LotteryStillActive();
    error ZK__LotteryNotExists();
    error ZK__WinnerNotSelected();
    error ZK__InvalidMerkleRoot();
    error ZK__ClaimAlreadyProcessed();
    error ZK__InsufficientTokens();
    error ZK__InvalidItemId();
    error ZK__AlreadyRegistered();
    error ZK__NotRegistered();
    error ZK__NoTokensOnItem();
    error ZK__InvalidTimeRange();
    error ZK__InvalidItemCount();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new ZK lottery is created
    event LotteryCreatedZK(
        uint256 indexed lotteryId,
        string name,
        uint256 itemCount,
        uint256 tokensPerParticipant,
        uint256 startTime,
        uint256 endTime
    );

    /// @notice Emitted when a participant registers (address is public, bets are private)
    event ParticipantRegisteredZK(
        uint256 indexed lotteryId,
        address indexed participant,
        uint256 tokensReceived
    );

    /// @notice Emitted when a commitment is added (no identity info!)
    event CommitmentAdded(
        uint256 indexed lotteryId,
        uint256 indexed itemId,
        uint256 commitment,
        uint256 nullifierHash,
        uint256 tokenAmount,
        uint256 newMerkleRoot,
        uint256 ticketRangeStart,
        uint256 ticketRangeEnd
    );

    /// @notice Emitted when randomness is requested
    event RandomnessRequested(
        uint256 indexed lotteryId,
        uint256 indexed itemId,
        uint256 requestId
    );

    /// @notice Emitted when winning position is determined
    event WinningPositionSet(
        uint256 indexed lotteryId,
        uint256 indexed itemId,
        uint256 winningPosition,
        uint256 totalTokens
    );

    /// @notice Emitted when prize is claimed anonymously
    event PrizeClaimed(
        uint256 indexed lotteryId,
        uint256 indexed itemId,
        uint256 claimNullifierHash,
        address recipientAddress
    );

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Item in a lottery
    struct ItemZK {
        string name;
        string description;
        uint256 totalTokens;
        uint256 winningPosition;
        bool winnerSelected;
        bool prizeClaimed;
    }

    /// @notice Lottery data
    struct LotteryZK {
        uint256 id;
        string name;
        uint256 tokensPerParticipant;
        uint256 startTime;
        uint256 endTime;
        uint256 itemCount;
        bool isActive;
        uint256 commitmentCount;
    }

    /// @notice Participant token allocation
    struct Allocation {
        uint256 totalTokens;
        uint256 tokensUsed;
        bool registered;
    }

    /// @notice VRF request data
    struct VRFRequest {
        uint256 lotteryId;
        uint256 itemId;
        bool fulfilled;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice ZK verifier contracts
    IBetVerifier public immutable betVerifier;
    IWinnerVerifier public immutable winnerVerifier;

    /// @notice Lottery counter
    uint256 public lotteryCounter;

    /// @notice Lottery data
    mapping(uint256 => LotteryZK) public lotteries;

    /// @notice Items per lottery
    mapping(uint256 => mapping(uint256 => ItemZK)) public items;

    /// @notice Participant allocations per lottery
    mapping(uint256 => mapping(address => Allocation)) public allocations;

    /// @notice Bet nullifier tracking (prevents double-betting with same nullifier)
    mapping(uint256 => mapping(uint256 => bool)) public betNullifierUsed;

    /// @notice Claim nullifier tracking (prevents double-claiming)
    mapping(uint256 => mapping(uint256 => bool)) public claimNullifierUsed;

    /// @notice Valid roots per lottery (for delayed proof verification)
    mapping(uint256 => mapping(uint256 => bool)) public isValidLotteryRoot;

    /// @notice VRF requests
    mapping(uint256 => VRFRequest) public vrfRequests;
    uint256 public vrfRequestCounter;

    /// @notice Mock VRF coordinator for local testing
    address public vrfCoordinator;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _betVerifier,
        address _winnerVerifier,
        address _vrfCoordinator
    ) Ownable(msg.sender) {
        betVerifier = IBetVerifier(_betVerifier);
        winnerVerifier = IWinnerVerifier(_winnerVerifier);
        vrfCoordinator = _vrfCoordinator;
    }

    /*//////////////////////////////////////////////////////////////
                        LOTTERY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Create a new ZK lottery
    function createLottery(
        string calldata name,
        string[] calldata itemNames,
        string[] calldata itemDescriptions,
        uint256 tokensPerParticipant,
        uint256 startTime,
        uint256 endTime
    ) external onlyOwner returns (uint256 lotteryId) {
        if (startTime >= endTime) revert ZK__InvalidTimeRange();
        if (itemNames.length == 0 || itemNames.length != itemDescriptions.length) {
            revert ZK__InvalidItemCount();
        }

        lotteryId = ++lotteryCounter;

        lotteries[lotteryId] = LotteryZK({
            id: lotteryId,
            name: name,
            tokensPerParticipant: tokensPerParticipant,
            startTime: startTime,
            endTime: endTime,
            itemCount: itemNames.length,
            isActive: true,
            commitmentCount: 0
        });

        // Create items
        for (uint256 i = 0; i < itemNames.length; i++) {
            items[lotteryId][i] = ItemZK({
                name: itemNames[i],
                description: itemDescriptions[i],
                totalTokens: 0,
                winningPosition: 0,
                winnerSelected: false,
                prizeClaimed: false
            });
        }

        // Initialize merkle root for this lottery
        isValidLotteryRoot[lotteryId][currentRoot] = true;

        emit LotteryCreatedZK(
            lotteryId,
            name,
            itemNames.length,
            tokensPerParticipant,
            startTime,
            endTime
        );

        return lotteryId;
    }

    /*//////////////////////////////////////////////////////////////
                        PARTICIPANT REGISTRATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Register for a lottery and receive tokens
    /// @dev Address is visible but betting behavior will be hidden
    function register(uint256 lotteryId) external nonReentrant {
        LotteryZK storage lottery = lotteries[lotteryId];

        if (lottery.id == 0) revert ZK__LotteryNotExists();
        if (!lottery.isActive) revert ZK__LotteryNotActive();
        if (block.timestamp < lottery.startTime || block.timestamp > lottery.endTime) {
            revert ZK__LotteryNotActive();
        }

        Allocation storage alloc = allocations[lotteryId][msg.sender];
        if (alloc.registered) revert ZK__AlreadyRegistered();

        alloc.registered = true;
        alloc.totalTokens = lottery.tokensPerParticipant;
        alloc.tokensUsed = 0;

        emit ParticipantRegisteredZK(lotteryId, msg.sender, lottery.tokensPerParticipant);
    }

    /*//////////////////////////////////////////////////////////////
                          PRIVATE BETTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Place a bet using a ZK proof
    /// @param lotteryId The lottery ID
    /// @param proof Groth16 proof (8 elements)
    /// @param commitment The bet commitment
    /// @param nullifierHash Hash for double-spend prevention
    /// @param itemId Which item to bet on
    /// @param tokenAmount How many tokens to bet
    function placeBetZK(
        uint256 lotteryId,
        uint256[8] calldata proof,
        uint256 commitment,
        uint256 nullifierHash,
        uint256 itemId,
        uint256 tokenAmount
    ) external nonReentrant {
        LotteryZK storage lottery = lotteries[lotteryId];
        ItemZK storage item = items[lotteryId][itemId];
        Allocation storage alloc = allocations[lotteryId][msg.sender];

        // Validations
        if (lottery.id == 0) revert ZK__LotteryNotExists();
        if (!lottery.isActive) revert ZK__LotteryNotActive();
        if (block.timestamp < lottery.startTime || block.timestamp > lottery.endTime) {
            revert ZK__LotteryNotActive();
        }
        if (!alloc.registered) revert ZK__NotRegistered();
        if (itemId >= lottery.itemCount) revert ZK__InvalidItemId();
        if (betNullifierUsed[lotteryId][nullifierHash]) revert ZK__NullifierAlreadyUsed();
        if (alloc.tokensUsed + tokenAmount > alloc.totalTokens) {
            revert ZK__InsufficientTokens();
        }

        // Verify ZK proof
        if (!betVerifier.verifyProof(proof, lotteryId, commitment, nullifierHash)) {
            revert ZK__InvalidProof();
        }

        // Calculate ticket range for this bet
        uint256 ticketRangeStart = item.totalTokens;
        uint256 ticketRangeEnd = ticketRangeStart + tokenAmount;

        // Update state
        betNullifierUsed[lotteryId][nullifierHash] = true;
        alloc.tokensUsed += tokenAmount;
        item.totalTokens += tokenAmount;

        // Insert commitment into Merkle tree
        uint256 newRoot = _insert(commitment);
        isValidLotteryRoot[lotteryId][newRoot] = true;
        lottery.commitmentCount++;

        emit CommitmentAdded(
            lotteryId,
            itemId,
            commitment,
            nullifierHash,
            tokenAmount,
            newRoot,
            ticketRangeStart,
            ticketRangeEnd
        );
    }

    /*//////////////////////////////////////////////////////////////
                         WINNER SELECTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Request random winner selection for an item
    /// @dev In production, this calls Chainlink VRF
    function requestWinner(uint256 lotteryId, uint256 itemId)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        LotteryZK storage lottery = lotteries[lotteryId];
        ItemZK storage item = items[lotteryId][itemId];

        if (lottery.id == 0) revert ZK__LotteryNotExists();
        if (block.timestamp <= lottery.endTime) revert ZK__LotteryStillActive();
        if (item.winnerSelected) revert ZK__ClaimAlreadyProcessed();
        if (item.totalTokens == 0) revert ZK__NoTokensOnItem();

        requestId = ++vrfRequestCounter;

        vrfRequests[requestId] = VRFRequest({
            lotteryId: lotteryId,
            itemId: itemId,
            fulfilled: false
        });

        emit RandomnessRequested(lotteryId, itemId, requestId);

        return requestId;
    }

    /// @notice Fulfill random words (called by VRF coordinator or manually for testing)
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
        // In production, verify caller is VRF coordinator
        // For testing, anyone can call this

        VRFRequest storage request = vrfRequests[requestId];
        require(!request.fulfilled, "Already fulfilled");
        require(request.lotteryId != 0, "Request not found");

        ItemZK storage item = items[request.lotteryId][request.itemId];

        uint256 winningPos = randomWords[0] % item.totalTokens;

        item.winningPosition = winningPos;
        item.winnerSelected = true;
        request.fulfilled = true;

        // Deactivate lottery after winner selection
        lotteries[request.lotteryId].isActive = false;

        emit WinningPositionSet(
            request.lotteryId,
            request.itemId,
            winningPos,
            item.totalTokens
        );
    }

    /// @notice Manually set winning position for testing
    function setWinningPositionForTesting(
        uint256 lotteryId,
        uint256 itemId,
        uint256 winningPosition
    ) external onlyOwner {
        ItemZK storage item = items[lotteryId][itemId];
        require(!item.winnerSelected, "Already selected");
        require(winningPosition < item.totalTokens, "Invalid position");

        item.winningPosition = winningPosition;
        item.winnerSelected = true;

        emit WinningPositionSet(lotteryId, itemId, winningPosition, item.totalTokens);
    }

    /*//////////////////////////////////////////////////////////////
                       ANONYMOUS PRIZE CLAIM
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim prize using ZK proof of winning
    /// @param lotteryId The lottery ID
    /// @param itemId The item ID
    /// @param proof Groth16 proof of winning
    /// @param claimNullifierHash Nullifier to prevent double claims
    /// @param recipientAddress Where to send the prize
    function claimPrize(
        uint256 lotteryId,
        uint256 itemId,
        uint256[8] calldata proof,
        uint256 claimNullifierHash,
        address recipientAddress
    ) external nonReentrant {
        ItemZK storage item = items[lotteryId][itemId];

        if (!item.winnerSelected) revert ZK__WinnerNotSelected();
        if (item.prizeClaimed) revert ZK__ClaimAlreadyProcessed();
        if (claimNullifierUsed[lotteryId][claimNullifierHash]) {
            revert ZK__ClaimAlreadyProcessed();
        }

        // Verify ZK proof
        if (!winnerVerifier.verifyProof(
            proof,
            lotteryId,
            itemId,
            currentRoot,
            item.winningPosition,
            claimNullifierHash,
            uint256(uint160(recipientAddress))
        )) {
            revert ZK__InvalidProof();
        }

        // Mark as claimed
        claimNullifierUsed[lotteryId][claimNullifierHash] = true;
        item.prizeClaimed = true;

        // In a real implementation, transfer prize to recipientAddress here
        // For this demo, we just emit the event

        emit PrizeClaimed(lotteryId, itemId, claimNullifierHash, recipientAddress);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get lottery info
    function getLotteryInfo(uint256 lotteryId)
        external
        view
        returns (
            string memory name,
            uint256 tokensPerParticipant,
            uint256 startTime,
            uint256 endTime,
            uint256 itemCount,
            bool isActive,
            uint256 commitmentCount
        )
    {
        LotteryZK storage lottery = lotteries[lotteryId];
        return (
            lottery.name,
            lottery.tokensPerParticipant,
            lottery.startTime,
            lottery.endTime,
            lottery.itemCount,
            lottery.isActive,
            lottery.commitmentCount
        );
    }

    /// @notice Get item info
    function getItemInfo(uint256 lotteryId, uint256 itemId)
        external
        view
        returns (
            string memory name,
            string memory description,
            uint256 totalTokens,
            uint256 winningPosition,
            bool winnerSelected,
            bool prizeClaimed
        )
    {
        ItemZK storage item = items[lotteryId][itemId];
        return (
            item.name,
            item.description,
            item.totalTokens,
            item.winningPosition,
            item.winnerSelected,
            item.prizeClaimed
        );
    }

    /// @notice Get participant allocation
    function getAllocation(uint256 lotteryId, address participant)
        external
        view
        returns (uint256 totalTokens, uint256 tokensUsed, bool registered)
    {
        Allocation storage alloc = allocations[lotteryId][participant];
        return (alloc.totalTokens, alloc.tokensUsed, alloc.registered);
    }

    /// @notice Check if lottery is currently active
    function isLotteryActive(uint256 lotteryId) external view returns (bool) {
        LotteryZK storage lottery = lotteries[lotteryId];
        return lottery.isActive &&
               block.timestamp >= lottery.startTime &&
               block.timestamp <= lottery.endTime;
    }
}
