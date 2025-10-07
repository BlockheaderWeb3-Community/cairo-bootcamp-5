use starknet::ContractAddress;

#[starknet::contract]
mod staking_contract {
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};
    use starknet::storage::{Map, StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess, StorageMapWriteAccess};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Pausable Mixin
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,

        // ERC20 token addresses
        stark_token: ContractAddress,
        reward_token: ContractAddress,

        // Reward distribution state
        reward_rate: u256, // rewards per second
        reward_per_token_stored: u256, // cumulative reward per token
        last_update_time: u64, // last time reward_per_token_stored was updated
        period_finish: u64, // end time of current reward period

        // User state
        user_reward_per_token_paid: Map<ContractAddress, u256>, // reward per token paid to user
        rewards: Map<ContractAddress, u256>, // pending rewards for user
        balances: Map<ContractAddress, u256>, // staked balances

        // Global state
        total_supply: u256, // total staked tokens
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,

        Staked: Staked,
        Unstaked: Unstaked,
        RewardPaid: RewardPaid,
        RewardsFunded: RewardsFunded,
        RecoveredTokens: RecoveredTokens,
    }

    #[derive(Drop, starknet::Event)]
    struct Staked {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Unstaked {
        #[key]
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardPaid {
        #[key]
        user: ContractAddress,
        reward: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardsFunded {
        amount: u256,
        duration: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct RecoveredTokens {
        token: ContractAddress,
        amount: u256,
        #[key]
        to: ContractAddress,
    }

    // Interfaces
    #[starknet::interface]
    trait IStaking<TContractState> {
        fn stake(ref self: TContractState, amount: u256);
        fn unstake(ref self: TContractState, amount: u256);
        fn claim_rewards(ref self: TContractState);
        fn earned(self: @TContractState, account: ContractAddress) -> u256;
        fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
        fn total_supply(self: @TContractState) -> u256;
        fn last_time_reward_applicable(self: @TContractState) -> u64;
        fn reward_per_token(self: @TContractState) -> u256;
    }

    #[starknet::interface]
    trait IOwnerFunctions<TContractState> {
        fn fund_rewards(ref self: TContractState, amount: u256, duration: u64);
        fn pause(ref self: TContractState);
        fn unpause(ref self: TContractState);
        fn recover_erc20(ref self: TContractState, token: ContractAddress, amount: u256);
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        reward_token: ContractAddress,
    ) {
        self.ownable.initializer(owner);
        self.stark_token.write(0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d.try_into().unwrap());
        self.reward_token.write(reward_token);
        self.last_update_time.write(get_block_timestamp());
    }

    #[abi(embed_v0)]
    impl StakingImpl of IStaking<ContractState> {
        /// Stake tokens to earn rewards
        fn stake(ref self: ContractState, amount: u256) {
            self.pausable.assert_not_paused();
            assert(amount > 0, 'Amount must be > 0');

            let caller = get_caller_address();
            self.update_reward(caller);

            // Transfer tokens from user to contract
            let stark_token = IERC20Dispatcher { contract_address: self.stark_token.read() };
            stark_token.transfer_from(caller, get_contract_address(), amount);

            // Update user balance and total supply
            let current_balance = self.balances.read(caller);
            self.balances.write(caller, current_balance + amount);
            let current_total = self.total_supply.read();
            self.total_supply.write(current_total + amount);

            self.emit(Staked { user: caller, amount });
        }

        /// Unstake tokens
        fn unstake(ref self: ContractState, amount: u256) {
            self.pausable.assert_not_paused();
            assert(amount > 0, 'Amount must be > 0');

            let caller = get_caller_address();
            let current_balance = self.balances.read(caller);
            assert(current_balance >= amount, 'Insufficient balance');

            self.update_reward(caller);

            // Update user balance and total supply
            self.balances.write(caller, current_balance - amount);
            let current_total = self.total_supply.read();
            self.total_supply.write(current_total - amount);

            // Transfer tokens back to user
            let stark_token = IERC20Dispatcher { contract_address: self.stark_token.read() };
            stark_token.transfer(caller, amount);

            self.emit(Unstaked { user: caller, amount });
        }

        /// Claim accumulated rewards
        fn claim_rewards(ref self: ContractState) {
            let caller = get_caller_address();
            self.update_reward(caller);

            let reward = self.rewards.read(caller);
            assert(reward > 0, 'No rewards to claim');

            self.rewards.write(caller, 0);

            // Transfer reward tokens to user
            let reward_token = IERC20Dispatcher { contract_address: self.reward_token.read() };
            reward_token.transfer(caller, reward);

            self.emit(RewardPaid { user: caller, reward });
        }

        /// Get earned rewards for an account
        fn earned(self: @ContractState, account: ContractAddress) -> u256 {
            let balance = self.balances.read(account);
            let reward_per_token = self.reward_per_token();
            let user_paid = self.user_reward_per_token_paid.read(account);
            let pending = self.rewards.read(account);

            balance * (reward_per_token - user_paid) / 1_000_000_000_000_000_000 + pending
        }

        /// Get staked balance for an account
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        /// Get total staked tokens
        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        /// Get last time reward was applicable
        fn last_time_reward_applicable(self: @ContractState) -> u64 {
            let current_time = get_block_timestamp();
            let finish = self.period_finish.read();
            if current_time < finish {
                current_time
            } else {
                finish
            }
        }

        /// Get current reward per token
        fn reward_per_token(self: @ContractState) -> u256 {
            let total_supply = self.total_supply.read();
            if total_supply == 0 {
                self.reward_per_token_stored.read()
            } else {
                let last_time = self.last_time_reward_applicable();
                let last_update = self.last_update_time.read();
                let time_diff = last_time - last_update;
                let reward_rate = self.reward_rate.read();

                self.reward_per_token_stored.read() + (reward_rate * time_diff.into() * 1_000_000_000_000_000_000) / total_supply
            }
        }
    }

    #[abi(embed_v0)]
    impl OwnerFunctions of IOwnerFunctions<ContractState> {
        /// Fund rewards for distribution over a period
        fn fund_rewards(ref self: ContractState, amount: u256, duration: u64) {
            self.ownable.assert_only_owner();
            assert(amount > 0, 'Amount must be > 0');
            assert(duration > 0, 'Duration must be > 0');

            self.update_reward_per_token_stored();

            let current_time = get_block_timestamp();
            let reward_rate = amount / duration.into();

            // If there's an ongoing period, add to it
            let period_finish = self.period_finish.read();
            if current_time < period_finish {
                let remaining = period_finish - current_time;
                let leftover = remaining.into() * self.reward_rate.read();
                self.reward_rate.write(leftover / duration.into() + reward_rate);
            } else {
                self.reward_rate.write(reward_rate);
            }

            self.last_update_time.write(current_time);
            self.period_finish.write(current_time + duration);

            // Transfer reward tokens to contract
            let reward_token = IERC20Dispatcher { contract_address: self.reward_token.read() };
            reward_token.transfer_from(get_caller_address(), get_contract_address(), amount);

            self.emit(RewardsFunded { amount, duration });
        }

        /// Pause staking operations
        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
        }

        /// Unpause staking operations
        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
        }

        /// Recover accidentally sent tokens (cannot recover staked or reward tokens)
        fn recover_erc20(ref self: ContractState, token: ContractAddress, amount: u256) {
            self.ownable.assert_only_owner();
            assert(token != self.stark_token.read(), 'Cannot recover staked token');
            assert(token != self.reward_token.read(), 'Cannot recover reward token');

            let token_dispatcher = IERC20Dispatcher { contract_address: token };
            token_dispatcher.transfer(self.ownable.owner(), amount);

            self.emit(RecoveredTokens { token, amount, to: self.ownable.owner() });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Update reward for a specific account
        fn update_reward(ref self: ContractState, account: ContractAddress) {
            let reward_per_token = self.reward_per_token();
            self.reward_per_token_stored.write(reward_per_token);
            self.last_update_time.write(self.last_time_reward_applicable());

            let zero_address = 0.try_into().unwrap();
            if account != zero_address {
                let balance = self.balances.read(account);
                let user_paid = self.user_reward_per_token_paid.read(account);
                self.rewards.write(account, balance * (reward_per_token - user_paid) / 1_000_000_000_000_000_000 + self.rewards.read(account));
                self.user_reward_per_token_paid.write(account, reward_per_token);
            }
        }

        /// Update global reward per token stored
        fn update_reward_per_token_stored(ref self: ContractState) {
            let reward_per_token = self.reward_per_token();
            self.reward_per_token_stored.write(reward_per_token);
            self.last_update_time.write(self.last_time_reward_applicable());
        }
    }
}