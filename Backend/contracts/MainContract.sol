// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISolarToken.sol" ;

contract SolarTokenReward {
    ISolarToken public token; // Use ISolarToken instead of IERC20;
    address public owner;
    uint256 public tokenPerUnit = 1;

     constructor(address _tokenAddress, uint256 _tokensPerUnit) {
        token = ISolarToken(_tokenAddress); //ISolarToken allows minting by IoTDevices
        owner = msg.sender; //the depoyer
        tokenPerUnit = _tokensPerUnit;
    }

    struct Producer{
        uint256 SolarTokenbalance; // Producers EcoToken balance
        address payable producer; //address of solar producers/users
        string username; //username of the users
        address trustedIoTDevice; // IoT device or backend server
        uint256 EnergyProduced; //TEnergy produced at a time in Watts. Tak note 1 unit = 1kWh
        uint256 totalEnergyPurchased;
        uint256 TokenReward; //EcoToken to be rewarded after production period
        uint256 TotalEnergyProduced; //Total amount of energy produced by the user since registration
        bool isRegistered;
    }

    mapping( address => Producer) public SolarTokensDetails; //maps user address to their solar tokens details
    mapping(address => bool) public trustedIoTDevices; // Stores registered IoT devices
    mapping(address => address) public IoTtoProducer; // IoT Device → Producer
    mapping(address => uint256) public userEnergyPurchased;
    mapping(address => uint256) public redeemedEnergy;

    uint256 public producerCounter; //Keeps track of all users in the app
    uint256 public allEnergyPurchased; // Tracks the total energy purchased in the app

    struct SellOrder {
    string username;
    address seller;
    uint256 tokenAmount;
    uint256 pricePerToken;
    }
    SellOrder[] public sellOrders;

  
    event RewardClaimed(address indexed sender, uint256 TokenReward);
    event TokensListed(address indexed seller, uint256 tokenAmount, uint256 pricePerToken);
    event EnergyRedeemed(address indexed user, uint256 tokenAmount);
    event UserRegistered(string username, string password);
    event OrderUpdated(address seller, uint256 tokenAmount);
    event TokensPurchased(address buyer, address seller, uint256 tokenAmount, uint256 totalCost);
    event TokensBurnt(address indexed user, uint256 tokenAmount);


        modifier onlyOwner () {
            require(msg.sender == owner, "Only owner can perform this action");
            _;
        }
            //register users
        function registerUser(string memory username, string memory password) public {
            require(bytes (username).length > 1, "Username can't be empty");
            require(bytes (password).length > 8, "Password is too short");
            require(!SolarTokensDetails[msg.sender].isRegistered, "User is already registered");


            //Registering the user when the require statements are passed
            SolarTokensDetails[msg.sender] = Producer({
                SolarTokenbalance: 0,
                producer: payable(msg.sender),
                username: username,
                trustedIoTDevice:address(0),
                EnergyProduced: 0,
                totalEnergyPurchased: 0,
                TokenReward: 0,
                TotalEnergyProduced: 0,
                isRegistered: true
            });

            emit UserRegistered(
                username,
                password
            );

            producerCounter++;
        }

         function setTrustedIoTDevice( address _iotDevice) public onlyOwner {
           require(_iotDevice != address(0), "Invalid IoT device address");
           trustedIoTDevices[_iotDevice] = true; // Mark the IoT device as trusted
        }

            //links to producers
        function linkIoTDevice(address _iotDevice) public {
        require(SolarTokensDetails[msg.sender].isRegistered, "User not registered");
        require(trustedIoTDevices[_iotDevice], "IoT device is not trusted");

       
        IoTtoProducer[_iotDevice] = msg.sender;// Link device to producer
        }


        function updateTokensPerUnit(uint256 _tokenPerUnit) public onlyOwner {
            tokenPerUnit = _tokenPerUnit;
        }

  
                  //data is gotten from a backend server
        function submitEnergyData(uint256 _energyProduced) public {
             address producer = IoTtoProducer[msg.sender];//Find producer linked to this
             require(producer != address(0), "No producer linked to this device");
             require(SolarTokensDetails[producer].trustedIoTDevice == msg.sender, "Unauthorized IoT device");
             require(_energyProduced > 0, "Energy must be greater than zero");

                 // Store the energy produced
              SolarTokensDetails[producer].EnergyProduced = _energyProduced;

              token.mintTokensForEnergy(producer, _energyProduced);
        }


        function calculateReward( ) public {
            require(SolarTokensDetails[msg.sender].isRegistered, "No such user");
            
            uint256 EnergyProduced = SolarTokensDetails[msg.sender].EnergyProduced;
            uint256 TokenReward = EnergyProduced * tokenPerUnit;
            SolarTokensDetails[msg.sender].TokenReward = TokenReward;//updates the value to the struct so it can be acccesed globally
            SolarTokensDetails[msg.sender].EnergyProduced = 0; //reset energy produced value
            SolarTokensDetails[msg.sender].SolarTokenbalance += TokenReward;
            SolarTokensDetails[msg.sender].TotalEnergyProduced += EnergyProduced;
        }

        function claimReward ( ) public {
            require(SolarTokensDetails[msg.sender].EnergyProduced > 0, "Solar Energy produced must be greater than zero");
            require(SolarTokensDetails[msg.sender].isRegistered, "No such user");

             uint256 rewardAmount = SolarTokensDetails[msg.sender].TokenReward;
            require(rewardAmount > 0, "No reward to claim");
            SolarTokensDetails[msg.sender].TokenReward = 0; // Reset after claiming
     
     
             require(IERC20(address(token)).transfer(msg.sender, rewardAmount), "Token transfer failed"); //use IERC for token transfer


          emit RewardClaimed( msg.sender, rewardAmount);
        }
            
            //producers set their own price and list them on the app
        function listTokensForSale(string memory _username, uint256 _tokenAmount, uint256 _pricePerToken) external {
            require(IERC20(address(token)).balanceOf(msg.sender) >= _tokenAmount, "Not enough tokens to sell");
            require(_tokenAmount > 0 && _pricePerToken > 10, "Invalid amount or price");
            require(msg.sender == SolarTokensDetails[msg.sender].producer, "Not a registered seller");//seller = producer

            IERC20(address(token)).transferFrom(msg.sender,address(this), _tokenAmount);// Lock tokens in contract

            sellOrders.push(SellOrder({
            username: _username,
            seller: msg.sender,
            tokenAmount: _tokenAmount,
            pricePerToken: _pricePerToken
        }));

        emit TokensListed(msg.sender, _tokenAmount, _pricePerToken);
    }

        function buyTokens(uint256 orderIndex, uint256 tokenAmount) public payable {
            require(orderIndex <= sellOrders.length, "Invalid Order Index");

            SellOrder storage order = sellOrders[orderIndex];
            require(tokenAmount > 0 && tokenAmount <= order.tokenAmount, "Invalid token amount");

            uint256 totalCost = tokenAmount * order.pricePerToken;
            order.tokenAmount -= tokenAmount; //reduce the tokenAmount from the total tokens in the order
            

            IERC20(address(token)).transferFrom(address(this), msg.sender, tokenAmount); // transfers/moves tokens to buyer
            payable(order.seller).transfer(totalCost); // payable sends ETH to seller

            require(msg.value == totalCost, "Not enough ETH sent");


            emit TokensPurchased(msg.sender, order.seller, tokenAmount, totalCost);

             userEnergyPurchased[msg.sender] += tokenAmount; // Track the energy purchase per user
             allEnergyPurchased += tokenAmount;//Update the total energy purchased in the app

        // Update the order amount or remove if fully bought
        if (tokenAmount == order.tokenAmount) {
            sellOrders[orderIndex] = sellOrders[sellOrders.length - 1]; // Replace with last element
            sellOrders.pop(); // Remove last element
        } else {
            order.tokenAmount -= tokenAmount;
            emit OrderUpdated(order.seller, order.tokenAmount);
        } 
        }

        function redeemTokensForEnergy(uint256 tokenAmount) external {
           require(IERC20(address(token)).balanceOf(msg.sender) >= tokenAmount, "Not enough tokens");

           IERC20(address(token)).transferFrom(msg.sender, address(this), tokenAmount); //transfer tokens to the address first

            ISolarToken(address(token)).BurnTokens(tokenAmount); // Burn tokens to redeem energy
            redeemedEnergy[msg.sender] += tokenAmount; // Track redeemed energy

            emit EnergyRedeemed(msg.sender, tokenAmount);
            emit TokensBurnt( msg.sender, tokenAmount);
        }

            //allows one to only check their balance
        function checkBalance () external view returns (uint256) {
            require(SolarTokensDetails[msg.sender].isRegistered, "User not registered");
            return SolarTokensDetails[msg.sender].SolarTokenbalance;
        }

        function checkTotalEnergyProduced () external view returns (uint256) {
            require(SolarTokensDetails[msg.sender].isRegistered, "User not registered");
            return SolarTokensDetails[msg.sender].TotalEnergyProduced ;
        }
    }
