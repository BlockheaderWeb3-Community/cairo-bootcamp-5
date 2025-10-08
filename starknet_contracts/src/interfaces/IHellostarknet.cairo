/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
#[starknet::interface]
pub trait IHellostarknet<TContractState> {
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    fn set_balance(ref self: TContractState, amount: felt252);
    /// Resets the balance to zero.
    fn reset_balance(ref self: TContractState);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;
}
