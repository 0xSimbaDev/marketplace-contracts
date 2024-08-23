// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;

    // Account to receive commission fee.
    address payable public contractAddress;
    // Fee percentage on sale.
    uint16 public marketFee;
    // Counter for total number of items listed in the marketplace
    Counters.Counter private itemIds;
    // Counter for total number of items sold in the marketplace
    Counters.Counter private itemsSold;

    struct MarketItem {
        uint256 itemId;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool isSold;
    }

    mapping(uint256 => MarketItem) public idMarketItem;

    event listedItem (
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool isSold
    );

    event boughtItem (
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool isSold
    );

    constructor (address _address) {
        contractAddress = payable(_address);
        marketFee = 250;
    }

    function listItem(address nftAddress, uint256 _tokenId, uint256 _price) external payable nonReentrant {
        require(_price > 0, "Price must be greater than 0");
        itemIds.increment();
        uint256 currentMarketId = itemIds.current();
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

        idMarketItem[currentMarketId] = MarketItem(
            currentMarketId,
            _tokenId,
            payable(msg.sender),
            payable(address(this)),
            _price,
            false
        );

        emit listedItem(
            currentMarketId, 
            _tokenId,
            msg.sender,
            address(this),
            _price,
            false
        );
    }

    function buyItem(address nftAddress, uint256 _itemId) public payable nonReentrant {
        uint256 price = idMarketItem[_itemId].price;
        uint256 _tokenId = idMarketItem[_itemId].tokenId;
        require(msg.value == price, "Enter the asking price to complete your purchase.");
        uint256 platformFee = (price * marketFee) / 10000;
        
        payable(contractAddress).transfer(platformFee);
        payable(idMarketItem[_itemId].seller).transfer(msg.value - platformFee);
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

        idMarketItem[_itemId].isSold = true;
        idMarketItem[_itemId].owner = payable(msg.sender);
        itemsSold.increment();

        emit boughtItem(
            _itemId, 
            _tokenId,
            idMarketItem[_itemId].seller,
            msg.sender,
            price,
            true
        );
    }

    function cancelListing(uint256 _itemId) external nonReentrant {
        require(idMarketItem[_itemId].seller == msg.sender, "Only the seller can cancel the listing");
        require(!idMarketItem[_itemId].isSold, "Sold item cannot be cancelled");
        
        uint256 _tokenId = idMarketItem[_itemId].tokenId;

        IERC721(address(this)).safeTransferFrom(address(this), msg.sender, _tokenId);
        delete idMarketItem[_itemId];
    }
}
