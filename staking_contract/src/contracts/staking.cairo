#[starknet::contract]
pub mod StakingContract {
    use starknet::ContractAddress;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        Map,
    };
    use starknet::{get_caller_address, get_block_timestamp};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Pausable
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    // ReentrancyGuard
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        reentrancy_guard: ReentrancyGuardComponent::Storage,
        staking_token: ContractAddress,
        reward_token: ContractAddress,
        total_staked: u256,
        reward_rate: u256,
        last_update_time: u64,
        user_stake_balance: Map<ContractAddress, u256>,
        user_stake_duration: Map<ContractAddress, u64>,
        user_reward_paid: Map<ContractAddress, u256>,
        rewards: Map<ContractAddress, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        Staked: Staked,
        Unstaked: Unstaked,
        RewardPaid: RewardPaid,
        RewardsFunded: RewardsFunded,
        RecoveredTokens: RecoveredTokens,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Staked {
        pub user: ContractAddress,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Unstaked {
        pub user: ContractAddress,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RewardPaid {
        pub user: ContractAddress,
        pub reward: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RewardsFunded {
        pub amount: u256,
        pub reward_multiplier: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RecoveredTokens {
        pub token: ContractAddress,
        pub amount: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        staking_token: ContractAddress,
        reward_token: ContractAddress,
    ) {
        self.ownable.initializer(owner);
        self.staking_token.write(staking_token);
        self.reward_token.write(reward_token);
        self.last_update_time.write(get_block_timestamp());
    }

    #[abi(embed_v0)]
    impl StakingImpl of crate::interfaces::IStaking::IStaking<ContractState> {
        fn stake(ref self: ContractState, amount: u256, duration: u64) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();
            assert(amount > 0, 'Amount must be > 0');
            assert(duration > 0, 'Duration must be > 0');  

            let caller = get_caller_address();

            let staking_token = IERC20Dispatcher { contract_address: self.staking_token.read() };
            let allowance = staking_token.allowance(caller, starknet::get_contract_address());
            assert(allowance >= amount, 'Insufficient allowance');

            let balance = self.user_stake_balance.read(caller);
            let block_time = get_block_timestamp();
            let  reward = self._calculate_reward(amount, duration);

            self.user_stake_duration.write(caller, block_time + duration);
            self.user_stake_balance.write(caller, balance + amount);
            self.total_staked.write(self.total_staked.read() + amount);
            self.rewards.write(caller, reward);

            let success = staking_token.transfer_from(caller, starknet::get_contract_address(), amount);
            assert(success, 'Transfer failed');

            self.emit(Event::Staked(Staked { user: caller, amount }));

            self.reentrancy_guard.end();
        }

        fn unstake(ref self: ContractState, amount: u256) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();
            assert(amount > 0, 'Amount must be > 0');

            let caller = get_caller_address();
            let balance = self.user_stake_balance.read(caller);
            let duration = self.user_stake_duration.read(caller);
            let block_time = get_block_timestamp() ;
            assert(balance >= amount, 'Insufficient balance');
            assert(block_time <= duration, 'Staking period has not ended');

            let staking_token = IERC20Dispatcher { contract_address: self.staking_token.read() };
            let success = staking_token.transfer(caller, amount);
            assert(success, 'Transfer failed');

            self.user_stake_balance.write(caller, balance - amount);
            self.total_staked.write(self.total_staked.read() - amount);
            self.user_stake_duration.write(caller,0);

            self.emit(Event::Unstaked(Unstaked { user: caller, amount }));

            self.reentrancy_guard.end();
        }

        fn claim_rewards(ref self: ContractState) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();

            let caller = get_caller_address();
            let reward = self.rewards.read(caller);
            assert(reward > 0, 'No rewards to claim');

            self.rewards.write(caller, 0);
            self.user_reward_paid.write(caller, self.user_reward_paid.read(caller) + reward);

            let reward_token = IERC20Dispatcher { contract_address: self.reward_token.read() };
            let success = reward_token.transfer(caller, reward);
            assert(success, 'Transfer failed');

            self.emit(Event::RewardPaid(RewardPaid { user: caller, reward }));
            

            self.reentrancy_guard.end();
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.user_stake_balance.read(account)
        }

        fn duration_of(self: @ContractState, account: ContractAddress) -> u64 {
            self.user_stake_duration.read(account)
        }

        fn earned(self: @ContractState, account: ContractAddress) -> u256 {
            let rewards_paid = self.user_reward_paid.read(account);
            let rewards_owed = self.rewards.read(account);

            rewards_paid + rewards_owed
        }

        fn total_staked(self: @ContractState) -> u256 {
            self.total_staked.read()
        }

        fn reward_rate(self: @ContractState) -> u256 {
            self.reward_rate.read()
        }


        fn last_update_time(self: @ContractState) -> u64 {
            self.last_update_time.read()
        }

        fn fund_rewards(ref self: ContractState, amount: u256, reward_multiplier: u64) {
            self.ownable.assert_only_owner();
            assert(amount > 0, 'Amount must be > 0');
            assert!(reward_multiplier > 0 && reward_multiplier <= 50, "Reward multiplier must be > 0 and less tham 50"); //max 5%

            let reward_token = IERC20Dispatcher { contract_address: self.reward_token.read() };
            let caller = get_caller_address();
            let allowance = reward_token.allowance(caller, starknet::get_contract_address());
            assert(allowance >= amount, 'Insufficient allowance');


            let success = reward_token.transfer_from(caller, starknet::get_contract_address(), amount);
            assert(success, 'Transfer failed');

            let reward_mult = reward_multiplier / 1_000_u64; //max 5%
            self.reward_rate.write(reward_mult.into());

            let current_time = get_block_timestamp();
            self.last_update_time.write(current_time);

            self.emit(Event::RewardsFunded(RewardsFunded { amount, reward_multiplier }));
        }

        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
        }

        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
        }

        fn recover_erc20(ref self: ContractState, token: ContractAddress, amount: u256) {
            self.ownable.assert_only_owner();
            assert(token != self.staking_token.read(), 'Cannot recover staking token');
            assert(token != self.reward_token.read(), 'Cannot recover reward token');

            let erc20 = IERC20Dispatcher { contract_address: token };
            let success = erc20.transfer(get_caller_address(), amount);
            assert(success, 'Transfer failed');

            self.emit(Event::RecoveredTokens(RecoveredTokens { token, amount }));
        }

        fn paused(self: @ContractState) -> bool {
            self.pausable.is_paused()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {

        fn _calculate_reward(self: @ContractState, amount: u256, duration: u64) -> u256 {
            amount * duration.into() * self.reward_rate.read()
        }
    }
}