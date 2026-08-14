// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ArtToken.sol";
import {IERC721Receiver} from "@openzeppelin/contracts@4.4.2/token/ERC721/IERC721Receiver.sol";

contract Handler is Test, IERC721Receiver {
    ArtToken internal t;
    address[] internal actors;

    constructor(ArtToken _t) {
        t = _t;
        // Populate actors so the array is never empty
        actors.push(address(0x1111));
        actors.push(address(0x2222));
    }

    function createArt(uint256 actorSeed, string calldata name) public payable {
        address a = actors[actorSeed % actors.length];

        // Fund the ACTOR address, because startPrank makes them the caller,
        // meaning msg.value will be deducted from their balance.
        vm.deal(a, 1000 ether);

        vm.startPrank(a);
        t.createRandomArtWork{value: t.fee()}(name);
        vm.stopPrank();
    }

    // Implement IERC721Receiver so the Handler can safely receive NFTs if needed
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Required to receive ETH
    receive() external payable {}
}

contract Invariants is Test {
    ArtToken internal t;
    Handler internal h;

    function setUp() public {
        t = new ArtToken("Art", "ART");
        h = new Handler(t);

        // Tell the fuzzer to ONLY call functions on the Handler
        targetContract(address(h));
    }

    // Added `view` to fix compiler warning 2018
    function invariant_totalSupplyConsistent() public view {
        // Since the handler never holds tokens, its balance should always be 0
        assertEq(t.balanceOf(address(h)), 0);
    }
}
