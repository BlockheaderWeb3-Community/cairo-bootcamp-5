use snforge_std::{declare, DeclareResultTrait, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address, start_cheat_block_timestamp, stop_cheat_block_timestamp, EventSpy, EventSpyAssertionsTrait, spy_events};
use starknet::ContractAddress;
use starknet::contract_address_const;
use staking_contract::interfaces::IStaking::{IStakingDispatcher, IStakingDispatcherTrait};
// use openzeppelin::token::erc20::{ERC20Component, interface::{IERC20Dispatcher, IERC20DispatcherTrait}};

// use staking_contract::contracts::rewardToken::RewardToken;
use staking_contract::contracts::staking::StakingContract;

    // Mock ERC20 for testing
    #[starknet::interface]
    trait IMockERC20<TContractState> {
        fn total_supply(self: @TContractState) -> u256;
        fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
        fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
        fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
        fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
        fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;

        fn name(self: @TContractState) -> ByteArray;
        fn symbol(self: @TContractState) -> ByteArray;
        fn decimals(self: @TContractState) -> u8;

        fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    }

    #[starknet::contract]
    mod MockERC20 {
        use starknet::event::EventEmitter;
        use starknet::{ContractAddress, get_caller_address};
        use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, Map, StoragePathEntry};
        use core::num::traits::Zero;

        #[storage]
        pub struct Storage {
            balances: Map<ContractAddress, u256>,
            allowances: Map<(ContractAddress, ContractAddress), u256>, // Mapping<(owner, spender), amount>
            token_name: ByteArray,
            symbol: ByteArray,
            decimal: u8,
            total_supply: u256,
            owner: ContractAddress,
        }

        #[event]
        #[derive(Drop, starknet::Event)]
        pub enum Event {
            Transfer: Transfer,
            Approval: Approval,
        }

        #[derive(Drop, starknet::Event)]
        pub struct Transfer {
            #[key]
            from: ContractAddress,
            #[key]
            to: ContractAddress,
            amount: u256,
        }

        #[derive(Drop, starknet::Event)]
        pub struct Approval {
            #[key]
            owner: ContractAddress,
            #[key]
            spender: ContractAddress,
            value: u256
        }

        #[constructor]
        fn constructor(ref self: ContractState, name: ByteArray, symbol: ByteArray, decimals: u8, owner: ContractAddress) {
            self.token_name.write(name);
            self.symbol.write(symbol);
            self.decimal.write(decimals);
            self.owner.write(owner);
        }

        #[abi(embed_v0)]
        impl MockERC20Impl of super::IMockERC20<ContractState> {
            fn total_supply(self: @ContractState) -> u256 {
                self.total_supply.read()
            }

            fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
                let balance = self.balances.entry(account).read();

                balance
            }

            fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
                let allowance = self.allowances.entry((owner, spender)).read();

                allowance
            }

            fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
                let sender = get_caller_address();

                let sender_prev_balance = self.balances.entry(sender).read();
                let recipient_prev_balance = self.balances.entry(recipient).read();

                assert(sender_prev_balance >= amount, 'Insufficient amount');

                self.balances.entry(sender).write(sender_prev_balance - amount);
                self.balances.entry(recipient).write(recipient_prev_balance + amount);

                assert(self.balances.entry(recipient).read() > recipient_prev_balance, 'Transaction failed');

                self.emit(Transfer { from: sender, to: recipient, amount });

                true
            }

            fn transfer_from(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool {
                let spender = get_caller_address();

                let spender_allowance = self.allowances.entry((sender, spender)).read();
                let sender_balance = self.balances.entry(sender).read();
                let recipient_balance = self.balances.entry(recipient).read();

                assert(amount <= spender_allowance, 'amount exceeds allowance');
                assert(amount <= sender_balance, 'amount exceeds balance');

                self.allowances.entry((sender, spender)).write(spender_allowance - amount);
                self.balances.entry(sender).write(sender_balance - amount);
                self.balances.entry(recipient).write(recipient_balance + amount);

                self.emit(Transfer { from: sender, to: recipient, amount });

                true
            }

            fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
                let caller = get_caller_address();

                self.allowances.entry((caller, spender)).write(amount);

                self.emit(Approval { owner: caller, spender, value: amount });

                true
            }

            fn name(self: @ContractState) -> ByteArray {
                self.token_name.read()
            }

            fn symbol(self: @ContractState) -> ByteArray {
                self.symbol.read()
            }

            fn decimals(self: @ContractState) -> u8 {
                self.decimal.read()
            }

            fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
                let previous_total_supply = self.total_supply.read();
                let previous_balance = self.balances.entry(recipient).read();

                self.total_supply.write(previous_total_supply + amount);
                self.balances.entry(recipient).write(previous_balance + amount);

                let zero_address = Zero::zero();

                self.emit(Transfer { from: zero_address, to: recipient, amount });

                true
            }
        }
    }
    

fn deploy_mock_erc20( ) -> (IMockERC20Dispatcher, IMockERC20Dispatcher, ContractAddress) {
    let contract = declare("MockERC20").unwrap().contract_class();
    let mut staking_constructor_args = array![];

    let owner = contract_address_const::<'owner'>();
    let name: ByteArray = "Staking Name";
    let symbol: ByteArray = "STK";
    let decimals: u8 = 6;

    name.serialize(ref staking_constructor_args);
    symbol.serialize(ref staking_constructor_args);
    decimals.serialize(ref staking_constructor_args);
    owner.serialize(ref staking_constructor_args);

    let (contract_address, _) = contract.deploy(@staking_constructor_args).unwrap();
    let stake_dispatcher = IMockERC20Dispatcher { contract_address };

    let mut reward_constructor_args = array![];

    let name: ByteArray = "Reward Name";
    let symbol: ByteArray = "RWD";
    let decimals: u8 = 6;

    name.serialize(ref reward_constructor_args);
    symbol.serialize(ref reward_constructor_args);
    decimals.serialize(ref reward_constructor_args);
    owner.serialize(ref reward_constructor_args);

    let (contract_address, _) = contract.deploy(@reward_constructor_args).unwrap();
    let reward_dispatcher = IMockERC20Dispatcher { contract_address };

    (stake_dispatcher, reward_dispatcher, owner)
}

fn deploy_another_erc20( ) -> IMockERC20Dispatcher {
    let contract = declare("MockERC20").unwrap().contract_class();
    let mut constructor_args = array![];

    let owner = contract_address_const::<'owner'>();
    let name: ByteArray = "Another Name";
    let symbol: ByteArray = "ANT";
    let decimals: u8 = 6;

    name.serialize(ref constructor_args);
    symbol.serialize(ref constructor_args);
    decimals.serialize(ref constructor_args);
    owner.serialize(ref constructor_args);

    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    let stake_dispatcher = IMockERC20Dispatcher { contract_address };

    stake_dispatcher
}

fn deploy_staking_contract() -> (IStakingDispatcher, IMockERC20Dispatcher, IMockERC20Dispatcher, ContractAddress) {
    let (stake_dispatcher, reward_dispatcher, owner) = deploy_mock_erc20();
    let staking_token = stake_dispatcher.contract_address ;
    let reward_token = reward_dispatcher.contract_address ;

    let contract = declare("StakingContract").unwrap().contract_class();
    let mut constructor_args = array![];
    owner.serialize(ref constructor_args);
    staking_token.serialize(ref constructor_args);
    reward_token.serialize(ref constructor_args);

    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    let staking_dispatcher = IStakingDispatcher { contract_address };

    (staking_dispatcher, stake_dispatcher, reward_dispatcher, owner)
}

#[test]
fn test_stake() {
    let (staking_contract, staking_token, _reward_token, _owner) = deploy_staking_contract();

    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(staking_token.contract_address, user);

    staking_token.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    staking_token.approve(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(staking_token.contract_address);
    start_cheat_block_timestamp(staking_contract.contract_address, 10000);
    start_cheat_caller_address(staking_contract.contract_address, user);


    let mut spy = spy_events();

    // Stake 50 tokens
    staking_contract.stake(50000000, 10);

    // Check balance
    let balance = staking_contract.balance_of(user);
    assert(balance == 50000000, 'Wrong balance');

    let total_staked = staking_contract.total_staked();
    assert(total_staked == 50000000, 'Wrong total staked');

    let duration = staking_contract.duration_of(user);
    assert(duration == 10010, 'Wrong duration');

    // Check event
    spy.assert_emitted(@array![(
        staking_contract.contract_address,
        staking_contract::contracts::staking::StakingContract::Event::Staked(
            staking_contract::contracts::staking::StakingContract::Staked {
                user,
                amount: 50000000
            }
        )
    )]);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Amount must be > 0')]
fn test_stake_with_amount_set_to_zero() {
    let (staking_contract, _staking_token, _reward_token, _owner) = deploy_staking_contract();

    let user = contract_address_const::<'user'>();

    start_cheat_block_timestamp(staking_contract.contract_address, 10000);
    start_cheat_caller_address(staking_contract.contract_address, user);
    // Stake 50 tokens
    staking_contract.stake(0, 10);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Duration must be > 0')]
fn test_stake_with_duration_set_to_zero() {
    let (staking_contract, _staking_token, _reward_token, _owner) = deploy_staking_contract();

    let user = contract_address_const::<'user'>();

    start_cheat_block_timestamp(staking_contract.contract_address, 10000);
    start_cheat_caller_address(staking_contract.contract_address, user);
    // Stake 50 tokens
    staking_contract.stake(50000000, 0);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Insufficient allowance')]
fn test_stake_with_no_approval_to_staking_contract() {
    let (staking_contract, staking_token, _reward_token, _owner) = deploy_staking_contract();

    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(staking_token.contract_address, user);

    staking_token.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    // staking_token.approve(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(staking_token.contract_address);
    start_cheat_block_timestamp(staking_contract.contract_address, 10000);
    start_cheat_caller_address(staking_contract.contract_address, user);
    // Stake 50 tokens
    staking_contract.stake(50000000, 10);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
fn test_unstake() {
    let user = contract_address_const::<'user'>();
    let (staking_contract, staking_token, _reward_token, _owner) = deploy_staking_contract();

    start_cheat_caller_address(staking_token.contract_address, user);

    staking_token.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    staking_token.approve(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(staking_token.contract_address);

    start_cheat_block_timestamp(staking_contract.contract_address, 10000);
    start_cheat_caller_address(staking_contract.contract_address, user);

    staking_contract.stake(80000000, 10);

    // Check balance
    let balance = staking_contract.balance_of(user);
    assert(balance == 80000000, 'Wrong balance');

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);

    start_cheat_block_timestamp(staking_contract.contract_address, 10010);
    start_cheat_caller_address(staking_contract.contract_address, user);

    let mut spy = spy_events();

    let total_staked_before = staking_contract.total_staked();
    let amount = 80000000;
    // Unstake 50 tokens
    staking_contract.unstake(amount);

    let balance = staking_contract.balance_of(user);
    assert(balance == 0, 'Wrong balance after unstake');

    let total_staked_after = staking_contract.total_staked();
    assert!(total_staked_after == total_staked_before - amount , "Wrong total staked after unstake");

    spy.assert_emitted(@array![(
        staking_contract.contract_address,
        staking_contract::contracts::staking::StakingContract::Event::Unstaked(
            staking_contract::contracts::staking::StakingContract::Unstaked {
                user,
                amount: 80000000
            }
        )
    )]);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Amount must be > 0')]
fn test_unstake_amount_zero() {
    let user = contract_address_const::<'user'>();
    let (staking_contract, staking_token, _reward_token, _owner) = deploy_staking_contract();

    start_cheat_caller_address(staking_token.contract_address, user);

    staking_token.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    staking_token.approve(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(staking_token.contract_address);

    start_cheat_block_timestamp(staking_contract.contract_address, 10000);
    start_cheat_caller_address(staking_contract.contract_address, user);

    staking_contract.stake(80000000, 10);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);

    start_cheat_block_timestamp(staking_contract.contract_address, 10010);
    start_cheat_caller_address(staking_contract.contract_address, user);

    // Unstake 50 tokens
    staking_contract.unstake(0);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Insufficient balance')]
fn test_unstake_more_than_amount_staked() {
    let user = contract_address_const::<'user'>();
    let (staking_contract, staking_token, _reward_token, _owner) = deploy_staking_contract();

    start_cheat_caller_address(staking_token.contract_address, user);

    staking_token.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    staking_token.approve(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(staking_token.contract_address);

    start_cheat_block_timestamp(staking_contract.contract_address, 10000);
    start_cheat_caller_address(staking_contract.contract_address, user);

    staking_contract.stake(80000000, 10);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);

    start_cheat_block_timestamp(staking_contract.contract_address, 10010);
    start_cheat_caller_address(staking_contract.contract_address, user);

    // Unstake 50 tokens
    staking_contract.unstake(100000000);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Staking period has not ended')]
fn test_unstake_stake_duration_not_reached() {
    let user = contract_address_const::<'user'>();
    let (staking_contract, staking_token, _reward_token, _owner) = deploy_staking_contract();

    start_cheat_caller_address(staking_token.contract_address, user);

    staking_token.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    staking_token.approve(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(staking_token.contract_address);

    start_cheat_block_timestamp(staking_contract.contract_address, 10000);
    start_cheat_caller_address(staking_contract.contract_address, user);

    staking_contract.stake(80000000, 100);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);

    start_cheat_block_timestamp(staking_contract.contract_address, 10000);
    start_cheat_caller_address(staking_contract.contract_address, user);

    // Unstake 80 tokens
    staking_contract.unstake(80000000);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
fn test_fund_reward() {
    let (staking_contract, _staking_token, reward_token, owner) = deploy_staking_contract();

    // let user = contract_address_const::<'user'>();

    start_cheat_caller_address(reward_token.contract_address, owner);

    reward_token.mint(owner, 10000000000 );  // 10000 tokens
    // Approve staking contract to spend tokens
    reward_token.approve(staking_contract.contract_address, 10000000000); // 10000 tokens

    stop_cheat_caller_address(reward_token.contract_address);
    start_cheat_block_timestamp(staking_contract.contract_address, 10030);
    start_cheat_caller_address(staking_contract.contract_address, owner);


    let mut spy = spy_events();

    // fund 5000 reward tokens
    staking_contract.fund_rewards(5000000000, 10); // 5000 token, 1% reward

    // Check reward rate
    let reward_rate = staking_contract.reward_rate();
    
    assert(reward_rate == 10 / 1000, 'Wrong reward rate');

    let last_updated_time = staking_contract.last_update_time();
    assert(last_updated_time == 10030, 'Wrong last update time');


    // Check event
    spy.assert_emitted(@array![(
        staking_contract.contract_address,
        staking_contract::contracts::staking::StakingContract::Event::RewardsFunded(
            staking_contract::contracts::staking::StakingContract::RewardsFunded {
                amount: 5000000000,
                reward_multiplier: 10
            }
        )
    )]);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_fund_reward_invoke_by_not_owner() {
    let (staking_contract, _staking_token, reward_token, _owner) = deploy_staking_contract();

    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(reward_token.contract_address, user);

    reward_token.mint(user, 10000000000 );  // 10000 tokens
    // Approve staking contract to spend tokens
    reward_token.approve(staking_contract.contract_address, 1000000000); // 1000 tokens

    stop_cheat_caller_address(reward_token.contract_address);
    start_cheat_block_timestamp(staking_contract.contract_address, 10030);
    start_cheat_caller_address(staking_contract.contract_address, user);

    // fund 5000 reward tokens
    staking_contract.fund_rewards(5000000000, 40); // 5000 token, 7% reward


    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Amount must be > 0')]
fn test_fund_reward_amount_greater_than_zero() {
    let (staking_contract, _staking_token, reward_token, owner) = deploy_staking_contract();

    // let user = contract_address_const::<'user'>();

    start_cheat_caller_address(reward_token.contract_address, owner);

    reward_token.mint(owner, 10000000000 );  // 10000 tokens
    // Approve staking contract to spend tokens
    reward_token.approve(staking_contract.contract_address, 10000000000); // 10000 tokens

    stop_cheat_caller_address(reward_token.contract_address);
    start_cheat_block_timestamp(staking_contract.contract_address, 10030);
    start_cheat_caller_address(staking_contract.contract_address, owner);

    // fund 0 reward tokens
    staking_contract.fund_rewards(0, 10); // 0 token, 1% reward


    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}


#[test]
#[should_panic(expected: "Reward multiplier must be > 0 and less tham 50")]
fn test_fund_reward_multiplier_greater_than_zero() {
    let (staking_contract, _staking_token, reward_token, owner) = deploy_staking_contract();

    // let user = contract_address_const::<'user'>();

    start_cheat_caller_address(reward_token.contract_address, owner);

    reward_token.mint(owner, 10000000000 );  // 10000 tokens
    // Approve staking contract to spend tokens
    reward_token.approve(staking_contract.contract_address, 10000000000); // 10000 tokens

    stop_cheat_caller_address(reward_token.contract_address);
    start_cheat_block_timestamp(staking_contract.contract_address, 10030);
    start_cheat_caller_address(staking_contract.contract_address, owner);

    // fund 5000 reward tokens
    staking_contract.fund_rewards(5000000000, 00); // 5000 token, 0% reward


    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: "Reward multiplier must be > 0 and less tham 50")]
fn test_fund_reward_multiplier_not_greater_than_fifty() {
    let (staking_contract, _staking_token, reward_token, owner) = deploy_staking_contract();

    // let user = contract_address_const::<'user'>();

    start_cheat_caller_address(reward_token.contract_address, owner);

    reward_token.mint(owner, 10000000000 );  // 10000 tokens
    // Approve staking contract to spend tokens
    reward_token.approve(staking_contract.contract_address, 10000000000); // 10000 tokens

    stop_cheat_caller_address(reward_token.contract_address);
    start_cheat_block_timestamp(staking_contract.contract_address, 10030);
    start_cheat_caller_address(staking_contract.contract_address, owner);

    // fund 5000 reward tokens
    staking_contract.fund_rewards(5000000000, 70); // 5000 token, 7% reward


    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Insufficient allowance')]
fn test_fund_reward_with_insufficieint_approval() {
    let (staking_contract, _staking_token, reward_token, owner) = deploy_staking_contract();

    // let user = contract_address_const::<'user'>();

    start_cheat_caller_address(reward_token.contract_address, owner);

    reward_token.mint(owner, 10000000000 );  // 10000 tokens
    // Approve staking contract to spend tokens
    reward_token.approve(staking_contract.contract_address, 1000000000); // 1000 tokens

    stop_cheat_caller_address(reward_token.contract_address);
    start_cheat_block_timestamp(staking_contract.contract_address, 10030);
    start_cheat_caller_address(staking_contract.contract_address, owner);

    // fund 5000 reward tokens
    staking_contract.fund_rewards(5000000000, 40); // 5000 token, 7% reward


    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
#[ignore]
fn test_claim_reward() {
    let (staking_contract, staking_token, reward_token, owner) = deploy_staking_contract();
    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(reward_token.contract_address, owner);

    reward_token.mint(owner, 10000000000 );  // 10000 tokens
    // Approve staking contract to spend tokens
    reward_token.approve(staking_contract.contract_address, 10000000000); // 10000 tokens

    stop_cheat_caller_address(reward_token.contract_address);

    //owner fund reward
    start_cheat_block_timestamp(staking_contract.contract_address, 10030);
    start_cheat_caller_address(staking_contract.contract_address, owner);

    // fund 5000 reward tokens
    staking_contract.fund_rewards(5000000000, 10); // 5000 token, 1% reward

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);

    start_cheat_caller_address(staking_token.contract_address, user);
    staking_token.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    staking_token.approve(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(staking_token.contract_address);
    start_cheat_block_timestamp(staking_contract.contract_address, 10050);
    start_cheat_caller_address(staking_contract.contract_address, user);

    // Stake 100 tokens
    staking_contract.stake(100000000, 10);

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);

    start_cheat_block_timestamp(staking_contract.contract_address, 10070);
    start_cheat_caller_address(staking_contract.contract_address, user);

    // claim rewards
    staking_contract.claim_rewards();

    let reward_earned = staking_contract.earned(user);
    assert(reward_earned == 1000000, 'No rewards earned');

    stop_cheat_caller_address(staking_contract.contract_address);
    stop_cheat_block_timestamp(staking_contract.contract_address);
}

#[test]
fn test_pause() {
    let (staking_contract, _staking_token, _reward_token, owner) = deploy_staking_contract();
    // let user = contract_address_const::<'user'>();

    start_cheat_caller_address(staking_contract.contract_address, owner);

    staking_contract.pause();
    assert(staking_contract.paused(), 'Contract not paused');

    stop_cheat_caller_address(staking_contract.contract_address);

}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_pause_by_non_owner() {
    let (staking_contract, _staking_token, _reward_token, _owner) = deploy_staking_contract();
    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(staking_contract.contract_address, user);

    staking_contract.pause();

    stop_cheat_caller_address(staking_contract.contract_address);

}

#[test]
fn test_unpause() {
    let (staking_contract, _staking_token, _reward_token, owner) = deploy_staking_contract();
    // let user = contract_address_const::<'user'>();

    start_cheat_caller_address(staking_contract.contract_address, owner);

    staking_contract.pause();
    staking_contract.unpause();
    assert(!staking_contract.paused(), 'Contract not paused');

    stop_cheat_caller_address(staking_contract.contract_address);

}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_unpause_by_non_owner() {
    let (staking_contract, _staking_token, _reward_token, owner) = deploy_staking_contract();
    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(staking_contract.contract_address, owner);

    staking_contract.pause();

    stop_cheat_caller_address(staking_contract.contract_address);

    start_cheat_caller_address(staking_contract.contract_address, user);

    staking_contract.unpause();

    stop_cheat_caller_address(staking_contract.contract_address);

}


#[test]
fn test_recover_erc20() {
    let (staking_contract, _staking_token, _reward_token, owner) = deploy_staking_contract();

    let another_erc20 = deploy_another_erc20();

    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(another_erc20.contract_address, user);

    another_erc20.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    another_erc20.transfer(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(another_erc20.contract_address);

    start_cheat_caller_address(staking_contract.contract_address, owner);

    let mut spy = spy_events();

    // Stake 50 tokens
    staking_contract.recover_erc20(another_erc20.contract_address, 50000000);

    // Check event
    spy.assert_emitted(@array![(
        staking_contract.contract_address,
        staking_contract::contracts::staking::StakingContract::Event::RecoveredTokens(
            staking_contract::contracts::staking::StakingContract::RecoveredTokens {
                token: another_erc20.contract_address,
                amount: 50000000
            }
        )
    )]);
    stop_cheat_caller_address(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_recover_erc20_by_non_owner() {
    let (staking_contract, staking_token, _reward_token, owner) = deploy_staking_contract();

    let another_erc20 = deploy_another_erc20();

    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(another_erc20.contract_address, user);

    another_erc20.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    another_erc20.transfer(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(another_erc20.contract_address);

    start_cheat_caller_address(staking_contract.contract_address, user);

    // Stake 50 tokens
    staking_contract.recover_erc20(another_erc20.contract_address, 50000000);

    stop_cheat_caller_address(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Cannot recover staking token')]
fn test_recover_erc20_of_staking_token() {
    let (staking_contract, staking_token, _reward_token, owner) = deploy_staking_contract();

    let another_erc20 = deploy_another_erc20();

    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(another_erc20.contract_address, user);

    another_erc20.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    another_erc20.transfer(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(another_erc20.contract_address);

    start_cheat_caller_address(staking_contract.contract_address, owner);

    // Stake 50 tokens
    staking_contract.recover_erc20(staking_token.contract_address, 50000000);

    stop_cheat_caller_address(staking_contract.contract_address);
}

#[test]
#[should_panic(expected: 'Cannot recover reward token')]
fn test_recover_erc20_of_reward_token() {
    let (staking_contract, _staking_token, reward_token, owner) = deploy_staking_contract();

    let another_erc20 = deploy_another_erc20();

    let user = contract_address_const::<'user'>();

    start_cheat_caller_address(another_erc20.contract_address, user);

    another_erc20.mint(user, 100000000 );  // 100 tokens
    // Approve staking contract to spend tokens
    another_erc20.transfer(staking_contract.contract_address, 100000000); // 100 tokens

    stop_cheat_caller_address(another_erc20.contract_address);

    start_cheat_caller_address(staking_contract.contract_address, owner);

    // Stake 50 tokens
    staking_contract.recover_erc20(reward_token.contract_address, 50000000);

    stop_cheat_caller_address(staking_contract.contract_address);
}
