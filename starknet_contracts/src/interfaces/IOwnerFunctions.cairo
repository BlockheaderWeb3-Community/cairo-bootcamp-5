use starknet::ContractAddress;

#[starknet::interface]
trait IOwnerFunctions<TContractState> {
    fn fund_rewards(ref self: TContractState, amount: u256, duration: u64);
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);
    fn recover_erc20(ref self: TContractState, token: ContractAddress, amount: u256);
}