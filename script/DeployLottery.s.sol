// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {FortunaLottery} from "../contracts/FortunaLottery.sol";

/**
 * @title DeployLottery
 * @notice Deployment script for FortunaLottery contract on Base Sepolia
 * @dev Run with: forge script script/DeployLottery.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast --verify
 */
contract DeployLottery is Script {
    // Base Sepolia Chainlink VRF Coordinator
    address public constant VRF_COORDINATOR = 0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE;

    // Base Sepolia VRF Configuration
    // Get your subscription ID from: https://vrf.chain.link/base-sepolia
    uint256 public subscriptionId;

    // Base Sepolia 30 gwei key hash
    bytes32 public constant KEY_HASH =
        0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;

    function run() external returns (FortunaLottery) {
        // Get subscription ID from environment variable
        subscriptionId = vm.envUint("VRF_SUBSCRIPTION_ID");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Deploying FortunaLottery contract...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("VRF Coordinator:", VRF_COORDINATOR);
        console.log("Subscription ID:", subscriptionId);
        console.log("Key Hash:", vm.toString(KEY_HASH));

        vm.startBroadcast(deployerPrivateKey);

        FortunaLottery lottery = new FortunaLottery(
            VRF_COORDINATOR,
            subscriptionId,
            KEY_HASH
        );

        vm.stopBroadcast();

        console.log("FortunaLottery deployed to:", address(lottery));
        console.log("\n=== Post-Deployment Steps ===");
        console.log("1. Add this contract as a consumer to your VRF subscription:");
        console.log("   Go to: https://vrf.chain.link/base-sepolia");
        console.log("   Add consumer:", address(lottery));
        console.log("\n2. Verify contract (if --verify flag wasn't used):");
        console.log(
            "   forge verify-contract",
            address(lottery),
            "contracts/FortunaLottery.sol:FortunaLottery",
            "--chain-id 84532"
        );

        return lottery;
    }
}
