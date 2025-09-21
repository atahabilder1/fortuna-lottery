// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title FortunaLottery
 * @author Anik Tahabilder
 * @notice A decentralized Chinese Lottery (probabilistic auction) contract
 * @dev Implements a lottery system where winners are chosen randomly with probability
 *      proportional to tokens placed
 */
contract FortunaLottery is Ownable, ReentrancyGuard {
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

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Counter for lottery IDs
    uint256 private lotteryCounter;

    /// @notice Mapping from lottery ID to Lottery
    mapping(uint256 => Lottery) private lotteries;

    /// @notice Current active lottery ID
    uint256 public currentLotteryId;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) {
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
}
