// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SolarToken is ERC20 , Ownable {
    uint256 public transactionFee = 1; // 1% fee
    uint256 public burnFee = 2;
    uint256 public mintPercentage = 5;
    mapping(address => bool) public trustedIoTDevices; // Store trusted IoT devices
    uint256 public allEnergyPurchased; // Tracks the total energy purchased in the app
    mapping(address => uint256) public userEnergyPurchased;

    constructor(uint256 initialSupply) ERC20("SolarToken", "SLT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }


    modifier onlyTrustedIoT() {
        require(trustedIoTDevices[msg.sender], "Only trusted IoT devices can mint");
        _;
    }

    mapping(address => uint256) public redeemedEnergy;

    event EnergyPurchased(address indexed buyer, uint256 tokenAmount); //to track energy purchases
    event TokensBurnt(address indexed buyer, uint256 burnAmount);

    // Function to add a trusted IoT device (can be called by owner only)
    function addTrustedIoTDevice(address _iotDevice) external {
        require(msg.sender == owner(), "Only owner can add trusted IoT devices");
        trustedIoTDevices[_iotDevice] = true;
    }

    function removeTrustedIoTDevice(address _iotDevice) external onlyOwner {
    trustedIoTDevices[_iotDevice] = false;
   }   


     function setMintPercentage(uint256 _mintPercentage) external onlyOwner {
        require(_mintPercentage <= 100, "Mint percentage too high"); // Limit max burn percentage
        mintPercentage = _mintPercentage;
    } 

    // Function for IoT devices to mint tokens based on solar energy production
    function mintTokensForEnergy(address producer, uint256 energyProduced) external onlyTrustedIoT {
        require(energyProduced > 0, "Energy produced must be greater than zero");

        // Calculate the amount of tokens to mint based on energy produced
        uint256 tokensToMint = (energyProduced * 10) /100; 
        
        _mint(producer, tokensToMint); // Mint tokens to the producer's address
    }

    function BurnTokens(uint256 tokenAmount) external {
        require( tokenAmount > 9, "Token amount too low"); // Limit max burn percentage
        _burn(msg.sender, tokenAmount);
    }

    function setTransactionFee(uint256 newFee) external onlyOwner {
        require(newFee <= 10, "Fee cannot exceed 10%");
        transactionFee = newFee;
    }

    function transfer(address buyer, uint256 tokenAmount) public override (ERC20) returns (bool) {
        uint256 transactionfeeAmount = (tokenAmount * transactionFee) / 100; //calculationg transaction fee(feeAmount)
        uint256 burnAmount = redeemedEnergy[msg.sender];
        uint256 transferAmount = (tokenAmount - burnAmount - transactionfeeAmount);// final amount of token to be transferred

        _transfer(msg.sender, owner(), transactionfeeAmount); // Transaction fee goes to owner
        _transfer(msg.sender, buyer, transferAmount); //rest of tokens transferred to buyer
        _burn(msg.sender, burnAmount); // Burn the tokens
        
         
        userEnergyPurchased[msg.sender] += tokenAmount; // Track the energy purchase per user
        allEnergyPurchased += tokenAmount;//Update the total energy purchased in the app

        emit EnergyPurchased(msg.sender, tokenAmount);
        emit TokensBurnt(msg.sender, burnAmount);

        return true;
    }

}