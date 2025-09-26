// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VRFConsumerBaseV2Plus} from
    "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title FortunaLottery
 * @author Anik Tahabilder
 * @notice A decentralized Chinese Lottery (probabilistic auction) contract
 * @dev Implements a lottery system where winners are chosen randomly with probability
 *      proportional to tokens placed using Chainlink VRF v2.5
 */
contract FortunaLottery is ReentrancyGuard, VRFConsumerBaseV2Plus {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Lottery__NotActive();
    error Lottery__AlreadyEnded();
    error Lottery__InvalidTokenAmount();
    error Lottery__InsufficientTokens();
    error Lottery__InvalidItemId();
    error Lottery__AlreadyParticipated();
    error Lottery__NotEnoughParticipants();
    error Lottery__WinnerAlreadySelected();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LotteryCreated(
        uint256 indexed lotteryId,
        uint256 itemCount,
        uint256 tokensPerParticipant,
        uint256 startTime,
        uint256 endTime
    );

    event ParticipantRegistered(
        uint256 indexed lotteryId,
        address indexed participant,
        uint256 tokensReceived
    );

    event TokensPlaced(
        uint256 indexed lotteryId,
        address indexed participant,
        uint256 indexed itemId,
        uint256 tokens
    );

    event WinnerSelected(
        uint256 indexed lotteryId,
        uint256 indexed itemId,
        address indexed winner,
        uint256 requestId
    );

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Represents a single lottery item
    struct LotteryItem {
        string name;
        string description;
        uint256 totalTokens;
        address winner;
        bool winnerSelected;
    }

    /// @notice Represents a participant's token distribution
    struct ParticipantInfo {
        uint256 totalTokens;
        uint256 tokensUsed;
        mapping(uint256 => uint256) tokensPerItem;
        bool registered;
    }

    /// @notice Represents a complete lottery
    struct Lottery {
        uint256 id;
        string name;
        uint256 tokensPerParticipant;
        uint256 startTime;
        uint256 endTime;
        uint256 itemCount;
        bool isActive;
        mapping(uint256 => LotteryItem) items;
        mapping(address => ParticipantInfo) participants;
        address[] participantList;
    }

    /// @notice Represents a VRF request for winner selection
    struct VRFRequest {
        uint256 lotteryId;
        uint256 itemId;
        bool fulfilled;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Chainlink VRF Configuration
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private constant CALLBACK_GAS_LIMIT = 200000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /// @notice Mapping from VRF request ID to VRF request details
    mapping(uint256 => VRFRequest) private vrfRequests;

    /// @notice Counter for lottery IDs
    uint256 private lotteryCounter;

    /// @notice Mapping from lottery ID to Lottery
    mapping(uint256 => Lottery) private lotteries;

    /// @notice Current active lottery ID
    uint256 public currentLotteryId;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the Fortuna Lottery contract
     * @param vrfCoordinator Address of the Chainlink VRF Coordinator
     * @param subscriptionId Chainlink VRF subscription ID
     * @param keyHash Chainlink VRF key hash for gas lane
     */
    constructor(address vrfCoordinator, uint256 subscriptionId, bytes32 keyHash)
        VRFConsumerBaseV2Plus(vrfCoordinator)
    {
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        lotteryCounter = 0;
        currentLotteryId = 0;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get lottery basic information
     * @param lotteryId The ID of the lottery
     * @return name The lottery name
     * @return tokensPerParticipant Tokens each participant receives
     * @return startTime When the lottery starts
     * @return endTime When the lottery ends
     * @return itemCount Number of items in the lottery
     * @return isActive Whether the lottery is currently active
     */
    function getLotteryInfo(uint256 lotteryId)
        external
        view
        returns (
            string memory name,
            uint256 tokensPerParticipant,
            uint256 startTime,
            uint256 endTime,
            uint256 itemCount,
            bool isActive
        )
    {
        Lottery storage lottery = lotteries[lotteryId];
        return (
            lottery.name,
            lottery.tokensPerParticipant,
            lottery.startTime,
            lottery.endTime,
            lottery.itemCount,
            lottery.isActive
        );
    }

    /**
     * @notice Get item information
     * @param lotteryId The ID of the lottery
     * @param itemId The ID of the item
     * @return name The item name
     * @return description The item description
     * @return totalTokens Total tokens placed on this item
     * @return winner The winner address (zero address if not selected)
     * @return winnerSelected Whether winner has been selected
     */
    function getItemInfo(uint256 lotteryId, uint256 itemId)
        external
        view
        returns (
            string memory name,
            string memory description,
            uint256 totalTokens,
            address winner,
            bool winnerSelected
        )
    {
        LotteryItem storage item = lotteries[lotteryId].items[itemId];
        return (item.name, item.description, item.totalTokens, item.winner, item.winnerSelected);
    }

    /**
     * @notice Get participant information
     * @param lotteryId The ID of the lottery
     * @param participant The participant address
     * @return totalTokens Total tokens received
     * @return tokensUsed Tokens already distributed
     * @return registered Whether participant is registered
     */
    function getParticipantInfo(uint256 lotteryId, address participant)
        external
        view
        returns (uint256 totalTokens, uint256 tokensUsed, bool registered)
    {
        ParticipantInfo storage info = lotteries[lotteryId].participants[participant];
        return (info.totalTokens, info.tokensUsed, info.registered);
    }

    /**
     * @notice Get tokens placed by participant on specific item
     * @param lotteryId The ID of the lottery
     * @param participant The participant address
     * @param itemId The item ID
     * @return tokens Number of tokens placed
     */
    function getParticipantTokensOnItem(
        uint256 lotteryId,
        address participant,
        uint256 itemId
    ) external view returns (uint256 tokens) {
        return lotteries[lotteryId].participants[participant].tokensPerItem[itemId];
    }

    /**
     * @notice Get number of participants in a lottery
     * @param lotteryId The ID of the lottery
     * @return count Number of participants
     */
    function getParticipantCount(uint256 lotteryId) external view returns (uint256 count) {
        return lotteries[lotteryId].participantList.length;
    }

    /**
     * @notice Check if lottery is currently active
     * @param lotteryId The ID of the lottery
     * @return active Whether the lottery is active
     */
    function isLotteryActive(uint256 lotteryId) public view returns (bool active) {
        Lottery storage lottery = lotteries[lotteryId];
        return lottery.isActive
            && block.timestamp >= lottery.startTime
            && block.timestamp <= lottery.endTime;
    }

    /*//////////////////////////////////////////////////////////////
                        LOTTERY CREATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create a new lottery
     * @param name Name of the lottery
     * @param tokensPerParticipant Number of tokens each participant receives
     * @param startTime Unix timestamp when lottery starts
     * @param endTime Unix timestamp when lottery ends
     * @param itemNames Array of item names
     * @param itemDescriptions Array of item descriptions
     * @return lotteryId The ID of the newly created lottery
     * @dev Only owner can create lotteries
     */
    function createLottery(
        string memory name,
        uint256 tokensPerParticipant,
        uint256 startTime,
        uint256 endTime,
        string[] memory itemNames,
        string[] memory itemDescriptions
    ) external onlyOwner returns (uint256 lotteryId) {
        require(startTime < endTime, "Invalid time range");
        require(itemNames.length > 0, "Must have at least one item");
        require(itemNames.length == itemDescriptions.length, "Array length mismatch");
        require(tokensPerParticipant > 0, "Invalid token amount");

        lotteryId = lotteryCounter++;
        Lottery storage lottery = lotteries[lotteryId];

        lottery.id = lotteryId;
        lottery.name = name;
        lottery.tokensPerParticipant = tokensPerParticipant;
        lottery.startTime = startTime;
        lottery.endTime = endTime;
        lottery.itemCount = itemNames.length;
        lottery.isActive = true;

        // Add items to the lottery
        for (uint256 i = 0; i < itemNames.length; i++) {
            lottery.items[i] = LotteryItem({
                name: itemNames[i],
                description: itemDescriptions[i],
                totalTokens: 0,
                winner: address(0),
                winnerSelected: false
            });
        }

        currentLotteryId = lotteryId;

        emit LotteryCreated(
            lotteryId, itemNames.length, tokensPerParticipant, startTime, endTime
        );

        return lotteryId;
    }

    /**
     * @notice End a lottery early
     * @param lotteryId The ID of the lottery to end
     * @dev Only owner can end lotteries
     */
    function endLottery(uint256 lotteryId) external onlyOwner {
        Lottery storage lottery = lotteries[lotteryId];
        require(lottery.isActive, "Lottery not active");
        lottery.isActive = false;
    }

    /*//////////////////////////////////////////////////////////////
                    PARTICIPANT & TOKEN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register as a participant in the lottery
     * @param lotteryId The ID of the lottery to join
     * @dev Participants receive tokens upon registration
     */
    function registerParticipant(uint256 lotteryId) external nonReentrant {
        if (!isLotteryActive(lotteryId)) {
            revert Lottery__NotActive();
        }

        Lottery storage lottery = lotteries[lotteryId];
        ParticipantInfo storage participant = lottery.participants[msg.sender];

        if (participant.registered) {
            revert Lottery__AlreadyParticipated();
        }

        participant.registered = true;
        participant.totalTokens = lottery.tokensPerParticipant;
        participant.tokensUsed = 0;

        lottery.participantList.push(msg.sender);

        emit ParticipantRegistered(lotteryId, msg.sender, lottery.tokensPerParticipant);
    }

    /**
     * @notice Place tokens on a specific item
     * @param lotteryId The ID of the lottery
     * @param itemId The ID of the item
     * @param tokenAmount Number of tokens to place
     * @dev Tokens can be placed multiple times on same item
     */
    function placeTokens(uint256 lotteryId, uint256 itemId, uint256 tokenAmount)
        external
        nonReentrant
    {
        if (!isLotteryActive(lotteryId)) {
            revert Lottery__NotActive();
        }

        Lottery storage lottery = lotteries[lotteryId];
        ParticipantInfo storage participant = lottery.participants[msg.sender];

        if (!participant.registered) {
            revert Lottery__AlreadyParticipated();
        }

        if (itemId >= lottery.itemCount) {
            revert Lottery__InvalidItemId();
        }

        if (tokenAmount == 0) {
            revert Lottery__InvalidTokenAmount();
        }

        uint256 remainingTokens = participant.totalTokens - participant.tokensUsed;
        if (tokenAmount > remainingTokens) {
            revert Lottery__InsufficientTokens();
        }

        participant.tokensUsed += tokenAmount;
        participant.tokensPerItem[itemId] += tokenAmount;
        lottery.items[itemId].totalTokens += tokenAmount;

        emit TokensPlaced(lotteryId, msg.sender, itemId, tokenAmount);
    }

    /**
     * @notice Place tokens on multiple items at once
     * @param lotteryId The ID of the lottery
     * @param itemIds Array of item IDs
     * @param tokenAmounts Array of token amounts for each item
     * @dev Arrays must be same length
     */
    function placeTokensBatch(
        uint256 lotteryId,
        uint256[] calldata itemIds,
        uint256[] calldata tokenAmounts
    ) external nonReentrant {
        if (!isLotteryActive(lotteryId)) {
            revert Lottery__NotActive();
        }

        require(itemIds.length == tokenAmounts.length, "Array length mismatch");

        Lottery storage lottery = lotteries[lotteryId];
        ParticipantInfo storage participant = lottery.participants[msg.sender];

        if (!participant.registered) {
            revert Lottery__AlreadyParticipated();
        }

        uint256 totalTokensToPlace = 0;
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            totalTokensToPlace += tokenAmounts[i];
        }

        uint256 remainingTokens = participant.totalTokens - participant.tokensUsed;
        if (totalTokensToPlace > remainingTokens) {
            revert Lottery__InsufficientTokens();
        }

        for (uint256 i = 0; i < itemIds.length; i++) {
            uint256 itemId = itemIds[i];
            uint256 tokenAmount = tokenAmounts[i];

            if (itemId >= lottery.itemCount) {
                revert Lottery__InvalidItemId();
            }

            if (tokenAmount > 0) {
                participant.tokensPerItem[itemId] += tokenAmount;
                lottery.items[itemId].totalTokens += tokenAmount;

                emit TokensPlaced(lotteryId, msg.sender, itemId, tokenAmount);
            }
        }

        participant.tokensUsed += totalTokensToPlace;
    }

    /*//////////////////////////////////////////////////////////////
                        CHAINLINK VRF FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Request random winner selection for an item
     * @param lotteryId The ID of the lottery
     * @param itemId The ID of the item
     * @return requestId The Chainlink VRF request ID
     * @dev Only owner can request winner selection after lottery ends
     */
    function requestWinner(uint256 lotteryId, uint256 itemId)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        Lottery storage lottery = lotteries[lotteryId];
        LotteryItem storage item = lottery.items[itemId];

        require(block.timestamp > lottery.endTime, "Lottery still active");
        require(itemId < lottery.itemCount, "Invalid item ID");
        require(!item.winnerSelected, "Winner already selected");
        require(item.totalTokens > 0, "No tokens placed on item");

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        vrfRequests[requestId] =
            VRFRequest({lotteryId: lotteryId, itemId: itemId, fulfilled: false});

        return requestId;
    }

    /**
     * @notice Callback function called by Chainlink VRF with random number
     * @param requestId The ID of the VRF request
     * @param randomWords Array of random numbers from Chainlink VRF
     * @dev This function is called automatically by Chainlink VRF
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
        internal
        override
    {
        VRFRequest storage request = vrfRequests[requestId];
        require(!request.fulfilled, "Request already fulfilled");

        Lottery storage lottery = lotteries[request.lotteryId];
        LotteryItem storage item = lottery.items[request.itemId];

        // Select winner based on weighted probability
        address winner = _selectWeightedWinner(
            lottery, request.itemId, randomWords[0]
        );

        item.winner = winner;
        item.winnerSelected = true;
        request.fulfilled = true;

        emit WinnerSelected(request.lotteryId, request.itemId, winner, requestId);
    }

    /**
     * @notice Select a winner based on weighted probability
     * @param lottery The lottery storage reference
     * @param itemId The item ID
     * @param randomNumber Random number from Chainlink VRF
     * @return winner Address of the selected winner
     * @dev Uses weighted random selection based on tokens placed
     */
    function _selectWeightedWinner(
        Lottery storage lottery,
        uint256 itemId,
        uint256 randomNumber
    ) private view returns (address winner) {
        LotteryItem storage item = lottery.items[itemId];
        uint256 totalTokens = item.totalTokens;

        // Get random position in token range
        uint256 winningPosition = randomNumber % totalTokens;

        // Find the participant who owns the token at winning position
        uint256 cumulativeTokens = 0;
        for (uint256 i = 0; i < lottery.participantList.length; i++) {
            address participant = lottery.participantList[i];
            uint256 participantTokens =
                lottery.participants[participant].tokensPerItem[itemId];

            if (participantTokens > 0) {
                cumulativeTokens += participantTokens;
                if (winningPosition < cumulativeTokens) {
                    return participant;
                }
            }
        }

        // Should never reach here if logic is correct
        revert("Winner selection failed");
    }
}
