#[starknet::interface]
/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
pub trait IHelloStarknet<TContractState> {
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;

    fn reset_balance(ref self: TContractState);

    fn set_balance(ref self: TContractState, amount: felt252);
}