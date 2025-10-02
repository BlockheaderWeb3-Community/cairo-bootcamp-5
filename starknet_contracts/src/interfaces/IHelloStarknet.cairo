use starknet::ContractAddress;  // <--- this was missing

/// Interface representing `HelloContract`.
#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    fn increase_balance(ref self: TContractState, amount: felt252);
    fn get_balance(self: @TContractState) -> felt252;
    fn get_unique_balance(self: @TContractState, addr: ContractAddress) -> felt252;
    fn set_balance(ref self: TContractState, amount: felt252);
    fn reset_balance(ref self: TContractState);
}
