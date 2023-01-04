# Solution to Challenger #2 Alchemy University

Objetives:
By the end of this tutorial, you will learn how to do the following:

    * Use the Hardhat development environment to build, test, and deploy our smart contract.
    * Connect your MetaMask wallet to the Goerli test network using an Alchemy RPC endpoint.
    * Get free Goerli ETH from goerlifaucet.com.
    * Use Ethers.js to interact with your deployed smart contract.
    * Build a frontend website for your decentralized application with Replit.

## Beginning 🚀

_These instructions will allow you to get a copy of the project running on your local machine for 
development and testing purposes._

See **Deployment** for how to deploy the project.

### Prerequisites 📋

To prepare for the rest of this tutorial, you need to have:

    npm (npx) version 8.5.5
    node version 16.13.1
    An Alchemy account (sign up here for free!)

The following is not required, but extremely useful:

    some familiarity with a command line
    some familiarity with JavaScript

Now let's begin building our smart contract


### Instalation 🔧

_Code the BuyMeACoffee.sol smart contract_

Open your terminal and create a new directory:

```
mkdir BuyMeACoffee-contracts
cd BuyMeACoffee-contracts
```

start a new npm project (default settings are fine):

```
npm init -y
```

This should create a package.json file for you that looks like this:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npm init 
-y
Wrote to ~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$/package.json:

{
  "name": "buymeacoffee-contracts",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}

```

Install hardhat:

```
npm install --save-dev hardhat
```

Create a sample project:

```
npx hardhat
```

Press Enter to accept all the default settings and install the sample project's dependencie.

Your project directory should now look something like this (Use tree to visualize):

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ tree -C 
-L 1
```

![Alt text](https://www.github.com/assets.digitalocean.com/articles/alligator/boo.svg "a title")

Rename the contract file to BuyMeACoffee.sol

Replace the contract code with the following:

```
//SPDX-License-Identifier: Unlicense

// contracts/BuyMeACoffee.sol
pragma solidity ^0.8.0;

// Switch this to your own contract address once deployed, for bookkeeping!
// Example Contract Address on Goerli: 0xDBa03676a2fBb6711CB652beF5B7416A53c1421D

contract BuyMeACoffee {
    // Event to emit when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable owner;

    // List of all memos received from coffee purchases.
    Memo[] memos;

    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(msg.sender);
    }

    /**
     * @dev fetches all stored memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message) public payable {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "can't buy coffee for free!");

        // Add the memo to storage!
        memos.push(Memo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }
}
```

_Create a buy-coffee.js script to test your contract_

Under the scripts folder, there should be a sample script already populated sample-script.js. Let's 
rename that file to buy-coffee.js and paste in the following code:

```
const hre = require("hardhat");

// Returns the Ether balance of a given address.
async function getBalance(address) {
  const balanceBigInt = await hre.ethers.provider.getBalance(address);
  return hre.ethers.utils.formatEther(balanceBigInt);
}

// Logs the Ether balances for a list of addresses.
async function printBalances(addresses) {
  let idx = 0;
  for (const address of addresses) {
    console.log(`Address ${idx} balance: `, await getBalance(address));
    idx ++;
  }
}

// Logs the memos stored on-chain from coffee purchases.
async function printMemos(memos) {
  for (const memo of memos) {
    const timestamp = memo.timestamp;
    const tipper = memo.name;
    const tipperAddress = memo.from;
    const message = memo.message;
    console.log(`At ${timestamp}, ${tipper} (${tipperAddress}) said: "${message}"`);
  }
}

async function main() {
  // Get the example accounts we'll be working with.
  const [owner, tipper, tipper2, tipper3] = await hre.ethers.getSigners();

  // We get the contract to deploy.
  const BuyMeACoffee = await hre.ethers.getContractFactory("BuyMeACoffee");
  const buyMeACoffee = await BuyMeACoffee.deploy();

  // Deploy the contract.
  await buyMeACoffee.deployed();
  console.log("BuyMeACoffee deployed to:", buyMeACoffee.address);

  // Check balances before the coffee purchase.
  const addresses = [owner.address, tipper.address, buyMeACoffee.address];
  console.log("== start ==");
  await printBalances(addresses);

  // Buy the owner a few coffees.
  const tip = {value: hre.ethers.utils.parseEther("1")};
  await buyMeACoffee.connect(tipper).buyCoffee("Carolina", "You're the best!", tip);
  await buyMeACoffee.connect(tipper2).buyCoffee("Vitto", "Amazing teacher", tip);
  await buyMeACoffee.connect(tipper3).buyCoffee("Kay", "I love my Proof of Knowledge", tip);

  // Check balances after the coffee purchase.
  console.log("== bought coffee ==");
  await printBalances(addresses);

  // Withdraw.
  await buyMeACoffee.connect(owner).withdrawTips();

  // Check balances after withdrawal.
  console.log("== withdrawTips ==");
  await printBalances(addresses);

  // Check out the memos.
  console.log("== memos ==");
  const memos = await buyMeACoffee.getMemos();
  printMemos(memos);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

Now for the fun, let's run the script:

```
npx hardhat run scripts/buy-coffee.js
```

You should see the output in your terminal like this:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx 
hardhat run scripts/buy-coffee.js
Downloading compiler 0.8.17
Compiled 2 Solidity files successfully
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
== start ==
Address 0 balance:  9999.99857209
Address 1 balance:  10000.0
Address 2 balance:  0.0
== bought coffee ==
Address 0 balance:  9999.99857209
Address 1 balance:  9998.999752217513572352
Address 2 balance:  3.0
== withdrawTips ==
Address 0 balance:  10002.998526175780770316
Address 1 balance:  9998.999752217513572352
Address 2 balance:  0.0
== memos ==
At 1669600347, Carolina (0x70997970C51812dc3A010C7d01b50e0d17dc79C8) said: "You're the best!"
At 1669600348, Vitto (0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC) said: "Amazing teacher"
At 1669600349, Kay (0x90F79bf6EB2c4f870365E785982E1f101E93b906) said: "I love my Proof of Knowledge"
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ tree -C 
-L 1
```

_Deploy your BuyMeACoffe.sol smart contract to the local testnet_

Let's create a new file scripts/deploy.js that will be super simple, just for deploying our contract 
to any network we choose later (we'll choose Goerli later if you haven't noticed).

The deploy.js file should look like this:

```
// scripts/deploy.js

const hre = require("hardhat");

async function main() {
  // We get the contract to deploy.
  const BuyMeACoffee = await hre.ethers.getContractFactory("BuyMeACoffee");
  const buyMeACoffee = await BuyMeACoffee.deploy();

  await buyMeACoffee.deployed();

  console.log("BuyMeACoffee deployed to:", buyMeACoffee.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

```

Now with this deploy.js script coded and saved, if you run the following command:

```
npx hardhat run scripts/deploy.js
```

You'll see one single line printed out:

```
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

What's interesting is that if you run it over and over again, you'll see the same exact deploy address 
every time:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx 
hardhat run scripts/deploy.js
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx 
hardhat run scripts/deploy.js
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx 
hardhat run scripts/deploy.js
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx 
hardhat run scripts/deploy.js
BuyMeACoffee deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$
```

Why is that? That's because when you run the script, the default network that the Hardhat tool uses is 
a local development network, right on your computer. It's fast and deterministic and great for some 
quick sanity checking.

_Deploy your BuyMeACoffe.sol smart contract to the Ethereum Goerli testnet using Alchemy and MetaMask_

When you open your hardhat.config.js file, you will see some sample deploy code. Delete that and paste 
this version in:

```
// hardhat.config.js

require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("dotenv").config()

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const GOERLI_URL = process.env.GOERLI_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: GOERLI_URL,
      accounts: [PRIVATE_KEY]
    }
  }
};
```

Now before we can do our deployment, we need to make sure we get one last tool installed, the dotenv 
module. As its name implies, dotenv helps us connect a .env file to the rest of our project. Let's set 
it up.

Install dotenv:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npm 
install dotenv

added 1 package, and audited 924 packages in 34s

129 packages are looking for funding
  run `npm fund` for details
```

Create a .env file (Using of IDE VSCode) Populate the .env file with the variables that we need:

```
GOERLI_URL=https://eth-goerli.alchemyapi.io/v2/<your api key>
GOERLI_API_KEY=<your api key>
PRIVATE_KEY=<your metamask api key>
```

Also, in order to get what you need for environment variables, you can use the following resources:

    GOERLI_URL - sign up for an account on Alchemy, create an Ethereum -> Goerli app, and use the HTTP 
    URL
    GOERLI_API_KEY - from your same Alchemy Ethereum Goerli app, you can get the last portion of the 
    URL, and that will be your API KEY
    PRIVATE_KEY - Follow these instructions from MetaMask to export your private key.

Make sure that .env is listed in your .gitignore:

```
node_modules
.env
coverage
coverage.json
typechain
typechain-types

#Hardhat files
cache
artifacts
```

Now we can deploy!
Run the deploy script, this time adding a special flag to use the Goerli network:

```
npx hardhat run scripts/deploy.js --network goerli
```

If you see the follow error:

```
Error: Cannot find module '@nomiclabs/hardhat-waffle'
```

We proceed to execute the following line in our terminal:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npm 
install --save-dev @nomiclabs/hardhat-waffle 'ethereum-waffle@^3.0.0'
```

We run again:

```
npx hardhat run scripts/deploy.js --network goerli
```

We get:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx 
hardhat run scripts/deploy.js --network goerli
BuyMeACoffee deployed to: 0x2eE1DF352C85198c2F6859b74c8BA2c93B3b56f7
```

We verify that the SmartContract is truly deployed on the Tesnet Goerli using 
https://goerli.etherscan.io/

![Alt text](https://www.github.com/assets.digitalocean.com/articles/alligator/boo.svg "a title")

_Verify & Publish Contract Source Code_

We go to the following address:

https://goerli.etherscan.io/verifyContract

and fill in all the requested data. Finally we to see:

```
The Contract Source code for 0x2eE1DF352C85198c2F6859b74c8BA2c93B3b56f7 has already been verified.
Click here to view the Verified Contract Source Code
```

_Implement a withdraw script_

Later on when we publish our website, we'll need a way to collect all the awesome tips that our 
friends and fans are leaving us. We can write another hardhat script to do just that!

Create a file at scripts/withdraw.js

```
// scripts/withdraw.js

const hre = require("hardhat");
const abi = require("../artifacts/contracts/BuyMeACoffee.sol/BuyMeACoffee.json");

async function getBalance(provider, address) {
  const balanceBigInt = await provider.getBalance(address);
  return hre.ethers.utils.formatEther(balanceBigInt);
}

async function main() {
  // Get the contract that has been deployed to Goerli.
  const contractAddress="0x2eE1DF352C85198c2F6859b74c8BA2c93B3b56f7";
  const contractABI = abi.abi;

  // Get the node connection and wallet connection.
  const provider = new hre.ethers.providers.AlchemyProvider("goerli", process.env.GOERLI_API_KEY);

  // Ensure that signer is the SAME address as the original contract deployer,
  // or else this script will fail with an error.
  const signer = new hre.ethers.Wallet(process.env.PRIVATE_KEY, provider);

  // Instantiate connected contract.
  const buyMeACoffee = new hre.ethers.Contract(contractAddress, contractABI, signer);

  // Check starting balances.
  console.log("current balance of owner: ", await getBalance(provider, signer.address), "ETH");
  const contractBalance = await getBalance(provider, buyMeACoffee.address);
  console.log("current balance of contract: ", await getBalance(provider, buyMeACoffee.address), 
  "ETH");

  // Withdraw funds if there are funds to withdraw.
  if (contractBalance !== "0.0") {
    console.log("withdrawing funds..")
    const withdrawTxn = await buyMeACoffee.withdrawTips();
    await withdrawTxn.wait();
  } else {
    console.log("no funds to withdraw!");
  }

  // Check ending balance.
  console.log("current balance of owner: ", await getBalance(provider, signer.address), "ETH");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

The most important part of this script is when we call the withdrawTips() function to pull money out 
from our contract balance and send it over to the owner's wallet:

```
// Withdraw funds if there are funds to withdraw.
  if (contractBalance !== "0.0") {
    console.log("withdrawing funds..")
    const withdrawTxn = await buyMeACoffee.withdrawTips();
    await withdrawTxn.wait();
  }
until the end
```

If there are no funds in the contract, we avoid attempting to withdraw so that we don't spend gas fees 
unnecessarily.

## Build the frontend Buy Me A Coffee website dapp with Replit and Ethers.js ⚙️

For this website portion, in order to keep things simple and clean, we are going to use an amazing 
tool for spinning up demo projects quickly, called Replit IDE.

Visit my example project here, and fork it to create your own copy to modify: https://replit.com/
@thatguyintech/BuyMeACoffee-Solidity-DeFi-Tipping-app

After forking the repl, you should be taken to an IDE page where you can:

    See the code of a Next.js web application
    Get access to a console, a terminal shell, and a preview of the README.md file
    View a hot-reloading version of your dapp

This part of the tutorial will be quick and fun -- we're going to update a couple of variables so that 
it's connected to the smart contract we deployed in the earlier parts of the project and so that it 
shows your own name on the website!

Let's get everything hooked up and working first, and then I'll explain to you what's going on in each 
part.

Here are the changes we need to make:

    Update the contractAddress in pages/index.js
    Update the name strings to be your own name in pages/index.js
    Ensure that the contract ABI matches your contract in utils/BuyMeACoffee.json

Update contractAddress in pages/index.js

You can see that the contractAddress variable is already populated with an address. This is an example 
contract that I deployed, which you're welcome to use, but if you do... all the tips sent to your 
website will go to my address :)

You can fix this by pasting in your address from when we deployed the BuyMeACoffee.sol smart contract 
earlier.

Ensure that the contract ABI matches in utils/BuyMeACoffee.json

This is also a key thing to check especially when you make changes to your smart contract later on 
(after this tutorial).

The ABI is the application binary interface, which is just a fancy way of telling our frontend code 
what kinds of functions are available to call on the smart contract. The ABI is generated inside a 
json file when the smart contract is compiled. You can find it back in the smart contract folder at 
the path artifacts/contracts/BuyMeACoffee.sol/BuyMeACoffee.json

Whenever you change your smart contract code and re-deploy, your ABI will change as well. Copy that 
over and paste it into the Replit file: utils/BuyMeACoffee.json

Now if the app isn't already running, you can go to the shell and use npm run dev to start a local 
server to test out your changes. The website should load in a few seconds.

```
~/Buy-Me-A-Coffee-DeFi-DApp-Veneh$ npm run dev
```

The awesome thing about Replit is that once you have the website up, you can go back to your profile, 
find the Replit project link, and send that to friends for them to visit your tipping page.

Now let's take a tour through the website and the code. You can already see from the above screenshot 
that when you first visit the dapp, it will check if you have MetaMask installed and whether your 
wallet is connected to the site. The first time you visit, you will not be connected, so a button will 
appear asking you to Connect your wallet.

After you click Connect your wallet, a MetaMask window will pop up asking if you want to confirm the 
connection by signing a message. This message signing does not require any gas fees or costs.

Once the signature is complete, the website will acknowledge your connection and you will be able to 
see the coffee form, as well as any of the previous memos left behind by other visitors.

To recap:

    We used Hardhat and Ethers.js to code, test, and deploy a custom solidity smart contract.
    We deployed the smart contract to the Goerli test network using Alchemy and MetaMask.
    We implemented a withdrawal script to allow us to accept the fruits of our labor.
    We connected a frontend website built with Next.js, React, and Replit to the smart contract by 
    using Ethers.js to load the contract ABI.

That's a LOT!

## Challenge ⚙️

Okay, now time for the best part. I'm going to leave you with some challenges to try on your own, to 
see if you fully understand what you've learned here! (For some guidance, watch the YouTube video 
here).

    Allow your smart contract to update the withdrawal address.

We implement in the Intelligent Contract the necessary changes in order to update the address to which 
the funds can be withdrawn, then we deploy the new contract in the Goerli testnet:

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx 
hardhat run scripts/deploy-upd.js --network goerli
Compiled 1 Solidity file successfully
BuyMeACoffeeUpd deployed to: 0x2451E511a2E34EbD6C345bF0a5c0af833D800604
```
We then verify and publish in the Source Code of the Smart Contract

```
 The Contract Source code for 0x2451E511a2E34EbD6C345bF0a5c0af833D800604 has already been verified.
Click here to view the Verified Contract Source Code
```
Then we run the script to withdraw all the funds from the Smart Contract to the address of the Wallet 
that owns the contract.

```
llabori@Xubuntu64Bits-virtual-machine:~/BlockChains/AlchemyUniversity/2-BuyMeCoffeeDeFidapp$ npx 
hardhat run scripts/withdraw-upd.js
current balance of owner:  1.176838871658965623 ETH
current balance of contract:  0.003 ETH
withdrawing funds..
current balance of owner:  1.179774929554468324 ETH
```

Once you're done with your challenge, tweet about it by tagging @AlchemyLearn on Twitter and using the 
hashtag #roadtoweb3!

And make sure to share your reflections on this project to earn your Proof of Knowledge (PoK) token: 
https://university.alchemy.com/discord

## Built with 🛠️

_Herramientas que utilizaste para crear tu proyectoTools you used to develop the challenge_

- [Visual Studio Code](https://code.visualstudio.com/) - The IDE
- [Replit](https://replit.com) - OnLine IDE for Front End
- [Alchemy](https://dashboard.alchemy.com) - Interface/API to the Goerli Tesnet Network
- [Xubuntu](https://xubuntu.org/) - Operating system based on Ubuntu distribution
- [Goerli Testnet](https://goerli.etherscan.io) - Web system used to verify transactions, verify 
  contracts, deploy contracts, verify and publish contract source code, etc.
- [Solidity](https://soliditylang.org ) Object-oriented programming language for implementing smart 
  contracts on various blockchain platforms
- [Hardhat](https://hardhat.org) - Environment developers use to test, compile, deploy and debug dApps 
  based on the Ethereum blockchain
- [GitHub](https://github.com/) - Internet hosting service for software development and version 
  control using Git
- [Goerli Faucet](https://goerlifaucet.com/) - Faucet used to obtain ETH used in the tests to deploy 
  the SmartContrat as well as to interact with them.
- [MetaMask](https://metamask.io) - MetaMask is a software cryptocurrency wallet used to interact with 
  the Ethereum blockchain.


## Contributing 🖇️

Please read the [CONTRIBUTING.md](https://gist.github.com/llabori-venehsoftw/xxxxxx) for details of our 
code of conduct, and the process for submitting pull requests to us.

## Wiki 📖

N/A

## Versioning 📌

We use [GitHub] for versioning all the files used (https://github.com/tu/proyecto/tags).

## Autores ✒️

_People who collaborated with the development of the challenge_

- **VeneHsoftw** - _Initial Work_ - [venehsoftw](https://github.com/venehsoftw)
- **Luis Labori** - _Initial Work_, _Documentationn_ - [llabori-venehsoftw](https://github.com/
llabori-venehsoftw)

## License 📄

This project is licensed under the License (Your License) - see the file [LICENSE.md](LICENSE.md) for 
details.

## Gratitude 🎁

- If you found the information reflected in this Repo to be of great importance, please extend your 
collaboration by clicking on the star button on the upper right margin. 📢
- If it is within your means, you may extend your donation using the following address: 
`0xAeC4F555DbdE299ee034Ca6F42B83Baf8eFA6f0D`

---

⌨️ con ❤️ por [Venehsoftw](https://github.com/llabori-venehsoftw) 😊
