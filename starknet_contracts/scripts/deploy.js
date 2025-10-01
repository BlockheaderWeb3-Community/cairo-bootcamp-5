const { starknet } = require("hardhat");
const { ethers } = require("ethers");

async function main() {
  console.log("Deploying Staking Contract...");

  // Get the deployer account
  const [deployer] = await starknet.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy StarkToken
  console.log("Deploying StarkToken...");
  const starkTokenFactory = await starknet.getContractFactory("StarkToken");
  const starkToken = await starkTokenFactory.deploy([deployer.address]);
  await starkToken.deployed();
  console.log("StarkToken deployed to:", starkToken.address);

  // Deploy RewardToken
  console.log("Deploying RewardToken...");
  const rewardTokenFactory = await starknet.getContractFactory("RewardERC20");
  const rewardToken = await rewardTokenFactory.deploy([deployer.address]);
  await rewardToken.deployed();
  console.log("RewardToken deployed to:", rewardToken.address);

  // Deploy StakingContract
  console.log("Deploying StakingContract...");
  const stakingFactory = await starknet.getContractFactory("StakingContract");
  const stakingContract = await stakingFactory.deploy([
    deployer.address,
    starkToken.address,
    rewardToken.address,
  ]);
  await stakingContract.deployed();
  console.log("StakingContract deployed to:", stakingContract.address);

  // Mint some initial tokens for testing
  console.log("Minting initial tokens...");

  // Mint StarkTokens
  await starkToken.invoke("mint", [
    deployer.address,
    ethers.utils.parseEther("10000"),
  ]);
  console.log("Minted 10000 STK tokens to deployer");

  // Mint RewardTokens
  await rewardToken.invoke("mint", [
    deployer.address,
    ethers.utils.parseEther("10000"),
  ]);
  console.log("Minted 10000 RWT tokens to deployer");

  console.log("\nDeployment completed!");
  console.log("StarkToken:", starkToken.address);
  console.log("RewardToken:", rewardToken.address);
  console.log("StakingContract:", stakingContract.address);

  // Save deployment info
  const deploymentInfo = {
    network: starknet.network.name,
    starkToken: starkToken.address,
    rewardToken: rewardToken.address,
    stakingContract: stakingContract.address,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
  };

  console.log("\nDeployment Info:", JSON.stringify(deploymentInfo, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
