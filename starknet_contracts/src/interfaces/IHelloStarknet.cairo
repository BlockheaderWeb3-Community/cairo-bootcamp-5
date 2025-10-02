/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.

use starknet::ContractAddress;

#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;
    fn get_unique_balance(self: @TContractState, addr: ContractAddress) -> felt252;
    fn set_balance(ref self: TContractState, amount: felt252);
    fn reset_balance(ref self: TContractState);
}