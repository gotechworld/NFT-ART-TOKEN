// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ArtToken.sol";

contract ArtTokenTest is Test {
    ArtToken public artToken;

    address public owner;
    address public user1;
    address public user2;

    event NewArtWork(address indexed owner, uint256 indexed id, uint256 indexed dna);

    // Required so the test contract can receive ETH during withdraw()
    receive() external payable {}

    function setUp() public {
        artToken = new ArtToken("ArtToken", "ART");

        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Fund users with enough ETH for fuzz tests (50 mints * 5 ether = 250 ether)
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);
    }

    // ============================================
    // 1. Deployment & Config Tests
    // ============================================

    function test_Deployment() public view {
        assertEq(artToken.name(), "ArtToken");
        assertEq(artToken.symbol(), "ART");
        assertEq(artToken.fee(), 5 ether);
        assertEq(artToken.owner(), owner);
    }

    function test_UpdateFee() public {
        artToken.updateFee(10 ether);
        assertEq(artToken.fee(), 10 ether);
    }

    function test_RevertIf_NonOwnerUpdatesFee() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        artToken.updateFee(10 ether);
    }

    // ============================================
    // 2. Minting Tests
    // ============================================

    function test_CreateRandomArtWork() public {
        vm.prank(user1);
        // Only check topic 1 (owner) and topic 2 (id). Ignore topic 3 (dna) and data.
        vm.expectEmit(true, true, false, false);
        emit NewArtWork(user1, 0, 0);

        artToken.createRandomArtWork{value: 5 ether}("Masterpiece");

        assertEq(artToken.balanceOf(user1), 1);
        assertEq(artToken.ownerOf(0), user1);

        ArtToken.Art[] memory arts = artToken.getArtWorks();
        assertEq(arts.length, 1);
        assertEq(arts[0].name, "Masterpiece");
        assertEq(arts[0].id, 0);
        assertEq(arts[0].level, 1);
    }

    function test_RevertIf_InsufficientFee() public {
        vm.prank(user1);
        // Must encode the arguments to match the exact revert data
        vm.expectRevert(abi.encodeWithSelector(ArtToken.InsufficientFee.selector, 4 ether, 5 ether));
        artToken.createRandomArtWork{value: 4 ether}("Cheap Art");
    }

    function test_MultipleMintsIncrementCounter() public {
        vm.startPrank(user1);
        artToken.createRandomArtWork{value: 5 ether}("Art 1");
        artToken.createRandomArtWork{value: 5 ether}("Art 2");
        vm.stopPrank();

        assertEq(artToken.balanceOf(user1), 2);
        assertEq(artToken.ownerOf(0), user1);
        assertEq(artToken.ownerOf(1), user1);
    }

    // ============================================
    // 3. View Functions Tests
    // ============================================

    function test_GetOwnerArtWork() public {
        vm.startPrank(user1);
        artToken.createRandomArtWork{value: 5 ether}("Art 1");
        artToken.createRandomArtWork{value: 5 ether}("Art 2");
        vm.stopPrank();

        vm.prank(user2);
        artToken.createRandomArtWork{value: 5 ether}("Art 3");

        ArtToken.Art[] memory user1Arts = artToken.getOwnerArtWork(user1);
        assertEq(user1Arts.length, 2);
        assertEq(user1Arts[0].name, "Art 1");
        assertEq(user1Arts[1].name, "Art 2");

        ArtToken.Art[] memory user2Arts = artToken.getOwnerArtWork(user2);
        assertEq(user2Arts.length, 1);
        assertEq(user2Arts[0].name, "Art 3");
    }

    function test_InfoSmartContract() public {
        vm.prank(user1);
        artToken.createRandomArtWork{value: 5 ether}("Art 1");

        (address sc_address, uint256 sc_money) = artToken.infoSmartContract();

        assertEq(sc_address, address(artToken));
        // Contract divides by 10**18, so 5 ether becomes 5
        assertEq(sc_money, 5);
    }

    // ============================================
    // 4. Level Up & Transfer Tests
    // ============================================

    function test_LevelUp() public {
        vm.prank(user1);
        artToken.createRandomArtWork{value: 5 ether}("Art 1");

        vm.prank(user1);
        artToken.levelUp(0);

        ArtToken.Art[] memory arts = artToken.getArtWorks();
        assertEq(arts[0].level, 2);
    }

    function test_RevertIf_NonOwnerLevelsUp() public {
        vm.prank(user1);
        artToken.createRandomArtWork{value: 5 ether}("Art 1");

        vm.prank(user2);
        vm.expectRevert(ArtToken.NotOwner.selector);
        artToken.levelUp(0);
    }

    function test_TransferUpdatesOwnerArtWorkArray() public {
        vm.prank(user1);
        artToken.createRandomArtWork{value: 5 ether}("Art 1");

        vm.prank(user1);
        artToken.transferFrom(user1, user2, 0);

        ArtToken.Art[] memory user1Arts = artToken.getOwnerArtWork(user1);
        assertEq(user1Arts.length, 0);

        ArtToken.Art[] memory user2Arts = artToken.getOwnerArtWork(user2);
        assertEq(user2Arts.length, 1);
        assertEq(user2Arts[0].name, "Art 1");
    }

    // ============================================
    // 5. Withdrawal Tests
    // ============================================

    function test_Withdraw() public {
        vm.prank(user1);
        artToken.createRandomArtWork{value: 5 ether}("Art 1");

        uint256 ownerBalanceBefore = owner.balance;

        artToken.withdraw();

        (, uint256 sc_money) = artToken.infoSmartContract();
        assertEq(sc_money, 0);
        assertEq(owner.balance, ownerBalanceBefore + 5 ether);
    }

    function test_RevertIf_NonOwnerWithdraws() public {
        vm.prank(user1);
        artToken.createRandomArtWork{value: 5 ether}("Art 1");

        vm.prank(user2);
        vm.expectRevert("Ownable: caller is not the owner");
        artToken.withdraw();
    }

    // ============================================
    // 6. Fuzz Tests
    // ============================================

    function testFuzz_CreateRandomArtWork(uint256 feeAmount) public {
        feeAmount = bound(feeAmount, 0, 100 ether);

        artToken.updateFee(feeAmount);

        vm.prank(user1);
        if (feeAmount > 0) {
            artToken.createRandomArtWork{value: feeAmount}("Fuzz Art");
            assertEq(artToken.balanceOf(user1), 1);
            assertEq(artToken.ownerOf(0), user1);
        } else {
            artToken.createRandomArtWork{value: 0}("Free Fuzz Art");
            assertEq(artToken.balanceOf(user1), 1);
        }
    }

    function testFuzz_MultipleMintsAndLevelUp(uint8 mintCount) public {
        uint256 count = bound(uint256(mintCount), 1, 50);

        vm.startPrank(user1);
        for (uint256 i = 0; i < count; ++i) {
            artToken.createRandomArtWork{value: 5 ether}("Fuzz Art");
        }
        vm.stopPrank();

        assertEq(artToken.balanceOf(user1), count);

        uint256 randomTokenId = uint256(keccak256(abi.encodePacked(block.timestamp))) % count;

        vm.prank(user1);
        artToken.levelUp(randomTokenId);

        ArtToken.Art[] memory arts = artToken.getArtWorks();
        assertEq(arts[randomTokenId].level, 2);
    }
}
