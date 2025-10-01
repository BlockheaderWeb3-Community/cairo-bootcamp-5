# HelloStarknet Contract - Session 5a Assignment

A Starknet smart contract implementing balance management functionality with deployment and testing using sncast.

## 📋 Assignment Overview

This project implements a HelloStarknet contract with the following requirements:
1. Add `set_balance` function to update stored balance
2. Add `reset_balance` function to reset balance to zero
3. Use sncast to transfer STRK tokens to a peer

## 🏗️ Contract Implementation

### Contract Features

- **Balance Management**: Store and manage a global balance
- **User Balances**: Track individual user balances using mapping
- **Event Emission**: Emit events when balance increases
- **Error Handling**: Validate input parameters

### Functions Implemented

#### `set_balance(new_balance: felt252)`
- Updates the stored balance to the specified value
- Takes a `new_balance` parameter of type `felt252`
- Writes the new value directly to storage

#### `reset_balance()`
- Resets the stored balance back to zero
- No parameters required
- Sets balance to 0 in storage

#### `increase_balance(amount: felt252)`
- Increases both global and user-specific balances
- Validates that amount is not zero
- Emits `BalanceIncreased` event
- Updates caller's individual balance

#### `get_balance() -> felt252`
- Returns the current global balance
- Read-only function (view function)

## 🚀 Deployment Information

### Network Details
- **Network**: Starknet Sepolia Testnet
- **RPC**: Built-in sepolia network provider

### Contract Addresses
- **Class Hash**: `0xad0bddc52926250ea25690b0e44840783a6cd05398149dbadd81e96d960a08`
- **Contract Address**: `0x0130f1c796ec76a7aacd263ba58d7f5b723913320ec45173e4c0a71dede2a5f7`

### Deployment Transactions
- **Declaration**: `0x70f2cc55cc91ae8ad9b443b2e1a669867dd62f3fd1c7c456e9d601bdf689039`
- **Deployment**: `0x07970644f6d22ec33a4b0e976fa471a825fdd2d16a18241580edc09c2198e21`

## 🧪 Testing Results

### Function Testing

#### Initial Balance Check
```bash
sncast call --contract-address 0x0130f1c796ec76a7aacd263ba58d7f5b723913320ec45173e4c0a71dede2a5f7 --function "get_balance" --network sepolia
```
**Result**: `0x0` (Balance starts at 0)

#### Testing `set_balance` Function
```bash
sncast invoke --contract-address 0x0130f1c796ec76a7aacd263ba58d7f5b723913320ec45173e4c0a71dede2a5f7 --function "set_balance" --arguments "100" --network sepolia
```
- **Transaction Hash**: `0x072f1819626ba9b54671f085cf2908564867b9494a4523cb20b3210db3a11fb4`
- **Result**: Successfully set balance to 100

#### Verification After Set
```bash
sncast call --contract-address 0x0130f1c796ec76a7aacd263ba58d7f5b723913320ec45173e4c0a71dede2a5f7 --function "get_balance" --network sepolia
```
**Result**: `0x64` (100 in hexadecimal)

#### Testing `reset_balance` Function
```bash
sncast invoke --contract-address 0x0130f1c796ec76a7aacd263ba58d7f5b723913320ec45173e4c0a71dede2a5f7 --function "reset_balance" --network sepolia
```
- **Transaction Hash**: `0x0711359975523838faba2687018f2964c843e698508c70514866dee2fb707a02`
- **Result**: Successfully reset balance to 0

#### Final Verification
```bash
sncast call --contract-address 0x0130f1c796ec76a7aacd263ba58d7f5b723913320ec45173e4c0a71dede2a5f7 --function "get_balance" --network sepolia
```
**Result**: `0x0` (Balance successfully reset to 0)

## 💰 STRK Token Transfer

### Transfer Details
- **STRK Contract**: `0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d`
- **Recipient**: `0x039ae56ab233b40981b527523f6d833433652d6f0203a1ea5781ff8249122259`
- **Amount**: 10 STRK tokens (10,000,000,000,000,000,000 wei)

### Transfer Command
```bash
sncast invoke --contract-address 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d --network sepolia --function "transfer" --calldata 0x039ae56ab233b40981b527523f6d833433652d6f0203a1ea5781ff8249122259 0x8ac7230489e80000 0x0
```

### Transfer Result
- **Transaction Hash**: `0x07c2d24b3d0a00309d5c889d8540ebd5c8b85fec5c0a79cfc487346a3ee2c6e1`
- **Status**: ✅ Success
- **Explorer**: [View on Starkscan](https://sepolia.starkscan.co/tx/0x07c2d24b3d0a00309d5c889d8540ebd5c8b85fec5c0a79cfc487346a3ee2c6e1)

## 🛠️ Development Commands

### Build the Contract
```bash
scarb build
```

### Declare the Contract
```bash
sncast declare --contract-name HelloStarknet --network sepolia
```

### Deploy the Contract
```bash
sncast deploy --class-hash <CLASS_HASH> --network sepolia
```

### Call Functions (Read-only)
```bash
sncast call --contract-address <CONTRACT_ADDRESS> --function "get_balance" --network sepolia
```

### Invoke Functions (State-changing)
```bash
sncast invoke --contract-address <CONTRACT_ADDRESS> --function "set_balance" --arguments "100" --network sepolia
```


## ✅ Assignment Completion Status

- [x] **Task 1**: Implement `set_balance` function
- [x] **Task 2**: Implement `reset_balance` function  
- [x] **Task 3**: Transfer STRK tokens using sncast
- [x] **Testing**: All functions tested successfully
- [x] **Documentation**: Complete project documentation

## 🔗 Useful Links

- [Contract on Starkscan](https://sepolia.starkscan.co/contract/0x0130f1c796ec76a7aacd263ba58d7f5b723913320ec45173e4c0a71dede2a5f7)
- [Declaration Transaction](https://sepolia.starkscan.co/tx/0x70f2cc55cc91ae8ad9b443b2e1a669867dd62f3fd1c7c456e9d601bdf689039)
- [Deployment Transaction](https://sepolia.starkscan.co/tx/0x07970644f6d22ec33a4b0e976fa471a825fdd2d16a18241580edc09c2198e21)
- [STRK Transfer Transaction](https://sepolia.starkscan.co/tx/0x07c2d24b3d0a00309d5c889d8540ebd5c8b85fec5c0a79cfc487346a3ee2c6e1)

## 📝 Notes

- All functions work as expected and have been thoroughly tested
- The contract successfully compiles and deploys on Starknet Sepolia
- STRK token transfer completed successfully to peer address
- Contract uses proper Cairo syntax and follows Starknet best practices
- Events are properly implemented for balance increase operations
