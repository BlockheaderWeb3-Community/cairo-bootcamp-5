pub mod interfaces{
    pub mod IHelloStarknet;
    pub mod ICounter;
    pub mod IStaking;
    pub mod IOwnerFunctions;
}

pub mod contracts{
    pub mod HelloStarknet;
    pub mod counter;
    pub mod RewardToken;
    pub mod StakingContract;
}

/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
#[starknet::interface]
pub trait IHelloStarknet<TContractState> {
    /// Increase contract balance.
    fn increase_balance(ref self: TContractState, amount: felt252);
    /// Retrieve contract balance.
    fn get_balance(self: @TContractState) -> felt252;
    // Set contract balance
    fn set_balance(ref self: TContractState, value: felt252);
    // Reset contract balance
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

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }

        fn set_balance(ref self: ContractState, value: felt252) {
            assert(value != 0, 'Amount cannot be 0');
            self.balance.write(value);
        }

        fn reset_balance(ref self: ContractState){
            self.balance.write(0);
        }

        // Proof of STRK token transaction
        // transaction_hash: 0x0795336f0af31efc023ee9ebe31b94e034545774913d422d6b7ea8cf0aa920cd
    }
}

