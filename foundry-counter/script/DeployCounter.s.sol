// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Script.sol";
import {Counter, IERC20} from "../src/Counter.sol";

contract DeployCounterScript is Script {
    string DEFAULT_NEAR_ACCOUNT_ID = "counter-contract-001.testnet";
    address DEFAULT_WNEAR_ADDRESS = 0x4861825E75ab14553E5aF711EbbE6873d369d146;
    uint256 DEFAULT_NUMBER = 0;

    function run() external returns (Counter) {
        string memory privateKeyStr = vm.envString("AURORA_PRIVATE_KEY");
        if (bytes(privateKeyStr).length == 0) {
            revert("AURORA_PRIVATE_KEY environment variable not set.");
        }
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        address deployerAddress = vm.addr(deployerPrivateKey);
        console.log("Deployer Address:", deployerAddress, deployerAddress.balance);

        string memory nearAccountId = vm.envOr("CONSTRUCTOR_NEAR_ACCOUNT_ID", DEFAULT_NEAR_ACCOUNT_ID);
        address wNearAddress = vm.envOr("CONSTRUCTOR_WNEAR_ADDRESS", DEFAULT_WNEAR_ADDRESS);
        uint256 number = vm.envOr("CONSTRUCTOR_NUMBER", DEFAULT_NUMBER);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Contract with parameters:");
        console.log("  NEAR Account ID:", nearAccountId);
        console.log("  wNEAR:", wNearAddress);
        console.log("  Number:", number);

        Counter counterContract = new Counter(nearAccountId, IERC20(wNearAddress), number);

        console.log("Contract deployed to:", address(counterContract));

        vm.stopBroadcast();

        return counterContract;
    }
}
