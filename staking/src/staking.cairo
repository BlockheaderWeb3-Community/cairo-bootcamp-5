#[starknet::interface]
pub trait IStaking<TContractState> {
    fn stake(ref self: TContractState, amount: u256);
    fn unstake(ref self: TContractState, amount: u256);
    fn claim_rewards(ref self: TContractState);
    fn earned(self: @TContractState, account: starknet::ContractAddress) -> u256;
    fn set_reward_rate(ref self: TContractState, rate: u256);
    fn total_staked(self: @TContractState) -> u256;
    fn reward_rate(self: @TContractState) -> u256;
    fn owner(self: @TContractState) -> starknet::ContractAddress;
    fn user_stakes(self: @TContractState, account: starknet::ContractAddress) -> u256;
}

#[starknet::contract]
mod Staking {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use crate::erc20::IERC20DispatcherTrait;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        stark_token: ContractAddress,
        reward_token: ContractAddress,
        total_staked: u256,
        reward_rate: u256,
        user_stakes: starknet::storage::Map<ContractAddress, u256>,
        user_stake_time: starknet::storage::Map<ContractAddress, u64>,
        user_rewards: starknet::storage::Map<ContractAddress, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Staked: Staked,
        Unstaked: Unstaked,
        RewardPaid: RewardPaid,
        RewardRateSet: RewardRateSet,
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
    pub struct RewardRateSet {
        pub rate: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, stark_token: ContractAddress, reward_token: ContractAddress) {
        self.owner.write(get_caller_address());
        self.stark_token.write(stark_token);
        self.reward_token.write(reward_token);
    }

    #[abi(embed_v0)]
    impl StakingImpl of super::IStaking<ContractState> {
        fn stake(ref self: ContractState, amount: u256) {
            assert(amount > 0, 'Cannot stake 0');
            let caller = get_caller_address();
            self._update_reward(caller);
            self.user_stakes.write(caller, self.user_stakes.read(caller) + amount);
            self.total_staked.write(self.total_staked.read() + amount);
            // Transfer tokens from user to contract
            let stark_token_dispatcher = crate::erc20::IERC20Dispatcher { contract_address: self.stark_token.read() };
            stark_token_dispatcher.transfer_from(caller, starknet::get_contract_address(), amount);
            self.emit(Event::Staked(Staked { user: caller, amount }));
        }

        fn unstake(ref self: ContractState, amount: u256) {
            assert(amount > 0, 'Cannot unstake 0');
            let caller = get_caller_address();
            let user_stake = self.user_stakes.read(caller);
            assert(user_stake >= amount, 'Insufficient staked amount');
            self._update_reward(caller);
            self.user_stakes.write(caller, user_stake - amount);
            self.total_staked.write(self.total_staked.read() - amount);
            // Transfer tokens back to user
            let stark_token_dispatcher = crate::erc20::IERC20Dispatcher { contract_address: self.stark_token.read() };
            stark_token_dispatcher.transfer(caller, amount);
            self.emit(Event::Unstaked(Unstaked { user: caller, amount }));
        }

        fn claim_rewards(ref self: ContractState) {
            let caller = get_caller_address();
            self._update_reward(caller);
            let reward = self.user_rewards.read(caller);
            if reward > 0 {
                self.user_rewards.write(caller, 0);
                let reward_token_dispatcher = crate::erc20::IERC20Dispatcher { contract_address: self.reward_token.read() };
                reward_token_dispatcher.transfer(caller, reward);
                self.emit(Event::RewardPaid(RewardPaid { user: caller, reward }));
            }
        }

        fn earned(self: @ContractState, account: ContractAddress) -> u256 {
            let current_time = get_block_timestamp();
            let stake_time = self.user_stake_time.read(account);
            let stake_amount = self.user_stakes.read(account);
            let time_staked = current_time - stake_time;
            let existing_reward = self.user_rewards.read(account);
            existing_reward + (stake_amount * self.reward_rate.read() * time_staked.into()) / 86400 // daily rewards
        }

        fn set_reward_rate(ref self: ContractState, rate: u256) {
            self._only_owner();
            self.reward_rate.write(rate);
            self.emit(Event::RewardRateSet(RewardRateSet { rate }));
        }

        fn total_staked(self: @ContractState) -> u256 {
            self.total_staked.read()
        }

        fn reward_rate(self: @ContractState) -> u256 {
            self.reward_rate.read()
        }

        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn user_stakes(self: @ContractState, account: ContractAddress) -> u256 {
            self.user_stakes.read(account)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _only_owner(self: @ContractState) {
            assert(get_caller_address() == self.owner.read(), 'Only owner');
        }

        fn _update_reward(ref self: ContractState, account: ContractAddress) {
            let current_reward = self.earned(account);
            self.user_rewards.write(account, current_reward);
            self.user_stake_time.write(account, get_block_timestamp());
        }
    }
}