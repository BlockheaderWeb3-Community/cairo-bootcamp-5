# Staking Contract

A secure staking smart contract in Cairo for Starknet, allowing users to stake ERC20 tokens and earn rewards proportionally based on stake share and time.

## Features

- **Staking**: Users can stake Stark tokens (ERC20) by calling `stake(amount)`.
- **Unstaking**: Users can unstake their tokens with `unstake(amount)`.
- **Rewards**: Rewards are accrued in a separate RewardToken ERC20, distributed proportionally to staked balances over time.
- **Reward Distribution**: Uses per-second reward rate, updated when funding rewards.
- **Security**: Implements reentrancy guard, checks-effects-interactions pattern, and access controls.
- **Owner Functions**: Fund rewards, pause/unpause, recover ERC20 tokens (with restrictions).

## Design Choices

### Reward Calculation

The contract uses a "reward per token stored" mechanism with per-second reward rate:

- `reward_rate`: Total rewards distributed per second.
- `reward_per_token_stored`: Cumulative rewards per staked token.
- `user_reward_per_token_paid`: Tracks rewards already paid to user.
- `rewards`: Pending rewards for user.

When rewards are funded with `fund_rewards(amount, duration)`, the `reward_rate` is set to `amount / duration`.

On each action (stake, unstake, claim), rewards are updated:

```
reward_per_token += (time_elapsed * reward_rate) / total_staked
user_rewards += balance * (reward_per_token - user_reward_per_token_paid)
```

This ensures fair distribution proportional to stake amount and time.

### Security Measures

- **Reentrancy Protection**: Uses OpenZeppelin's ReentrancyGuard component.
- **Checks-Effects-Interactions**: All checks first, then state changes, then external calls.
- **ERC20 Approvals**: Proper use of `transfer_from` for staking and reward funding.
- **Access Control**: Owner-only functions use Ownable component.
- **Pausable**: Emergency pause functionality.
- **Gas Efficiency**: Minimizes storage writes, uses efficient data structures.

### Edge Cases

- **Zero Staking**: Reverts with "Amount must be > 0".
- **Insufficient Balance**: Unstaking more than staked reverts.
- **No Rewards**: Claiming with no accrued rewards succeeds but pays zero.
- **Rounding**: Integer division may cause small rounding errors; rewards are floored.
- **Leftover Rewards**: After distribution period, any remaining rewards stay in contract until recovered by owner.
- **Token Recovery**: Cannot recover staked or reward tokens during active distribution.

## Installation

```bash
scarb build
```

## Testing

Run tests with Starknet Foundry:

```bash
snforge test
```

### Test Cases

1. **Staking Basics**: Verifies balance updates and events.
2. **Unstaking**: Checks principal return and balance updates.
3. **Reward Accrual**: Funds rewards, advances time, verifies earned amounts.
4. **Multiple Stakers**: Tests proportional rewards for different stake amounts and times.
5. **Claiming**: Ensures correct reward transfer and events.
6. **Edge Cases**: Zero amounts, insufficient balance, no rewards.
7. **Security**: Reentrancy prevention, owner-only access.

Test Results: All tests pass, covering the minimum requirements and additional security checks.

## Deployment

Use the provided script:

```bash
./scripts/deploy.sh
```

Update the script with actual token addresses and account details.

## Usage

### Staking

```cairo
staking_contract.stake(amount);
```

### Claiming Rewards

```cairo
staking_contract.claim_rewards();
```

### Funding Rewards (Owner)

```cairo
staking_contract.fund_rewards(amount, duration);
```

## Dependencies

- Starknet 2.8.4
- OpenZeppelin Cairo Contracts 0.16.0

## License

MIT