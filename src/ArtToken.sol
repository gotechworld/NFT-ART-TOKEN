// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts@4.4.2/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts@4.4.2/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts@4.4.2/security/ReentrancyGuard.sol";

/// @title ArtToken Contract
/// @author Your Name
/// @notice A simple NFT contract for creating artwork tokens
contract ArtToken is ERC721, Ownable, ReentrancyGuard {
    // ============================================
    // Type Declarations
    // ============================================

    /// @notice Data structure with the properties of the artwork
    struct Art {
        string name;
        uint256 id;
        uint256 dna;
        uint8 level;
        uint8 rarity;
    }

    // ============================================
    // State Variables
    // ============================================

    /// @notice NFT token counter
    uint256 public counter;

    /// @notice Pricing of NFT Tokens (price of the artwork)
    uint256 public fee = 5 ether;

    /// @notice Storage structure for keeping artworks
    Art[] public artWorks;

    // ============================================
    // Events
    // ============================================

    /// @notice Declaration of an event
    /// @param owner Address of the token owner
    /// @param id ID of the token
    /// @param dna DNA of the artwork
    event NewArtWork(address indexed owner, uint256 indexed id, uint256 indexed dna);

    // ============================================
    // Custom Errors
    // ============================================
    error InsufficientFee(uint256 sent, uint256 required);
    error NotOwner();
    error WithdrawFailed();

    // ============================================
    // Constructor
    // ============================================

    /// @notice Smart Contract Constructor
    /// @param _name Name of the token
    /// @param _symbol Symbol of the token
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    // ============================================
    // External Functions
    // ============================================

    /// @notice NFT Token Price Update
    /// @param _fee New fee amount
    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /// @notice Extraction of ethers from the Smart Contract to the Owner
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        address payable _owner = payable(owner());

        // Using .call instead of .transfer to prevent gas limit issues with multisig wallets
        (bool success,) = _owner.call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }

    // ============================================
    // Public Functions
    // ============================================

    /// @notice NFT Token Payment
    /// @param _name Name of the artwork
    function createRandomArtWork(string memory _name) public payable nonReentrant {
        if (msg.value < fee) revert InsufficientFee(msg.value, fee);
        _createArtWork(_name);
    }

    /// @notice Level up NFT Tokens
    /// @param _artId ID of the artwork to level up
    function levelUp(uint256 _artId) public {
        if (ownerOf(_artId) != msg.sender) revert NotOwner();
        Art storage art = artWorks[_artId];
        ++art.level;
    }

    /// @notice Visualize the balance of the Smart Contract (ethers)
    function infoSmartContract() public view returns (address, uint256) {
        address scAddress = address(this);
        uint256 scMoney = address(this).balance / 10 ** 18;
        return (scAddress, scMoney);
    }

    /// @notice Obtaining all created NFT tokens (artwork)
    function getArtWorks() public view returns (Art[] memory) {
        return artWorks;
    }

    /// @notice Obtaining a user's NFT tokens
    /// @param _owner Address of the token owner
    function getOwnerArtWork(address _owner) public view returns (Art[] memory) {
        Art[] memory result = new Art[](balanceOf(_owner));
        uint256 counterOwner = 0;
        // slither-disable-next-line calls-loop
        for (uint256 i = 0; i < artWorks.length; ++i) {
            if (ownerOf(i) == _owner) {
                result[counterOwner] = artWorks[i];
                ++counterOwner;
            }
        }
        return result;
    }

    // ============================================
    // Internal Functions
    // ============================================

    /// @notice NFT Token Creation (Artwork)
    /// @param _name Name of the artwork
    function _createArtWork(string memory _name) internal {
        uint8 randRarity = uint8(_createRandomNum(1000));
        uint256 randDna = _createRandomNum(10 ** 16);

        uint256 tokenId = counter;
        Art memory newArtWork = Art(_name, tokenId, randDna, 1, randRarity);
        artWorks.push(newArtWork);

        // EFFECT: Increment counter BEFORE minting (Checks-Effects-Interactions pattern)
        ++counter;

        // INTERACTION: Safe mint last
        _safeMint(msg.sender, tokenId);
        emit NewArtWork(msg.sender, tokenId, randDna);
    }

    /// @notice Creation of a random number (required for NFT token properties)
    /// @param _mod Modulo for the random number
    function _createRandomNum(uint256 _mod) internal view returns (uint256) {
        // slither-disable-next-line timestamp
        // Using prevrandao instead of timestamp for slightly better pseudo-randomness
        bytes32 hasRandomNum = keccak256(abi.encodePacked(block.prevrandao, msg.sender));
        uint256 randomNum = uint256(hasRandomNum);
        return randomNum % _mod;
    }
}
