use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};
use test::RewardToken::{IExternalDispatcher, IExternalDispatcherTrait};
use test::interfaces::IStaking::{IStakingDispatcher, IStakingDispatcherTrait};

fn deploy_contract() -> (IStakingDispatcher, ContractAddress, ContractAddress) {
    let contract = declare("Staking").unwrap().contract_class();
    // Define constructor calldata
    let (strk_address, reward_address) = deploy_erc20();
    let mut constructor_args = array![reward_address.into(), strk_address.into()];

    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();

    (IStakingDispatcher { contract_address }, strk_address, reward_address)
}

fn deploy_erc20() -> (ContractAddress, ContractAddress) {
    let owner: ContractAddress = contract_address_const::<'aji'>();
    let name: ByteArray = "STRK";
    let sym: ByteArray = "Sym";
    let reward: ByteArray = "Reward";
    let reward_sym: ByteArray = "RWD";
    // Deploy mock ERC20
    let erc20_class = declare("RewardERC20").unwrap().contract_class();

    // Pass ByteArray directly for name and symbol
    let mut calldata = ArrayTrait::new();
    owner.serialize(ref calldata);
    name.serialize(ref calldata);
    sym.serialize(ref calldata);

    let (strk_address, _) = erc20_class.deploy(@calldata).unwrap();

    let mut usdc_calldata = ArrayTrait::new();
    owner.serialize(ref usdc_calldata);
    reward.serialize(ref usdc_calldata);
    reward_sym.serialize(ref usdc_calldata);
    let (reward_address, _) = erc20_class.deploy(@usdc_calldata).unwrap();

    (strk_address, reward_address)
}


#[test]
fn test_deployment() {
    let (dispatcher, strk_address, reward_address) = deploy_contract();
    let s_address = dispatcher.get_strk_address();
    let r_address = dispatcher.get_reward_address();

    assert(s_address == strk_address, 'invalid strk address');
    assert(r_address == reward_address, 'invalid reward address');
}

#[test]
fn test_stake() {
    let (dispatcher, strk_address, _) = deploy_contract();
    let caller: ContractAddress = contract_address_const::<'aji'>();
    let stake_amount: u256 = 1000;
    let stake_duration: u64 = 60 * 60 * 24 * 7; // 1 week

    // Mint some STRK to caller
    let strk_mint = IExternalDispatcher { contract_address: strk_address };
    strk_mint.mint(caller, 10000);

    let strk = IERC20Dispatcher { contract_address: strk_address };
    let initial_balance = strk.balance_of(caller);

    start_cheat_caller_address(strk_address, caller);
    // Approve staking contract to spend caller's STRK
    strk.approve(dispatcher.contract_address, stake_amount);
    let allowance = strk.allowance(caller, dispatcher.contract_address);
    stop_cheat_caller_address(strk_address);

    println!("Allowance: {}", allowance);
    println!("Initial Balance: {}", initial_balance);

    start_cheat_caller_address(dispatcher.contract_address, caller);
    // Stake tokens
    let stake_id = dispatcher.stake(stake_amount, stake_duration);
    let post_stake_balance = strk.balance_of(caller);

    let p_allowance = strk.allowance(caller, dispatcher.contract_address);
    println!("Allowance after stake: {}", p_allowance);
    println!("Post stake Balance: {}", post_stake_balance);

    assert(post_stake_balance == initial_balance - stake_amount, 'stake failed');
    let contract_balance = strk.balance_of(dispatcher.contract_address);
    assert(contract_balance == stake_amount, 'contract balance incorrect');

    let staked_balance = dispatcher.balance_of(caller);
    assert(staked_balance == stake_amount, 'staked balance incorrect');

    // Get stake details
    let stake_details = dispatcher.get_stake_details(stake_id);
    assert(stake_details.owner == caller, 'stake owner incorrect');
    assert(stake_details.amount == stake_amount, 'stake amount incorrect');
    assert(stake_details.duration == stake_duration, 'stake duration incorrect');
    assert(stake_details.valid, 'stake valid incorrect');
}

#[test]
fn test_Unstake() {
    let (dispatcher, strk_address, _) = deploy_contract();
    let caller: ContractAddress = contract_address_const::<'aji'>();
    let stake_amount: u256 = 1000;
    let unstake_amount: u256 = 500;
    let stake_duration: u64 = 60 * 60 * 24 * 7; // 1 week

    // Mint some STRK to caller
    let strk_mint = IExternalDispatcher { contract_address: strk_address };
    strk_mint.mint(caller, 10000);

    let strk = IERC20Dispatcher { contract_address: strk_address };
    let initial_balance = strk.balance_of(caller);

    start_cheat_caller_address(strk_address, caller);
    // Approve staking contract to spend caller's STRK
    strk.approve(dispatcher.contract_address, stake_amount);
    stop_cheat_caller_address(strk_address);

    start_cheat_caller_address(dispatcher.contract_address, caller);
    // Stake tokens
    let _ = dispatcher.stake(stake_amount, stake_duration);
    let post_stake_balance = strk.balance_of(caller);
    assert(post_stake_balance == initial_balance - stake_amount, 'stake failed');

    // Now unstake
    dispatcher.unstake(unstake_amount);
    let post_unstake_balance = strk.balance_of(caller);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Check user balance increased by unstake_amount
    assert(post_unstake_balance == post_stake_balance + unstake_amount, 'unstake failed');

    // Check contract balance decreased
    let contract_balance = strk.balance_of(dispatcher.contract_address);
    assert(contract_balance == stake_amount - unstake_amount, 'contract balance incorrect');

    // Check staked balance decreased
    let staked_balance = dispatcher.balance_of(caller);
    assert(staked_balance == stake_amount - unstake_amount, 'staked balance incorrect');
}

#[test]
fn test_balance_of() {
    let (dispatcher, strk_address, _) = deploy_contract();
    let caller: ContractAddress = contract_address_const::<'aji'>();
    let stake_amount: u256 = 1000;

    // Mint and stake
    let strk_mint = IExternalDispatcher { contract_address: strk_address };
    strk_mint.mint(caller, 10000);

    let strk = IERC20Dispatcher { contract_address: strk_address };
    start_cheat_caller_address(strk_address, caller);
    strk.approve(dispatcher.contract_address, stake_amount);
    stop_cheat_caller_address(strk_address);

    start_cheat_caller_address(dispatcher.contract_address, caller);
    let _ = dispatcher.stake(stake_amount, 60 * 60 * 24 * 7);
    stop_cheat_caller_address(dispatcher.contract_address);

    let balance = dispatcher.balance_of(caller);
    assert(balance == stake_amount, 'balance_of incorrect');
}

#[test]
fn test_total_supply() {
    let (dispatcher, strk_address, _) = deploy_contract();
    let caller: ContractAddress = contract_address_const::<'aji'>();
    let stake_amount: u256 = 1000;

    let initial_supply = dispatcher.total_supply();
    assert(initial_supply == 0, 'initial supply not zero');

    // Mint and stake
    let strk_mint = IExternalDispatcher { contract_address: strk_address };
    strk_mint.mint(caller, 10000);

    let strk = IERC20Dispatcher { contract_address: strk_address };
    start_cheat_caller_address(strk_address, caller);
    strk.approve(dispatcher.contract_address, stake_amount);
    stop_cheat_caller_address(strk_address);

    start_cheat_caller_address(dispatcher.contract_address, caller);
    let _ = dispatcher.stake(stake_amount, 60 * 60 * 24 * 7);
    stop_cheat_caller_address(dispatcher.contract_address);

    let supply = dispatcher.total_supply();
    assert(supply == stake_amount, 'total_supply incorrect');
}

#[test]
fn test_earned() {
    let (dispatcher, _, _) = deploy_contract();
    let caller: ContractAddress = contract_address_const::<'aji'>();

    // No staking, no rewards
    let earned_amount = dispatcher.earned(caller);
    assert(earned_amount == 0, 'earned should be zero initially');
}

#[test]
fn test_reward_per_token() {
    let (dispatcher, _, _) = deploy_contract();

    let rpt = dispatcher.reward_per_token();
    assert(rpt == 0, 'reward_per_token should be zero');
}

#[test]
fn test_last_time_reward_applicable() {
    let (dispatcher, _, _) = deploy_contract();

    let ltra = dispatcher.last_time_reward_applicable();
    // Since period_finish is 0, and current_time > 0, should return 0
    assert(ltra == 0, 'ltra incorrect');
}

#[test]
#[should_panic(expected: ('No rewards to claim',))]
fn test_claim_rewards_no_rewards() {
    let (dispatcher, _, _) = deploy_contract();
    let caller: ContractAddress = contract_address_const::<'aji'>();

    start_cheat_caller_address(dispatcher.contract_address, caller);
    dispatcher.claim_rewards();
    stop_cheat_caller_address(dispatcher.contract_address);
}