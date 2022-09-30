/**
 *Submitted for verification at polygonscan.com on 2022-05-17
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./adbmath.sol";
import "./price.sol";

// File: AMP3.sol

contract AmpToken is ERC1155, ERC2981, PriceConsumerV3, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    enum PaymentStatus {
        PENDINGPAYMENT,
        SENT
    }

    //EVENTS//
    event AmpCreated(
        uint256 indexed id,
        address creator,
        address owner,
        string name,
        uint256 price,
        uint256 _amount
    );

    struct Amp {
        uint256 id;
        address payable creator;
        uint256 price;
        uint256 amount;
        string name;
        bool valid;
    }

    struct Payment {
        uint256 id;
        address learner;
        PaymentStatus _state;
    }

    address payable public owner;
    uint256 lillupPrice = 0.000033 ether;

    //change to private before going live
    mapping(uint256 => Amp) public idToAmp;
    mapping(uint256 => Payment) public idToPay;
    mapping(uint256 => bool) private soldOut;
    mapping(address => bool) public creators;
    mapping(address => bool) public apprvLearner;
    mapping(address => bool) public whitelist;
    mapping(uint256 => string) internal _tokenURIs;

    address payable private marketAddress =
        payable(0x6ABc0b7386618B3A450e1A3f740F33e98220ab88);

    uint256 public nextCreatorsId;
    uint256 public nextLearnerId;
    uint256 public nextPaymentId;
    uint256 public totalAmp;

    constructor() ERC1155("") {
        // set royalty of all NFTs to 8%
        owner = payable(msg.sender);
        _setDefaultRoyalty(owner, 800);
    }

    //OWNER ONLY//
    function approveCreators(address _creators) public onlyOwner {
        //Contract owner approves new admin addresses - Complete
        //require check that the address being added doesnt already exist - Complete
        require(creators[_creators] != true, "Already Creator");
        creators[_creators] = true;
        nextCreatorsId++;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    //CREATIRS ONLY//
    /* MINT AMP NFT*/
    function createAmp(
        string memory _name,
        // uint256 _id,
        uint256 _price,
        uint256 _amount
    )
        public
        payable
        virtual
        returns (
            // bytes memory metadata
            uint256
        )
    {
        //  Do you want them to give their own ID or go in order of nextAmpId?
        //  This would require our frontend dev to make sure nextAmpID is a set field on frontend.
        //  require(idToAmp[_id].id == nextAmpId, "Please select the next Amp ID");
        //  require(idToAmp[_id].valid == false, "This ID is already taken");
        //  require(_price > 0 * 10^18, "Price must be at least 1 MATIC");
        //  8% Royalties should go to owner
        _setDefaultRoyalty(owner, 800);

        // int latestPrice = PriceConsumerV3.getLatestPrice();
        // int priceInUsd = (_price/(10**18))*(latestPrice/10**8);
        uint256 newTokenId = _tokenIds.current();
        idToAmp[newTokenId].creator = payable(msg.sender);
        idToAmp[newTokenId].name = _name;
        idToAmp[newTokenId].price = _price;
        idToAmp[newTokenId].amount = _amount;
        idToAmp[newTokenId].valid = true;

        ///set mint value
        uint256 buf2=10**18;
        bytes16 count= ABDKMathQuad.fromUInt(_amount);
        bytes16 buf1=ABDKMathQuad.div(ABDKMathQuad.mul(ABDKMathQuad.fromInt(-49),ABDKMathQuad.mul(ABDKMathQuad.ln(count), ABDKMathQuad.fromUInt(buf2))),ABDKMathQuad.fromInt(500));
        bytes16 buf=ABDKMathQuad.add(buf1, ABDKMathQuad.fromUInt(buf2));
        bytes16 tokenprice= ABDKMathQuad.mul(count,buf);    
        uint256 price = ABDKMathQuad.toUInt(tokenprice);

        marketAddress.transfer(price);

        _mint(msg.sender, newTokenId, _amount, "");
        _setTokenUri(newTokenId, _name);
        _setURI(_name);
        totalAmp += _amount;
        _tokenIds.increment();

        return newTokenId;

        //  createCourseItem(newTokenId, _price, _amount, _name);
    }

    function _setTokenUri(uint256 tokenId, string memory _tokenURI) private {
        _tokenURIs[tokenId] = _tokenURI;
    }


    /**
     * @dev Returns an URI for a given token ID
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return _tokenURIs[_tokenId];
    }


    //need to have royalties sent to Owner once Amp tokens are sent to Learner
    function sendAmp(
        address _to,
        uint256 _id,
        uint256 _amount
    ) public nonReentrant {
        idToPay[_id] = Payment(
            idToPay[_id].id = nextPaymentId,
            _to,
            idToPay[_id]._state = PaymentStatus.PENDINGPAYMENT
        );
        nextPaymentId++;

        //require(msg.value == listingPrice, "Price must be equal to listing price");
        idToAmp[_id] = Amp(
            _id,
            payable(msg.sender),
            _amount,
            idToAmp[_id].price,
            idToAmp[_id].name,
            idToAmp[_id].valid
        );

        //set enum status to pending payment

        // set 2.5%fee when send transfer
        uint256 buf=10**18;
        uint256 sendfee= SafeMath.div(SafeMath.mul(idToAmp[_id].price,25),1000);
        marketAddress.transfer(SafeMath.mul(sendfee,buf));
        
        _safeTransferFrom(_msgSender(), _to, _id, _amount, "");
    }

    function sendPayment(uint256 _id) public payable onlyLearner {
        //Needs to have learner send payment to creator if amount is correct
        //function needs to be called in the sendAMP function above.
        Payment storage payment = idToPay[_id];
        require(
            msg.sender == payment.learner,
            "Please connect the correct wallet address"
        );
        require(
            idToPay[_id]._state == PaymentStatus.PENDINGPAYMENT,
            "Payment Not Active"
        );
    }

    //Triggers payment for item if customer sends correct amount for item.
    /*function triggerPayment(uint _itemIndex) public payable {
        require(items[_itemIndex]._itemPrice == msg.value, "Only full payments accepted");
        require(items[_itemIndex]._state == SupplyChainState.Created, "Item is further in the chain");
        
        items[_itemIndex]._state = SupplyChainState.Paid;
        
        emit SupplyChainStep(_itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
    }
    */

    function setLearner(address _learner) public {
        require(
            creators[_learner] != true,
            "Already a creator. This address cannot be student"
        );
        apprvLearner[_learner] = true;
        nextLearnerId++;
    }

    //students added to whitelist don't pay when buying course
    function setWhiteList(address _whitelist) public onlyCreators {
        whitelist[_whitelist] = true;
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 _id, uint256 _amount)
        public
        payable
        onlyLearner
    {
        address creator = idToAmp[_id].creator;
        uint256 price = idToAmp[_id].price;
        uint256 tokenId = idToAmp[_id].id;
        require(idToAmp[_id].amount >= 1, "Course Sold Out");
        require(_amount == 1, "Amount too high, Select 1 token");
        idToAmp[_id].creator = payable(address(0));
        //Need to Add If statment for whitelist users. If Admin does not want to charge a student there address should be added to the whitelist
        if (whitelist[_msgSender()] == true) {
            _safeTransferFrom(address(this), msg.sender, tokenId, _amount, "");
            payable(creator).transfer(msg.value);
            idToAmp[_id].amount = idToAmp[_id].amount - 1;
        } else {
            require(msg.value == price, "Please submit the asking price");
            _safeTransferFrom(address(this), msg.sender, tokenId, _amount, "");
            payable(creator).transfer(msg.value);
            idToAmp[_id].amount = idToAmp[_id].amount - 1;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /*
     // Updates the listing price of the contract Has no Function at the moment
    function updateListingPrice(uint _listingPrice) public payable onlyOwner {
      listingPrice = _listingPrice;
    }

     // Returns the listing price of the contract. Has No function at the moment
    function getListingPrice() public view returns (uint256) {
      return listingPrice;
    }
    */

    //MODIFIERS//
    //OnlyAdmins can use functions that utilize this modifier

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Owner");
        _;
    }
    modifier onlyCreators() {
        require(creators[_msgSender()] == true, "Only Creators");
        _;
    }

    modifier onlyLearner() {
        require(
            apprvLearner[_msgSender()] == true,
            "Please register as a Student"
        );
        _;
    }
}
