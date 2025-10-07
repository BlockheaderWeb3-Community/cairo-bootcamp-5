# StarkNet Staking Contract

A secure and gas-efficient staking smart contract implemented in Cairo for StarkNet. Users can stake the native STRK token and earn rewards in Reward tokens based on their stake share and time.

## Features

### Core Functionality

- **Staking**: Users can stake native STRK tokens to earn rewards
- **Unstaking**: Users can withdraw their staked STRK tokens
- **Reward Distribution**: Fair reward calculation based on stake share and time
- **Reward Claiming**: Users can claim accumulated rewards

### Owner Functions

- **Fund Rewards**: Owner can add rewards to the pool with specified duration
- **Pause/Unpause**: Emergency pause functionality
- **Recover ERC20**: Recover accidentally sent tokens (with restrictions)

### Security Features

- **Pausable**: Contract can be paused in emergencies
- **Access Control**: Owner-only functions
- **Input Validation**: Comprehensive input validation
- **Reentrancy Protection**: Built-in protection against reentrancy attacks

## Architecture

### Reward Calculation

The contract implements a "reward per token stored" mechanism:

- **Reward Rate**: Rewards distributed per second across all stakers
- **Reward Per Token**: Cumulative rewards per staked token
- **User Rewards**: Calculated as: `balance * (rewardPerToken - userRewardPerTokenPaid) + pendingRewards`

### Contracts

- **StakingContract**: Main staking contract
- **STRK Token**: Native StarkNet token for staking (0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d)
- **RewardToken**: ERC20 token for rewards (RWT)

## Installation & Setup

### Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) - Cairo package manager
- [StarkNet Foundry](https://foundry-rs.github.io/starknet-foundry/) - Testing framework

### Build

```bash
scarb build
```

### Test

```bash
snforge test
```

## Usage

### Deploy Contracts

1. Deploy RewardToken contract
2. Deploy StakingContract with RewardToken address (STRK token address is hardcoded)

### Staking Flow

```cairo
// Approve staking contract to spend STRK tokens
strk_token.approve(staking_contract_address, amount);

// Stake STRK tokens
staking_contract.stake(amount);

// Check earned rewards
let rewards = staking_contract.earned(user_address);

// Claim rewards
staking_contract.claim_rewards();

// Unstake tokens
staking_contract.unstake(amount);
```

### Owner Functions

```cairo
// Fund rewards for distribution
staking_contract.fund_rewards(amount, duration);

// Pause staking (emergency)
staking_contract.pause();

// Unpause staking
staking_contract.unpause();

// Recover accidentally sent tokens
staking_contract.recover_erc20(token_address, amount);
```

## API Reference

### IStaking Interface

#### `stake(amount: u256)`

Stake tokens to earn rewards.

#### `unstake(amount: u256)`

Unstake tokens from the contract.

#### `claim_rewards()`

Claim accumulated reward tokens.

#### `earned(account: ContractAddress) -> u256`

Get earned rewards for an account.

#### `balance_of(account: ContractAddress) -> u256`

Get staked balance for an account.

#### `total_supply() -> u256`

Get total staked tokens.

### IOwnerFunctions Interface

#### `fund_rewards(amount: u256, duration: u64)`

Fund reward pool for distribution over specified duration.

#### `pause()`

Pause staking operations.

#### `unpause()`

Resume staking operations.

#### `recover_erc20(token: ContractAddress, amount: u256)`

Recover accidentally sent ERC20 tokens.

## Events

- **Staked**: Emitted when tokens are staked
- **Unstaked**: Emitted when tokens are unstaked
- **RewardPaid**: Emitted when rewards are claimed
- **RewardsFunded**: Emitted when rewards are funded
- **Paused**: Emitted when contract is paused
- **Unpaused**: Emitted when contract is unpaused
- **RecoveredTokens**: Emitted when tokens are recovered

## Security Considerations

### Reward Calculation Security

- Uses checked arithmetic to prevent overflow
- Updates reward calculations before state changes
- Implements reward per token stored pattern for gas efficiency

### Access Control

- Owner-only functions use OpenZeppelin's Ownable component
- Input validation on all public functions
- Pausable functionality for emergency stops

### Token Recovery

- Cannot recover staked STRK tokens while active distribution
- Cannot recover reward tokens
- Only owner can recover tokens

### Gas Optimization

- Efficient reward calculation using cumulative approach
- Minimal storage reads/writes
- Optimized for batch operations

## Testing

The contract includes comprehensive unit tests covering:

- Basic staking/unstaking functionality
- Reward calculation and claiming
- Owner functions (pause, fund rewards, recover tokens)
- Edge cases and error conditions
- Security scenarios

Run tests with:

```bash
snforge test
```

## Deployment

### Local Development

```bash
# Start local StarkNet node
starknet-devnet

# Deploy contracts
# Use deployment script or manual deployment
```

### Testnet Deployment

```bash
# Deploy to Sepolia testnet
# Use StarkNet CLI or wallet interface
```

## License

This project is licensed under the MIT License.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Disclaimer

This contract is provided as-is for educational and demonstration purposes. Always conduct thorough security audits before deploying to production networks.
