//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Marketplace is ReentrancyGuard, ERC721URIStorage {

    // Account to receive commission fee.
    address payable contractAddress; 
    // Fee percentage on sale.
    uint16 immutable marketFee; 

    using Counters for Counters.Counter;
    // Counter for total number of tokens minted
    Counters.Counter public tokenIds; 
    // Counter for total number of items listed in the marketplace
    Counters.Counter public itemIds; 
    // Counter for total number of items sold in the marketplace
    Counters.Counter public itemsSold; 

    struct MarketItem {
        // ID of the item in the marketplace
        uint256 itemId; 
        // ID of the token that represents the item
        uint256 tokenId; 
        // Address of the seller of the item
        address payable seller; 
        // Address of the current owner of the item
        address payable owner; 
        // Asking price of the item
        uint256 price; 
        // Boolean that indicates if the item is sold or not
        bool isSold;
    }

    // Mapping that holds the details of all items in the marketplace
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
    

    constructor (address _address) ERC721("NFTPinas", "NFTP") {
        // Set the contract address to the address that deployed the contract
        contractAddress = payable(_address);
        // Set the commission fee percentage
        marketFee = 250;
    }

    function mintItem(string memory _tokenURI) external returns(uint256) {
        // Increment the total number of tokens minted
        tokenIds.increment();
        uint256 currentTokenId = tokenIds.current();
        // Mint a new token for the user
        _mint(msg.sender, currentTokenId);
        // Set the URI for the token
        _setTokenURI(currentTokenId, _tokenURI);
        // Return the ID of the newly minted token
        return(currentTokenId);
    }

     function listItem(uint256 _tokenId ,uint256 _price) external payable nonReentrant{
        // Check that the price is greater than 0
        require(_price > 0, "Price must be greater than 0");

        // Increment the total number of items listed
        itemIds.increment();
        uint256 currentMarketId = itemIds.current();

        // Transfer the token to the contract's address
        _transfer(msg.sender, address(this), _tokenId);
        
        // Add the item to the marketplace
        idMarketItem[currentMarketId] = MarketItem(
            currentMarketId,
            _tokenId,
            payable(msg.sender),
            payable(address(this)),
            _price,
            false
        );

        // Emit an event that the item was listed
        emit listedItem(
            currentMarketId, 
            _tokenId,
            msg.sender,
            address(this),
            _price,
            false
        );
    }


    function buyItem(uint256 _itemId) public payable nonReentrant {
        // Get the price of the item
        uint256 price = idMarketItem[_itemId].price;
        // Get the tokenId of the item
        uint256 _tokenId = idMarketItem[_itemId].tokenId;
        // Check if the msg.value is equal to the price of the item
        require(msg.value == price, "Kindly enter the asking price to complete your purchase.");
        // Calculate the platform fee
        uint256 platformFee = (price * marketFee) / 10000;
        
        // Send the platform fee to the contract address
        payable(contractAddress).transfer(platformFee);
        
        // Send the remaining amount to the seller
        payable(idMarketItem[_itemId].seller).transfer(msg.value - platformFee);
        // Transfer the token to the buyer
        _transfer(address(this), msg.sender, _tokenId);
        // Update the item's status
        idMarketItem[_itemId].isSold = true;
        idMarketItem[_itemId].owner = payable(msg.sender);
        // Increment the number of sold items
        itemsSold.increment();

        // Emit an event with the item's details
        emit boughtItem(
            _itemId, 
            _tokenId,
            idMarketItem[_itemId].seller,
            msg.sender,
            price,
            true
        );
    }

    function fetchMarketItems() external view returns(MarketItem[] memory) {
        //Get the current number of items
        uint256 totalItemsCount = itemIds.current();
        // Get the current number of sold items
        uint256 itemsSoldCount = itemsSold.current();
        // Calculate the number of unsold items
        uint256 unsoldItemsCount = totalItemsCount - itemsSoldCount;

        // Create an empty array to store the unsold items
        MarketItem[] memory items = new MarketItem[](unsoldItemsCount);

        // Iterate through all items in the market
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= totalItemsCount; i++) {
            // Check if the item is unsold
            if(idMarketItem[i].owner == address(this)) {
                // Get the item's unique identifier
                uint256 currentId = idMarketItem[i].itemId;
                // Get the item's information
                MarketItem storage currentItem = idMarketItem[currentId];
                // Add the item to the array of unsold items
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    function fetchUserAssets() external view returns(MarketItem[] memory) {
        // Get the total number of items listed
        uint256 totalItemsCount =  itemIds.current();
        // Initialize the number of items listed by the user
        uint256 myItemCount = 0;
        // Initialize the current index for the items array
        uint256 currentIndex = 0;

        // Iterate through all the items and count the number of items listed by the user
        for(uint256 i = 0; i < totalItemsCount; i++) {
            if(idMarketItem[i+1].seller == msg.sender) {
                myItemCount += 1;
            }
        }

        // Create an array of MarketItems with the number of items the user has listed
        MarketItem[] memory items = new MarketItem[](myItemCount);
        // Iterate through all the items and add the items listed by the user to the array
        for(uint256 i = 0; i < totalItemsCount; i++) {
            if(idMarketItem[i+1].seller == msg.sender) {
                uint256 currentId = idMarketItem[i+1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        // Return the array of items
        return(items);
    }


}