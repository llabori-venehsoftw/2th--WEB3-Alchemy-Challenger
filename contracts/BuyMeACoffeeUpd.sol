//SPDX-License-Identifier: Unlicense

// contracts/BuyMeACoffeeUpd.sol
pragma solidity ^0.8.17;

// Switch this to your own contract address once deployed, for bookkeeping!
// Example Contract Address on Goerli: 0xDBa03676a2fBb6711CB652beF5B7416A53c1421D

// Author: @venehsoftw, @llabori
contract BuyMeACoffeeUpd {
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
    
    // Address of contract deployer (Owner). Marked payable so that
    // we can withdraw to this address later. Is possible update the Owner Address
    address payable owner;

    // List of all memos received from coffee purchases.
    Memo[] memos;

    // For prevents reentrancy
    bool internal locked = false;

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
     * @dev Mofifier to: change the Owner Address / Transfer fund / withdrawTips
     * @param _account address for the actual Owner
     */
    modifier onlyBy(address _account) {
      require(msg.sender == _account, "Sender not authorized.");
      // Underscore is a special character only used inside
      // a function modifier and it tells Solidity to
      // execute the rest of the code.
      _;
    }

    /**
     * @dev Mofifier to validate the new Owner. This modifier checks that the address passed in is not the zero address.
     * @param _addr address for the new Owner
     */
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    /**
     * @dev Send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public onlyBy(owner){
        require(!locked);
        locked = true;
        
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // Send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
        // require(owner.send(address(this).balance));
        locked = false;
    }

    /**
     * @dev Function to transfer Ether from this contract to address from input. Only for actual Owner
     * @param _to Address to transfer the Ether
     * @param _amount The amount of Ether to send to the address _to
     */
    function transfer(address payable _to, uint _amount) public onlyBy(owner) validAddress(_to) {
        require(!locked);
        locked = true;

        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
        locked = false;
    }

    /**
     * @dev Change the Owner Address. Only the actual Owner can to change the adddress
     * @param _address address for the new Owner
     */
    function changeOwner(address _address) public onlyBy(owner) validAddress(_address) {
        address _old_addr;
        _old_addr = owner;

        //require(_address == address(0x0), "The Address must be configurated");
        require(_address != _old_addr, "The owner's new address should be different from the current address");
        owner = payable(_address);
        assert(owner != _old_addr);
    }

    /**
     * @dev To see the address for this Contract
     */
    function getContractAddress() public view returns (address) {
        address _myaddress = address(this);     //   Contract address
        return _myaddress;
        }

    /**
     * @dev To see the address for the Owner
     */
    function getAddressOwner() public view returns (address) {
        address _myaddress = owner;             //   Owner address
        return _myaddress;
        }

}