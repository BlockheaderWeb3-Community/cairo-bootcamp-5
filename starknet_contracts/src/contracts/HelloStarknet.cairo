
/// Interface representing `HelloContract`.
/// This interface allows modification and retrieval of the contract balance.
// use starknet::storage::{StorageMapWriteAccess, StorageMapReadAccess};

#[starknet::contract]
pub mod HelloStarknet {

    use starknet_contracts::interfaces::IHelloStarknet::IHelloStarknet;
    use starknet::storage::*;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::event::EventEmitter;

    #[storage]
    struct Storage {
        balance: felt252,
        balances: Map<ContractAddress, felt252>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Balance: BalanceUpdated,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BalanceUpdated {
        pub caller: ContractAddress,
        pub old_amount: felt252,
        pub new_amount: felt252
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            let caller = get_caller_address();

            // Update total balance
            let old_amount = self.balance.read();
            let updated_amount = old_amount + amount;
            self.balance.write(updated_amount);

            // let unique_balance = self.balances.entry(caller).read();

            let old_unique_balance = self.balances.read(caller);
            // self.balances.entry(caller).write(unique_balance + amount);
            let new_unique_balance = old_unique_balance + amount;
            self.balances.write(caller, new_unique_balance);

            self.emit(Event::Balance(BalanceUpdated { caller, old_amount: old_unique_balance, new_amount: updated_amount }));
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }

        fn get_unique_balance(self: @ContractState, addr: ContractAddress) -> felt252 {
            self.balances.read(addr)
        }

        fn set_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            let caller = get_caller_address();

            let old_unique_balance = self.balances.read(caller);
            
            self.balances.write(caller, amount);

            let old_total_balance = self.balance.read();
            let new_total_balance = old_total_balance + amount - old_unique_balance;
            self.balance.write(new_total_balance);

            self.emit(Event::Balance(BalanceUpdated { caller, old_amount: old_unique_balance, new_amount: amount }));
        }

        fn reset_balance(ref self: ContractState) {
            let caller = get_caller_address();
            let old_unique_balance = self.balances.read(caller);
            let total_balance = self.balance.read();
            let new_total_balance = total_balance - old_unique_balance;
            self.balance.write(new_total_balance);

            self.balances.write(caller, 0);

            self.emit(Event::Balance(BalanceUpdated { caller, old_amount: old_unique_balance, new_amount: 0 }));

        }
    }
}