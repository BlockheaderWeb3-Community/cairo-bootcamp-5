#[starknet::contract]
pub mod HelloStarknet {
    use starknet::storage::*;
    use starknet::{ContractAddress, get_caller_address};
    use crate::interfaces::IHelloStarknet::IHelloStarknet;  // <--- correct import

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
        pub new_amount: felt252,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            let caller = get_caller_address();

            let old_total = self.balance.read();
            let new_total = old_total + amount;
            self.balance.write(new_total);

            let old_unique = self.balances.read(caller);
            let new_unique = old_unique + amount;
            self.balances.write(caller, new_unique);

            self.emit(Event::Balance(BalanceUpdated { caller, old_amount: old_unique, new_amount: new_unique }));
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

            let old_unique = self.balances.read(caller);
            self.balances.write(caller, amount);

            let old_total = self.balance.read();
            let new_total = old_total + amount - old_unique;
            self.balance.write(new_total);

            self.emit(Event::Balance(BalanceUpdated { caller, old_amount: old_unique, new_amount: amount }));
        }

        fn reset_balance(ref self: ContractState) {
            let caller = get_caller_address();
            let old_unique = self.balances.read(caller);

            let total = self.balance.read();
            self.balance.write(total - old_unique);

            self.balances.write(caller, 0);

            self.emit(Event::Balance(BalanceUpdated { caller, old_amount: old_unique, new_amount: 0 }));
        }
    }
}
