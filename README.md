
# AirdropNFT

A simple ERC721 NFT smart contract designed specifically for airdrops without public minting functionality. The contract supports both single and batch airdrops while maintaining a fixed maximum supply.

## Features

- **Airdrop Functionality**: Send NFTs to individual or multiple recipients
- **No Public Mint**: Only the owner can mint NFTs via airdrops
- **Fixed Supply**: Maximum token count is set at deployment and cannot be changed
- **ERC721Enumerable**: Full enumeration support for all tokens
- **Royalties Support**: Implements ERC-2981 for marketplace royalties
- **Owner-Only Operations**: All minting and configuration is restricted to the contract owner

## Prerequisites

- [Node.js](https://nodejs.org/) (>= 14.x)
- [npm](https://www.npmjs.com/) (>= 6.x)
- [Hardhat](https://hardhat.org/) or [Truffle](https://trufflesuite.com/)
- [OpenZeppelin Contracts](https://www.openzeppelin.com/contracts)

## Installation

1. Create a new project directory and initialize it:

```bash
mkdir my-nft-project
cd my-nft-project
npm init -y
```

2. Install required dependencies:

```bash
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @nomiclabs/hardhat-waffle @openzeppelin/contracts dotenv
```

3. Initialize Hardhat:

```bash
npx hardhat
```

4. Create a `contracts` directory and add the AirdropNFT contract:

```bash
mkdir contracts
```

5. Create a file named `AirdropNFT.sol` in the contracts directory and copy the contract code into it.

## Deployment

1. Create a deployment script in the `scripts` directory:

```javascript
// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy AirdropNFT contract
  const AirdropNFT = await hre.ethers.getContractFactory("AirdropNFT");
  const airdropNFT = await AirdropNFT.deploy(
    "MyNFTCollection",                // Collection name
    "MNFT",                           // Symbol
    10000,                            // Maximum supply
    "ipfs://QmYourBaseURI/",          // Base URI for metadata
    deployer.address,                 // Royalty receiver address
    500                               // Royalty percentage (5%)
  );

  await airdropNFT.deployed();
  console.log("AirdropNFT deployed to:", airdropNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

2. Configure Hardhat network settings in `hardhat.config.js`

3. Deploy the contract:

```bash
npx hardhat run scripts/deploy.js --network <your-network>
```

## Usage Guide

### Contract Deployment Parameters

When deploying the AirdropNFT contract, you need to provide the following parameters:

1. **_name**: The name of your NFT collection (e.g., "My Awesome NFTs")
2. **_symbol**: A short symbol for your collection (e.g., "MNFT")
3. **_maxSupply**: The maximum number of NFTs that can ever be minted
4. **_initialBaseURI**: The base URI for metadata (e.g., "ipfs://QmYourBaseURI/")
5. **_royaltyReceiver**: Address that will receive royalties from secondary sales
6. **_royaltyPercentage**: Percentage of sales that go to royalties in basis points (e.g., 500 = 5%)

### Airdropping NFTs

As the contract owner, you can airdrop NFTs to recipients:

#### Single Airdrop

Use this function to airdrop an NFT to a single recipient:

```javascript
// Example using ethers.js
const recipientAddress = "0xRecipientAddress";
const tx = await airdropNFT.airdrop(recipientAddress);
await tx.wait();

const receipt = await tx.wait();
// You can find the event in the logs to get the tokenId
const airdropEvent = receipt.events.find(e => e.event === "Airdropped");
const tokenId = airdropEvent.args.tokenId;
console.log(`Airdropped token ${tokenId} to ${recipientAddress}`);
```

#### Batch Airdrop

Use this function to airdrop NFTs to multiple recipients at once:

```javascript
// Example using ethers.js
const recipients = [
  "0xRecipient1Address",
  "0xRecipient2Address",
  "0xRecipient3Address",
  // Add more recipients as needed
];

const tx = await airdropNFT.airdropBatch(recipients);
await tx.wait();

const receipt = await tx.wait();
// You can find the event in the logs to get token info
const batchEvent = receipt.events.find(e => e.event === "BatchAirdropped");
const startTokenId = batchEvent.args.startTokenId;
const quantity = batchEvent.args.quantity;
console.log(`Airdropped ${quantity} tokens starting from ID ${startTokenId}`);
```

### Setting Up Metadata

The contract uses a base URI + tokenId + ".json" pattern for token URIs. For example, if your base URI is `ipfs://QmYourBaseURI/`, token ID 1 would have a URI of `ipfs://QmYourBaseURI/1.json`.

Each JSON file should follow a structure like:

```json
{
  "name": "NFT #1",
  "description": "Description for NFT #1",
  "image": "ipfs://QmYourImagesCID/1.png",
  "attributes": [
    {
      "trait_type": "Background",
      "value": "Blue"
    },
    {
      "trait_type": "Eyes",
      "value": "Green"
    }
  ]
}
```

#### Changing the Base URI

If you need to update the base URI for your metadata:

```javascript
const newBaseURI = "ipfs://QmNewBaseURI/";
const tx = await airdropNFT.setBaseURI(newBaseURI);
await tx.wait();
```

### Managing Royalties

You can update royalty information after deployment:

```javascript
const newReceiver = "0xNewRoyaltyReceiverAddress";
const newPercentage = 1000; // 10%
const tx = await airdropNFT.setRoyaltyInfo(newReceiver, newPercentage);
await tx.wait();
```

### Withdrawing Funds

If ETH is mistakenly sent to the contract, the owner can withdraw it:

```javascript
const tx = await airdropNFT.withdraw();
await tx.wait();
```

## Contract Functions Reference

### Airdrop Functions

- **airdrop(address to)**: Airdrops a single NFT to the specified address.
  - Can only be called by the owner
  - Returns the token ID of the airdropped NFT
  - Emits an `Airdropped` event

- **airdropBatch(address[] calldata recipients)**: Airdrops NFTs to multiple addresses in one transaction.
  - Can only be called by the owner
  - Mints one NFT per address in the array
  - Returns the last token ID minted
  - Emits a `BatchAirdropped` event

### Metadata Management

- **setBaseURI(string memory _newBaseURI)**: Updates the base URI for all token metadata.
  - Can only be called by the owner

- **tokenURI(uint256 tokenId)**: Returns the metadata URI for a specific token.
  - Follows the pattern: baseURI + tokenId + ".json"
  - Reverts if the token does not exist

### Royalty Management

- **setRoyaltyInfo(address _receiver, uint96 _percentage)**: Updates royalty information.
  - Can only be called by the owner
  - Percentage is in basis points (e.g., 500 = 5%)
  - Maximum percentage is 10000 (100%)

- **royaltyInfo(uint256 tokenId, uint256 salePrice)**: Returns royalty information for a token.
  - Implements ERC-2981 standard
  - Returns the royalty receiver address and the royalty amount based on the sale price

### Administration

- **withdraw()**: Withdraws any ETH mistakenly sent to the contract to the owner's address.
  - Can only be called by the owner

## Common Use Cases

### Issuing Membership NFTs

This contract is perfect for issuing membership NFTs to a known list of addresses:

```javascript
// Example: Airdrop membership NFTs to DAO members
const daoMembers = [
  "0xMember1Address",
  "0xMember2Address",
  // ... more members
];

await airdropNFT.airdropBatch(daoMembers);
```

### Rewarding Community Members

Use batch airdrops to reward active community members:

```javascript
// Example: Reward top contributors
const topContributors = [
  "0xContributor1Address",
  "0xContributor2Address",
  // ... more contributors
];

await airdropNFT.airdropBatch(topContributors);
```

### Special Edition Releases

For special one-off airdrops to specific collectors:

```javascript
// Example: Airdrop a special edition NFT
await airdropNFT.airdrop("0xCollectorAddress");
```

## Gas Optimization Tips

- When doing large airdrops, break them into smaller batches (e.g., 100 addresses per transaction) to avoid hitting gas limits
- Consider using a specialized airdrop tool for very large drops (1000+ addresses)

## Security Considerations

- The contract uses OpenZeppelin's battle-tested libraries for security
- Only the owner can mint NFTs, providing strong access control
- Constructor parameters cannot be changed after deployment (particularly maxSupply)
- Owner functions are protected with the Ownable modifier
- Consider a professional audit before deploying with significant value

## License

This project is licensed under the MIT License - see the LICENSE file for details.
