// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {FortunaLottery} from "../contracts/FortunaLottery.sol";

contract FortunaLotteryTest is Test {
    FortunaLottery public lottery;
    address public owner;
    address public participant1;
    address public participant2;
    address public participant3;

    // Mock VRF Coordinator for testing
    address public constant VRF_COORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    uint256 public constant SUBSCRIPTION_ID = 1;
    bytes32 public constant KEY_HASH =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    uint256 public constant TOKENS_PER_PARTICIPANT = 10;
    uint256 public startTime;
    uint256 public endTime;

    event LotteryCreated(
        uint256 indexed lotteryId,
        uint256 itemCount,
        uint256 tokensPerParticipant,
        uint256 startTime,
        uint256 endTime
    );

    event ParticipantRegistered(
        uint256 indexed lotteryId, address indexed participant, uint256 tokensReceived
    );

    event TokensPlaced(
        uint256 indexed lotteryId,
        address indexed participant,
        uint256 indexed itemId,
        uint256 tokens
    );

    function setUp() public {
        owner = address(this);
        participant1 = makeAddr("participant1");
        participant2 = makeAddr("participant2");
        participant3 = makeAddr("participant3");

        lottery = new FortunaLottery(VRF_COORDINATOR, SUBSCRIPTION_ID, KEY_HASH);

        startTime = block.timestamp;
        endTime = block.timestamp + 7 days;
    }

    function testInitialState() public {
        assertEq(lottery.currentLotteryId(), 0);
    }

    function testCreateLottery() public {
        string[] memory itemNames = new string[](3);
        itemNames[0] = "Item 1";
        itemNames[1] = "Item 2";
        itemNames[2] = "Item 3";

        string[] memory itemDescriptions = new string[](3);
        itemDescriptions[0] = "Description 1";
        itemDescriptions[1] = "Description 2";
        itemDescriptions[2] = "Description 3";

        vm.expectEmit(true, true, true, true);
        emit LotteryCreated(0, 3, TOKENS_PER_PARTICIPANT, startTime, endTime);

        uint256 lotteryId =
            lottery.createLottery("Test Lottery", TOKENS_PER_PARTICIPANT, startTime, endTime, itemNames, itemDescriptions);

        assertEq(lotteryId, 0);
        assertEq(lottery.currentLotteryId(), 0);

        (
            string memory name,
            uint256 tokensPerParticipant,
            uint256 start,
            uint256 end,
            uint256 itemCount,
            bool isActive
        ) = lottery.getLotteryInfo(0);

        assertEq(name, "Test Lottery");
        assertEq(tokensPerParticipant, TOKENS_PER_PARTICIPANT);
        assertEq(start, startTime);
        assertEq(end, endTime);
        assertEq(itemCount, 3);
        assertTrue(isActive);
    }

    function testCannotCreateLotteryAsNonOwner() public {
        string[] memory itemNames = new string[](1);
        itemNames[0] = "Item 1";

        string[] memory itemDescriptions = new string[](1);
        itemDescriptions[0] = "Description 1";

        vm.prank(participant1);
        vm.expectRevert();
        lottery.createLottery(
            "Test Lottery", TOKENS_PER_PARTICIPANT, startTime, endTime, itemNames, itemDescriptions
        );
    }

    function testRegisterParticipant() public {
        uint256 lotteryId = _createBasicLottery();

        vm.prank(participant1);
        vm.expectEmit(true, true, true, true);
        emit ParticipantRegistered(lotteryId, participant1, TOKENS_PER_PARTICIPANT);

        lottery.registerParticipant(lotteryId);

        (uint256 totalTokens, uint256 tokensUsed, bool registered) =
            lottery.getParticipantInfo(lotteryId, participant1);

        assertEq(totalTokens, TOKENS_PER_PARTICIPANT);
        assertEq(tokensUsed, 0);
        assertTrue(registered);
    }

    function testCannotRegisterTwice() public {
        uint256 lotteryId = _createBasicLottery();

        vm.startPrank(participant1);
        lottery.registerParticipant(lotteryId);

        vm.expectRevert(FortunaLottery.Lottery__AlreadyParticipated.selector);
        lottery.registerParticipant(lotteryId);
        vm.stopPrank();
    }

    function testPlaceTokens() public {
        uint256 lotteryId = _createBasicLottery();

        vm.startPrank(participant1);
        lottery.registerParticipant(lotteryId);

        vm.expectEmit(true, true, true, true);
        emit TokensPlaced(lotteryId, participant1, 0, 5);

        lottery.placeTokens(lotteryId, 0, 5);
        vm.stopPrank();

        (, uint256 tokensUsed,) = lottery.getParticipantInfo(lotteryId, participant1);

        assertEq(tokensUsed, 5);
        assertEq(
            lottery.getParticipantTokensOnItem(lotteryId, participant1, 0), 5
        );

        (,, uint256 itemTotalTokens,,) = lottery.getItemInfo(lotteryId, 0);
        assertEq(itemTotalTokens, 5);
    }

    function testPlaceTokensMultipleTimes() public {
        uint256 lotteryId = _createBasicLottery();

        vm.startPrank(participant1);
        lottery.registerParticipant(lotteryId);

        lottery.placeTokens(lotteryId, 0, 3);
        lottery.placeTokens(lotteryId, 0, 2);
        lottery.placeTokens(lotteryId, 1, 5);
        vm.stopPrank();

        assertEq(
            lottery.getParticipantTokensOnItem(lotteryId, participant1, 0), 5
        );
        assertEq(
            lottery.getParticipantTokensOnItem(lotteryId, participant1, 1), 5
        );

        (, uint256 tokensUsed,) = lottery.getParticipantInfo(lotteryId, participant1);
        assertEq(tokensUsed, 10);
    }

    function testCannotPlaceMoreTokensThanAvailable() public {
        uint256 lotteryId = _createBasicLottery();

        vm.startPrank(participant1);
        lottery.registerParticipant(lotteryId);

        vm.expectRevert(FortunaLottery.Lottery__InsufficientTokens.selector);
        lottery.placeTokens(lotteryId, 0, 11);
        vm.stopPrank();
    }

    function testPlaceTokensBatch() public {
        uint256 lotteryId = _createBasicLottery();

        vm.startPrank(participant1);
        lottery.registerParticipant(lotteryId);

        uint256[] memory itemIds = new uint256[](3);
        itemIds[0] = 0;
        itemIds[1] = 1;
        itemIds[2] = 2;

        uint256[] memory tokenAmounts = new uint256[](3);
        tokenAmounts[0] = 3;
        tokenAmounts[1] = 4;
        tokenAmounts[2] = 3;

        lottery.placeTokensBatch(lotteryId, itemIds, tokenAmounts);
        vm.stopPrank();

        assertEq(
            lottery.getParticipantTokensOnItem(lotteryId, participant1, 0), 3
        );
        assertEq(
            lottery.getParticipantTokensOnItem(lotteryId, participant1, 1), 4
        );
        assertEq(
            lottery.getParticipantTokensOnItem(lotteryId, participant1, 2), 3
        );

        (, uint256 tokensUsed,) = lottery.getParticipantInfo(lotteryId, participant1);
        assertEq(tokensUsed, 10);
    }

    function testMultipleParticipants() public {
        uint256 lotteryId = _createBasicLottery();

        // Participant 1
        vm.startPrank(participant1);
        lottery.registerParticipant(lotteryId);
        lottery.placeTokens(lotteryId, 0, 10);
        vm.stopPrank();

        // Participant 2
        vm.startPrank(participant2);
        lottery.registerParticipant(lotteryId);
        lottery.placeTokens(lotteryId, 0, 5);
        lottery.placeTokens(lotteryId, 1, 5);
        vm.stopPrank();

        // Participant 3
        vm.startPrank(participant3);
        lottery.registerParticipant(lotteryId);
        lottery.placeTokens(lotteryId, 1, 10);
        vm.stopPrank();

        assertEq(lottery.getParticipantCount(lotteryId), 3);

        (,, uint256 item0Tokens,,) = lottery.getItemInfo(lotteryId, 0);
        assertEq(item0Tokens, 15);

        (,, uint256 item1Tokens,,) = lottery.getItemInfo(lotteryId, 1);
        assertEq(item1Tokens, 15);
    }

    function testEndLottery() public {
        uint256 lotteryId = _createBasicLottery();

        lottery.endLottery(lotteryId);

        (,,,,, bool isActive) = lottery.getLotteryInfo(lotteryId);
        assertFalse(isActive);
    }

    function testCannotPlaceTokensAfterLotteryEnds() public {
        uint256 lotteryId = _createBasicLottery();

        vm.startPrank(participant1);
        lottery.registerParticipant(lotteryId);
        vm.stopPrank();

        lottery.endLottery(lotteryId);

        vm.prank(participant1);
        vm.expectRevert(FortunaLottery.Lottery__NotActive.selector);
        lottery.placeTokens(lotteryId, 0, 5);
    }

    // Helper function to create a basic lottery
    function _createBasicLottery() internal returns (uint256) {
        string[] memory itemNames = new string[](3);
        itemNames[0] = "Item 1";
        itemNames[1] = "Item 2";
        itemNames[2] = "Item 3";

        string[] memory itemDescriptions = new string[](3);
        itemDescriptions[0] = "Description 1";
        itemDescriptions[1] = "Description 2";
        itemDescriptions[2] = "Description 3";

        return lottery.createLottery(
            "Test Lottery", TOKENS_PER_PARTICIPANT, startTime, endTime, itemNames, itemDescriptions
        );
    }
}
