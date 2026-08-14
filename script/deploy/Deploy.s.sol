// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../../src/ArtToken.sol";

contract DeployScript is Script {
    function run() external returns (ArtToken) {
        // Ensure we are deploying to Sepolia (Chain ID 11155111)
        if (block.chainid != 11155111) {
            revert("Wrong network: Only Sepolia (11155111) is supported");
        }

        // Start broadcasting using the --private-key flag passed in the CLI
        vm.startBroadcast();

        string memory name = vm.envString("TOKEN_NAME");
        string memory symbol = vm.envString("TOKEN_SYMBOL");

        ArtToken token = new ArtToken(name, symbol);

        vm.stopBroadcast();
        return token;
    }
}
