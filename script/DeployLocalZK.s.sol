// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {FortunaLotteryZK} from "../contracts/FortunaLotteryZK.sol";
import {MockBetVerifier} from "../contracts/mocks/MockBetVerifier.sol";
import {MockWinnerVerifier} from "../contracts/mocks/MockWinnerVerifier.sol";
import {MockVRFCoordinator} from "../contracts/mocks/MockVRFCoordinator.sol";

/// @title DeployLocalZK
/// @notice Deploys FortunaLotteryZK with mock verifiers for local testing
/// @dev Run with: forge script script/DeployLocalZK.s.sol --rpc-url http://localhost:8545 --broadcast
contract DeployLocalZK is Script {
    function run() external {
        // Use Anvil's default private key for local deployment
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock verifiers
        MockBetVerifier betVerifier = new MockBetVerifier();
        console.log("MockBetVerifier deployed at:", address(betVerifier));

        MockWinnerVerifier winnerVerifier = new MockWinnerVerifier();
        console.log("MockWinnerVerifier deployed at:", address(winnerVerifier));

        MockVRFCoordinator vrfCoordinator = new MockVRFCoordinator();
        console.log("MockVRFCoordinator deployed at:", address(vrfCoordinator));

        // Deploy FortunaLotteryZK
        FortunaLotteryZK lottery = new FortunaLotteryZK(
            address(betVerifier),
            address(winnerVerifier),
            address(vrfCoordinator)
        );
        console.log("FortunaLotteryZK deployed at:", address(lottery));

        // Create a sample lottery for testing
        string[] memory itemNames = new string[](3);
        itemNames[0] = "Golden Trophy";
        itemNames[1] = "Silver Medal";
        itemNames[2] = "Bronze Badge";

        string[] memory itemDescs = new string[](3);
        itemDescs[0] = "The grand prize - a golden trophy";
        itemDescs[1] = "Second place - a silver medal";
        itemDescs[2] = "Third place - a bronze badge";

        uint256 lotteryId = lottery.createLottery(
            "Demo Lottery",
            itemNames,
            itemDescs,
            100, // 100 tokens per participant
            block.timestamp, // starts now
            block.timestamp + 7 days // ends in 7 days
        );

        console.log("Sample lottery created with ID:", lotteryId);

        vm.stopBroadcast();

        // Print summary
        console.log("\n=== Deployment Summary ===");
        console.log("Network: Local (Anvil)");
        console.log("FortunaLotteryZK:", address(lottery));
        console.log("MockBetVerifier:", address(betVerifier));
        console.log("MockWinnerVerifier:", address(winnerVerifier));
        console.log("MockVRFCoordinator:", address(vrfCoordinator));
        console.log("Sample Lottery ID:", lotteryId);
        console.log("\nUpdate your frontend .env with:");
        console.log("NEXT_PUBLIC_CONTRACT_ADDRESS=", address(lottery));
    }
}
