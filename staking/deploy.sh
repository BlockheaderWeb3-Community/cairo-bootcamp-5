#!/bin/bash

# Deployment script for StarkNet testnet
# Requires starkli and a funded account

# Set your variables
RPC_URL="https://starknet-sepolia.publicnode.com"  # or Testnet2
PRIVATE_KEY="your_private_key_here"
ACCOUNT_ADDRESS="your_account_address_here"

# Build contracts
echo "Building contracts..."
scarb build

# Declare contracts
echo "Declaring StarkToken..."
STARK_TOKEN_CLASS_HASH=$(starkli declare target/dev/cairotask1_StarkToken.contract_class.json --rpc $RPC_URL --account $ACCOUNT_ADDRESS --private-key $PRIVATE_KEY)

echo "Declaring RewardToken..."
REWARD_TOKEN_CLASS_HASH=$(starkli declare target/dev/cairotask1_RewardToken.contract_class.json --rpc $RPC_URL --account $ACCOUNT_ADDRESS --private-key $PRIVATE_KEY)

echo "Declaring Staking..."
STAKING_CLASS_HASH=$(starkli declare target/dev/cairotask1_Staking.contract_class.json --rpc $RPC_URL --account $ACCOUNT_ADDRESS --private-key $PRIVATE_KEY)

# Deploy tokens
INITIAL_SUPPLY=1000000000000000000000  # 1000 * 10^18

echo "Deploying StarkToken..."
STARK_TOKEN_ADDRESS=$(starkli deploy $STARK_TOKEN_CLASS_HASH $INITIAL_SUPPLY $ACCOUNT_ADDRESS --rpc $RPC_URL --account $ACCOUNT_ADDRESS --private-key $PRIVATE_KEY)

echo "Deploying RewardToken..."
REWARD_TOKEN_ADDRESS=$(starkli deploy $REWARD_TOKEN_CLASS_HASH $INITIAL_SUPPLY $ACCOUNT_ADDRESS --rpc $RPC_URL --account $ACCOUNT_ADDRESS --private-key $PRIVATE_KEY)

# Deploy staking contract
echo "Deploying Staking contract..."
STAKING_ADDRESS=$(starkli deploy $STAKING_CLASS_HASH $STARK_TOKEN_ADDRESS $REWARD_TOKEN_ADDRESS --rpc $RPC_URL --account $ACCOUNT_ADDRESS --private-key $PRIVATE_KEY)

echo "Deployment complete!"
echo "StarkToken: $STARK_TOKEN_ADDRESS"
echo "RewardToken: $REWARD_TOKEN_ADDRESS"
echo "Staking: $STAKING_ADDRESS"