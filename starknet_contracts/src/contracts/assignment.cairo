/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;
    // set contract balance
    fn set_balance(ref self: TContractState, amount: felt252);
    // reset balance
    fn reset_balance(ref self: TContractState);
}

/// Simple contract for managing balance.
#[starknet::contract]
mod HelloStarknet {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        balance: felt252,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }
        fn set_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(amount);
        }
        fn reset_balance(ref self: ContractState) {
            self.balance.write(0);
        }
        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}

// Assignment solution

// https://hackmd.io/@rp5xTWqeSeW3uFgGXiX0Eg/ryog6j5nll 

