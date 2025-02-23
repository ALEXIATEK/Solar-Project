const hre = require("hardhat");

//deploy MainContract.sol
async function main() {
    const MainContract = await hre.ethers.getContractFactory("MainContract");
    const maincontract = await MainContract.deploy();
    
    await solarToken.deployed();
    console.log("SolarToken deployed to:", maincontract.address);
}

  //Deploy IERC20.sol
  async function main() {
    const IERC20 = await hre.ethers.getContractFactory("IERC20");
    const ierc20 = await IERC20.deploy();
    
    await ierc20.deployed();
    console.log("SolarToken deployed to:", ierc20.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
