# Smart-contract-ERC1155 

  Date:12 December,2021

## Release 1.0

Code by DAN

Verification by Laz

Validation by Gana

Engineering process Openzeppelin v4.4.0

Test done on : Testnet Rinkeby

Features Included in the test1.sol:

function uri 

Created a test token in contract file :  test1.sol

To test the file we can use Remix   [link](http://remix.ethereum.org/#optimize=false&runs=200&evmVersion=null&version=soljson-v0.5.17+commit.d19bba13.js0)

After opening the file  
- compile the fie 
- then deploy it using the injected web3 which is connected to metamask when it's done copy the deployed address
- And paste it in the sourcfy for verification



## Release v1.7
Date:3 January,2022


code by dan

Verification by laz

Validation by gana

Engineering process Openzeppelin v4.4.0

complied and deployed in Remix  [link](http://remix.ethereum.org/#optimize=false&runs=200&evmVersion=null&version=soljson-v0.5.17+commit.d19bba13.js0)

- compile the fie 
- then deploy it using the injected web3 which is connected to metamask when it's done copy the deployed address and perform tasks accordingly

Test(deploy) done on : injected web3 ( Testnet Rinkeby and ploygon matic )

Features/Functions Included in the Release v1.7

 * approveAdmin
 * mint
 * registerAdmin
 * registerStudent
 * renounceOwnership 
 * safeBatchTransfer
 * safeTransferFrom 
 * setApprovalForAll 
 * transferOwnership 
 * admin ( address )
 * balanceOf ( address account and Id ) 
 * balanceOfBatch ( address account and Id )
 * isApprovedForAll ( address account and operation )
 * numberOfStudents
 * Owner
 * Student ( address )
 * supportsInterface
 * tokensInCirculation 


## Release v3.2
smart contract address 0x8dCBCf3be31E2b4594701Afdc31832534aB714ce


## Release v3.3
* Lillup wallet address added
* PriceConsumerV3 (MATIC to USD)
* Creator Minting Fee  (used abdmath.sol for logarithm calculation)
* setTokenUri function (set metadata)
* 2.5% royalty fee for every transaction
