const hre = require("hardhat");

async function main() {
    const SolarToken = await hre.ethers.getContractFactory("SolarToken");
    const solarToken = await SolarToken.deploy();
    
    await solarToken.deployed();
    console.log("SolarToken deployed to:", solarToken.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
