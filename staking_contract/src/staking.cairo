%lang starknet

use starknet::ContractAddress;
use core::integer::u256;
use starknet::storage::LegacyMap;

#[storage]
struct Storage {
    staking_token: ContractAddress,
    reward_token: ContractAddress,
    stakes: LegacyMap<ContractAddress, u256>,
    rewards: LegacyMap<ContractAddress, u256>,
}

#[contract]
mod StakingContract {
    use super::{Storage};
    use starknet::ContractAddress;
    use core::integer::u256;

    // --------------------------
    // Constructor
    // --------------------------
    #[constructor]
    fn constructor(
        ref self: Storage,
        staking_token: ContractAddress,
        reward_token: ContractAddress
    ) {
        self.staking_token = staking_token;
        self.reward_token = reward_token;
    }

    // --------------------------
    // Public Functions
    // --------------------------

    /// Stake tokens (user should have approved this contract beforehand if needed).
    #[external(v0)]
    fn stake(ref self: Storage, amount: u256) {
        let caller = starknet::get_caller_address();
        assert(amount > 0, 'Amount must be > 0');

        // Update stake balance
        let current_stake = self.stakes.read(caller);
        self.stakes.write(caller, current_stake + amount);

        // For simplicity, reward = 10% of staked amount
        let reward = amount / 10;
        let current_reward = self.rewards.read(caller);
        self.rewards.write(caller, current_reward + reward);
    }

    /// Withdraw staked tokens
    #[external(v0)]
    fn withdraw(ref self: Storage, amount: u256) {
        let caller = starknet::get_caller_address();
        let current_stake = self.stakes.read(caller);
        assert(current_stake >= amount, 'Not enough staked');

        self.stakes.write(caller, current_stake - amount);
    }

    /// Claim rewards (distributes RewardToken)
    #[external(v0)]
    fn claim_rewards(ref self: Storage) {
        let caller = starknet::get_caller_address();
        let reward_amount = self.rewards.read(caller);
        assert(reward_amount > 0, 'No rewards available');

        // Reset rewards before transferring
        self.rewards.write(caller, 0);

        // Call into RewardToken contract to transfer rewards
        starknet::call_contract_syscall(
            self.reward_token,
            'transfer',
            (caller, reward_amount)
        ).unwrap();
    }

    /// View: check stake balance
    #[external(v0)]
    fn get_stake(self: @Storage, user: ContractAddress) -> u256 {
        self.stakes.read(user)
    }

    /// View: check pending rewards
    #[external(v0)]
    fn get_rewards(self: @Storage, user: ContractAddress) -> u256 {
        self.rewards.read(user)
    }
}
