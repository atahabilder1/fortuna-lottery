// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {FortunaLotteryZK} from "../contracts/FortunaLotteryZK.sol";
import {MockBetVerifier} from "../contracts/mocks/MockBetVerifier.sol";
import {MockWinnerVerifier} from "../contracts/mocks/MockWinnerVerifier.sol";
import {MockVRFCoordinator} from "../contracts/mocks/MockVRFCoordinator.sol";

contract FortunaLotteryZKTest is Test {
    FortunaLotteryZK public lottery;
    MockBetVerifier public betVerifier;
    MockWinnerVerifier public winnerVerifier;
    MockVRFCoordinator public vrfCoordinator;

    address public owner = address(1);
    address public alice = address(2);
    address public bob = address(3);
    address public carol = address(4);

    uint256 public lotteryId;

    function setUp() public {
        vm.startPrank(owner);

        // Deploy mock verifiers
        betVerifier = new MockBetVerifier();
        winnerVerifier = new MockWinnerVerifier();
        vrfCoordinator = new MockVRFCoordinator();

        // Deploy lottery contract
        lottery = new FortunaLotteryZK(
            address(betVerifier),
            address(winnerVerifier),
            address(vrfCoordinator)
        );

        // Create a test lottery
        string[] memory itemNames = new string[](3);
        itemNames[0] = "Golden Watch";
        itemNames[1] = "Silver Ring";
        itemNames[2] = "Bronze Medal";

        string[] memory itemDescs = new string[](3);
        itemDescs[0] = "A luxurious golden watch";
        itemDescs[1] = "An elegant silver ring";
        itemDescs[2] = "A commemorative bronze medal";

        lotteryId = lottery.createLottery(
            "Test Lottery",
            itemNames,
            itemDescs,
            100, // tokens per participant
            block.timestamp, // start now
            block.timestamp + 1 days // end in 1 day
        );

        vm.stopPrank();
    }

    function test_CreateLottery() public view {
        (
            string memory name,
            uint256 tokensPerParticipant,
            uint256 startTime,
            uint256 endTime,
            uint256 itemCount,
            bool isActive,
            uint256 commitmentCount
        ) = lottery.getLotteryInfo(lotteryId);

        assertEq(name, "Test Lottery");
        assertEq(tokensPerParticipant, 100);
        assertEq(itemCount, 3);
        assertTrue(isActive);
        assertEq(commitmentCount, 0);
        assertGt(endTime, startTime);
    }

    function test_Register() public {
        vm.prank(alice);
        lottery.register(lotteryId);

        (uint256 totalTokens, uint256 tokensUsed, bool registered) =
            lottery.getAllocation(lotteryId, alice);

        assertEq(totalTokens, 100);
        assertEq(tokensUsed, 0);
        assertTrue(registered);
    }

    function test_RevertWhen_DoubleRegister() public {
        vm.startPrank(alice);
        lottery.register(lotteryId);

        vm.expectRevert(FortunaLotteryZK.ZK__AlreadyRegistered.selector);
        lottery.register(lotteryId);
        vm.stopPrank();
    }

    function test_PlaceBetZK() public {
        // Register Alice
        vm.prank(alice);
        lottery.register(lotteryId);

        // Place a bet with mock proof
        uint256[8] memory proof;
        uint256 commitment = 12345;
        uint256 nullifierHash = 67890;
        uint256 itemId = 0;
        uint256 tokenAmount = 25;

        vm.prank(alice);
        lottery.placeBetZK(
            lotteryId,
            proof,
            commitment,
            nullifierHash,
            itemId,
            tokenAmount
        );

        // Check item has tokens
        (,,uint256 totalTokens,,,) = lottery.getItemInfo(lotteryId, itemId);
        assertEq(totalTokens, 25);

        // Check allocation updated
        (, uint256 tokensUsed,) = lottery.getAllocation(lotteryId, alice);
        assertEq(tokensUsed, 25);

        // Check merkle tree updated
        assertEq(lottery.getLeafCount(), 1);
    }

    function test_MultipleBets() public {
        // Register participants
        vm.prank(alice);
        lottery.register(lotteryId);
        vm.prank(bob);
        lottery.register(lotteryId);

        uint256[8] memory proof;

        // Alice bets 30 tokens on item 0
        vm.prank(alice);
        lottery.placeBetZK(lotteryId, proof, 111, 222, 0, 30);

        // Bob bets 20 tokens on item 0
        vm.prank(bob);
        lottery.placeBetZK(lotteryId, proof, 333, 444, 0, 20);

        // Alice bets 25 tokens on item 1
        vm.prank(alice);
        lottery.placeBetZK(lotteryId, proof, 555, 666, 1, 25);

        // Check totals
        (,,uint256 item0Tokens,,,) = lottery.getItemInfo(lotteryId, 0);
        (,,uint256 item1Tokens,,,) = lottery.getItemInfo(lotteryId, 1);

        assertEq(item0Tokens, 50); // 30 + 20
        assertEq(item1Tokens, 25);
        assertEq(lottery.getLeafCount(), 3);
    }

    function test_RevertWhen_InsufficientTokens() public {
        vm.prank(alice);
        lottery.register(lotteryId);

        uint256[8] memory proof;

        // Try to bet more tokens than allocated
        vm.prank(alice);
        vm.expectRevert(FortunaLotteryZK.ZK__InsufficientTokens.selector);
        lottery.placeBetZK(lotteryId, proof, 111, 222, 0, 150);
    }

    function test_RevertWhen_NullifierReused() public {
        vm.prank(alice);
        lottery.register(lotteryId);

        uint256[8] memory proof;
        uint256 nullifierHash = 12345;

        // First bet works
        vm.prank(alice);
        lottery.placeBetZK(lotteryId, proof, 111, nullifierHash, 0, 25);

        // Second bet with same nullifier fails
        vm.prank(alice);
        vm.expectRevert(FortunaLotteryZK.ZK__NullifierAlreadyUsed.selector);
        lottery.placeBetZK(lotteryId, proof, 222, nullifierHash, 1, 25);
    }

    function test_WinnerSelection() public {
        // Register and place bets
        vm.prank(alice);
        lottery.register(lotteryId);
        vm.prank(bob);
        lottery.register(lotteryId);

        uint256[8] memory proof;

        vm.prank(alice);
        lottery.placeBetZK(lotteryId, proof, 111, 222, 0, 30);

        vm.prank(bob);
        lottery.placeBetZK(lotteryId, proof, 333, 444, 0, 20);

        // Fast forward past lottery end
        vm.warp(block.timestamp + 2 days);

        // Use setWinningPositionForTesting instead of VRF for simpler testing
        vm.prank(owner);
        lottery.setWinningPositionForTesting(lotteryId, 0, 35);

        // Check winner was selected
        (,,,uint256 winningPos, bool winnerSelected,) =
            lottery.getItemInfo(lotteryId, 0);

        assertTrue(winnerSelected);
        assertEq(winningPos, 35);
    }

    function test_ClaimPrize() public {
        // Setup: register, bet, select winner
        vm.prank(alice);
        lottery.register(lotteryId);

        uint256[8] memory proof;
        vm.prank(alice);
        lottery.placeBetZK(lotteryId, proof, 111, 222, 0, 50);

        vm.warp(block.timestamp + 2 days);

        vm.prank(owner);
        lottery.setWinningPositionForTesting(lotteryId, 0, 25);

        // Claim prize
        uint256 claimNullifierHash = 99999;
        address recipient = address(100);

        vm.prank(alice);
        lottery.claimPrize(
            lotteryId,
            0,
            proof,
            claimNullifierHash,
            recipient
        );

        // Check prize claimed
        (,,,,, bool prizeClaimed) = lottery.getItemInfo(lotteryId, 0);
        assertTrue(prizeClaimed);
    }

    function test_RevertWhen_DoubleClaim() public {
        // Setup
        vm.prank(alice);
        lottery.register(lotteryId);

        uint256[8] memory proof;
        vm.prank(alice);
        lottery.placeBetZK(lotteryId, proof, 111, 222, 0, 50);

        vm.warp(block.timestamp + 2 days);
        vm.prank(owner);
        lottery.setWinningPositionForTesting(lotteryId, 0, 25);

        // First claim works
        vm.prank(alice);
        lottery.claimPrize(lotteryId, 0, proof, 99999, address(100));

        // Second claim fails
        vm.prank(bob);
        vm.expectRevert(FortunaLotteryZK.ZK__ClaimAlreadyProcessed.selector);
        lottery.claimPrize(lotteryId, 0, proof, 88888, address(101));
    }

    function test_TicketRanges() public {
        // Register participants
        vm.prank(alice);
        lottery.register(lotteryId);
        vm.prank(bob);
        lottery.register(lotteryId);
        vm.prank(carol);
        lottery.register(lotteryId);

        uint256[8] memory proof;

        // Alice: tickets 0-29 (30 tokens)
        vm.prank(alice);
        lottery.placeBetZK(lotteryId, proof, 111, 222, 0, 30);

        // Bob: tickets 30-49 (20 tokens)
        vm.prank(bob);
        lottery.placeBetZK(lotteryId, proof, 333, 444, 0, 20);

        // Carol: tickets 50-99 (50 tokens)
        vm.prank(carol);
        lottery.placeBetZK(lotteryId, proof, 555, 666, 0, 50);

        // Total should be 100
        (,,uint256 totalTokens,,,) = lottery.getItemInfo(lotteryId, 0);
        assertEq(totalTokens, 100);

        // Verify we have 3 commitments in the merkle tree
        assertEq(lottery.getLeafCount(), 3);
    }

    function test_MerkleTreeGrowth() public {
        vm.prank(alice);
        lottery.register(lotteryId);

        uint256[8] memory proof;

        // Initial state
        assertEq(lottery.getLeafCount(), 0);

        // Add commitments
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(alice);
            lottery.placeBetZK(lotteryId, proof, i * 100, i * 1000, 0, 10);
        }

        // Check tree grew
        assertEq(lottery.getLeafCount(), 10);

        // Check root is valid
        assertTrue(lottery.isValidLotteryRoot(lotteryId, lottery.getRoot()));
    }

    function test_LotteryNotActiveAfterEnd() public {
        vm.prank(alice);
        lottery.register(lotteryId);

        // Fast forward past end
        vm.warp(block.timestamp + 2 days);

        uint256[8] memory proof;

        // Betting should fail
        vm.prank(alice);
        vm.expectRevert(FortunaLotteryZK.ZK__LotteryNotActive.selector);
        lottery.placeBetZK(lotteryId, proof, 111, 222, 0, 25);
    }
}
