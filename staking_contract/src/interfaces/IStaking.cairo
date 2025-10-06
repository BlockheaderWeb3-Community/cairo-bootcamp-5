use starknet::ContractAddress;

#[starknet::interface]
pub trait IStaking<TContractState> {
    // User functions
    fn stake(ref self: TContractState, amount: u256, duration: u64);
    fn unstake(ref self: TContractState, amount: u256);
    fn claim_rewards(ref self: TContractState);

    // View functions
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn duration_of(self: @TContractState, account: ContractAddress) -> u64;
    fn earned(self: @TContractState, account: ContractAddress) -> u256;
    fn total_staked(self: @TContractState) -> u256;
    fn reward_rate(self: @TContractState) -> u256;
    fn last_update_time(self: @TContractState) -> u64;

    // Owner functions
    fn fund_rewards(ref self: TContractState, amount: u256, reward_multiplier: u64);
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);
    fn recover_erc20(ref self: TContractState, token: ContractAddress, amount: u256);

    // Pausable view
    fn paused(self: @TContractState) -> bool;
}