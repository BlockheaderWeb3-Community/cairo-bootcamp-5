/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
#[starknet::interface]
pub trait IHellostarknet<TContractState> {
    /// set contract balance.
    fn set_balance(ref self: TContractState, amount: felt252);
    /// reset contract balance
    fn reset_balance(ref self:TContractState);
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;
}