#!/bin/bash

# Deployment script for Staking Contract
# Assumes sncast is configured with account and network

# Build the project
scarb build

# Declare the contract
echo "Declaring StakingContract..."
DECLARE_OUTPUT=$(sncast --account mainuser --wait declare --contract-name StakingContract)
CLASS_HASH=$(echo "$DECLARE_OUTPUT" | grep "class_hash:" | awk '{print $2}')

echo "Class hash: $CLASS_HASH"

# Deploy the contract
# Constructor args: owner, staking_token, reward_token
# Replace with actual addresses
OWNER="0x123..."  # Replace with actual owner address
STAKING_TOKEN="0x456..."  # Replace with Stark token address
REWARD_TOKEN="0x789..."  # Replace with RewardToken address

echo "Deploying StakingContract..."
DEPLOY_OUTPUT=$(sncast --account mainuser --wait deploy --class-hash $CLASS_HASH --constructor-args $OWNER $STAKING_TOKEN $REWARD_TOKEN)
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "contract_address:" | awk '{print $2}')

echo "Contract deployed at: $CONTRACT_ADDRESS"