#[starknet::contract]
mod Staking {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use test::interfaces::IStaking::IStaking;
    use test::types::StakeDetails;
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
        duration: u64,
        // Reward distribution state
        reward_rate: u256, // rewards per second
        reward_per_token_stored: u256, // cumulative reward per token
        last_update_time: u64, // last time reward_per_token_stored was updated
        period_finish: u64, // end time of current reward period
        // User state
        user_reward_per_token_paid: Map<ContractAddress, u256>, // reward per token paid to user
        rewards: Map<ContractAddress, u256>, // pending rewards for user
        balances: Map<ContractAddress, u256>, // staked balances
        stake_count: u256,
        stakes: Map<u256, StakeDetails>,
        // Global state
        total_supply: u256 // total staked tokens
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


    #[constructor]
    fn constructor(
        ref self: ContractState, reward_token: ContractAddress, stark_token: ContractAddress,
    ) {
        self.stark_token.write(stark_token);
        self.reward_token.write(reward_token);
    }

    #[abi(embed_v0)]
    impl StakingImpl of IStaking<ContractState> {
        /// Stake tokens to earn rewards
        fn stake(ref self: ContractState, amount: u256, duration: u64) -> u256 {
            assert(amount > 0, 'Amount must be > 0');

            let caller = get_caller_address();

            let id = self.stake_count.read() + 1;

            // Transfer tokenget_block_timestamps from user to contract
            let stark_token = IERC20Dispatcher { contract_address: self.stark_token.read() };
            stark_token.transfer_from(caller, get_contract_address(), amount);

            // Update user balance and total supply
            let current_balance = self.balances.read(caller);
            self.balances.write(caller, current_balance - amount);
            let current_total = self.total_supply.read();
            self.total_supply.write(current_total + amount);

            let stake_details = StakeDetails { id, owner: caller, duration, amount, valid: true };

            self.stakes.write(id, stake_details);
            self.stake_count.write(id);

            self.emit(Staked { user: caller, amount });

            id
        }

        fn get_stake_details(self: @ContractState, id: u256) -> StakeDetails {
            let stake = self.stakes.read(id);
            stake
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
            self.balances.write(caller, current_balance + amount);
            let current_total = self.total_supply.read();
            self.total_supply.write(current_total - amount);

            // Transfer tokens back to user
            let stark_token = IERC20Dispatcher { contract_address: self.stark_token.read() };
            stark_token.transfer(caller, amount);

            self.emit(Unstaked { user: caller, amount });
        }

        fn get_strk_address(self: @ContractState) -> ContractAddress {
            self.stark_token.read()
        }
        fn get_reward_address(self: @ContractState) -> ContractAddress {
            self.reward_token.read()
        }


        /// Claim accumulated rewards
        fn claim_rewards(ref self: ContractState) {
            let caller = get_caller_address();

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

                self.reward_per_token_stored.read()
                    + (reward_rate * time_diff.into() * 1_000_000_000_000_000_000) / total_supply
            }
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
                self
                    .rewards
                    .write(
                        account,
                        balance * (reward_per_token - user_paid) / 1_000_000_000_000_000_000
                            + self.rewards.read(account),
                    );
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
