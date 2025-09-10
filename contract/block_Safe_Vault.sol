// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Block Safe Vault - Simplified Version
 * @dev A simple secure vault for storing and managing ETH
 */
contract Project {
    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    
    // State variables
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public totalBalance;
    bool public emergencyStop;
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier notStopped() {
        require(!emergencyStop, "Contract is stopped");
        _;
    }
    
    /**
     * @dev Constructor - Sets the contract deployer as owner
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Core Function 1: Deposit ETH into the vault
     */
    function deposit() external payable notStopped {
        require(msg.value > 0, "Must send ETH");
        
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev Core Function 2: Withdraw ETH from the vault
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external notStopped {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        balances[msg.sender] -= amount;
        totalBalance -= amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    /**
     * @dev Core Function 3: Emergency controls (owner only)
     */
    function emergencyToggle() external onlyOwner {
        emergencyStop = !emergencyStop;
    }
    
    /**
     * @dev Get user's balance
     * @param user Address to check
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    /**
     * @dev Get contract's total ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Change owner (current owner only)
     * @param newOwner New owner address
     */
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        
        address oldOwner = owner;
        owner = newOwner;
        
        emit OwnerChanged(oldOwner, newOwner);
    }
    
    /**
     * @dev Owner can withdraw any amount for emergencies
     * @param amount Amount to withdraw
     */
    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(owner, amount);
    }
    
    /**
     * @dev Receive function to accept direct ETH transfers
     */
    receive() external payable {
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
