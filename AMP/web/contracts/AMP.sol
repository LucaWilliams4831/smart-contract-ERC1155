// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Amp is ERC1155, ERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    //EVENTS//
    event CourseItemCreated (
      uint256 indexed id,
      address creator,
      address owner,
      uint256 price,
      uint _amount
    );

    struct Course {
        uint id;
        address payable creator;
      //address payable owner;
        uint price;
        uint amount;  
        string name;
        string company; 
    }

    
    //change to private before going live
    mapping(uint256 => Course) public idToCourses;
    mapping(address => uint256) public students;
    mapping(uint256 => bool) private courseIds;
    mapping(address => bool) public admin;
    mapping(address => bool) public apprvStudent;
   
    uint public nextCourseId;
    uint public nextAdminId;
    uint public nextStudentId;

    uint256 listingPrice = 0.025 ether;
    
    constructor() ERC1155("https://ipfs.io/ipfs/bafybeigb7tqhulo5zciqshuzvofz3pv7kozrs57fgjo53jz5n4qkl66qzu/Amp.json") {
        // set royalty of all NFTs to 5%

        _setDefaultRoyalty(_msgSender(), 500);
    }

   

    //OWNER ONLY//
    function approveAdmin(address _admin) public onlyOwner {
      //Contract owner approves new admin addresses - Complete
      //require check that the address being added doesnt already exist - Complete
      require(admin[_admin] != true, "Already Admin");
      admin[_admin] = true;  
      nextAdminId++;
    } 

    function setStudent(address _student) public {
      require(admin[_student] != true, "Already an admin. This address cannot be student");
      apprvStudent[_student] = true;
      nextStudentId++;
    }

    //ADMINS ONLY//
    /* Mints tokens and lists it in the marketplace */
    //Should add newTokenID back here
    function createCourse(uint256 _id, uint256 _amount, uint256 _price, string memory _name, string memory _company) virtual public payable onlyAdmin() returns (uint) {
     
      _setDefaultRoyalty(_msgSender(), 500);
      _tokenIds.increment();
      uint256 newTokenId = _tokenIds.current();

      _mint(msg.sender, _id, _amount, "");
      
      createCourseItem(_id, _price, _amount, _name, _company);
      return newTokenId;
    }

    function createCourseItem(
      uint256 _id,
      uint _amount,
      uint256 _price,
      string memory _name,
      string memory _company
    ) private onlyAdmin() {
      require(courseIds[_id] == false, "This ID is already taken");
      require(_price > 0, "Price must be at least 1 wei");
      //require(msg.value == listingPrice, "Price must be equal to listing price");

      idToCourses[_id] =  Course(
        _id,
        payable(msg.sender),
      //  payable(address(this)),
        _amount,
        _price,
        _name,
        _company
        
      );

      _safeTransferFrom(msg.sender, address(this), _id, _amount, "");
      
      emit CourseItemCreated(
        _id,
        msg.sender,
        address(this),
        _price,
        _amount 
      );
      
      nextCourseId++;
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    /* Subtract 1 minted nft from Course ID on purchase */
    /* This function is wrong. Don't use _safeTransferFrom*/
    /* Need NonReentrant */

    function createMarketSale(
      uint256 _id,
      uint256 _amount
      ) public payable onlyStudent() {
      //uint price = idToCourses[_id].price;
        uint tokenId = idToCourses[_id].id;
      //bool sold = idToCourses[_id].sold;
      //require(msg.value == price, "Please submit the asking price");
      //require(sold != true, "This Sale is already finished");
      //EMIT MARKETID SOLD
      //idToCourses[_id].creator.transfer(msg.value);
      _safeTransferFrom(address(this), msg.sender, tokenId, _amount,"");
      idToCourses[_id].amount = idToCourses[_id].amount -1;
      



    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

     /* Updates the listing price of the contract Has no Function at the moment*/
    function updateListingPrice(uint _listingPrice) public payable onlyOwner {
      listingPrice = _listingPrice;
    }

     /* Returns the listing price of the contract. Has No function at the moment*/
    function getListingPrice() public view returns (uint256) {
      return listingPrice;
    }

    //MODIFIERS//
    //OnlyAdmins can use functions that utilize this modifier
    modifier onlyAdmin() {
      require(admin[_msgSender()] == true ,"Only Admin");
      _;
    }

    //Not Sure if this is really needed.
    modifier onlyStudent() {
      require(apprvStudent[_msgSender()] == true, "Please register as a Student");
      _;
    }
}
