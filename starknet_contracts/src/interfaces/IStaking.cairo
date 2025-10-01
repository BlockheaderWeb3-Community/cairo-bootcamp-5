use starknet::ContractAddress;

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