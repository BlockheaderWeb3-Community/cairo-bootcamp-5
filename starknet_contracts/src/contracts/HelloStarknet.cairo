#[starknet::contract]
pub mod HelloStarknet {
    
    use starknet_contracts::interfaces::IHelloStarknet::IHelloStarknet;
    // use Starknet::storage::{StoragePointerReadAccess, StoragePathEntry, StoragePointerWriteAccess, Map };
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess };
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        balance: felt252,
        balances: Map<ContractAddress, felt252>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Balance : BalanceIncreased,
        Balances: BalanceChanged,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BalanceIncreased {
        pub caller: ContractAddress,
        pub amount: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BalanceChanged {
        pub caller: ContractAddress,
        pub amount: felt252,
        pub old_balance: felt252,
    }



    #[abi(embed_v0)]
    impl HelloStarknetImpl of IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            let caller = get_caller_address();

            let updated_amount = self.balance.read() + amount;
            self.balance.write(updated_amount);

            // let unique_balance = self.balances.entry(caller).read();

            let unique_balance = self.balances.read(caller);
            // self.balances.entry(caller).write(unique_balance + amount);
            self.balances.write(caller, unique_balance + amount);

            // self.balance.write(self.balance.read() + amount);

            self.emit(BalanceIncreased{caller, amount});
        }

        fn set_balance(ref self: ContractState, amount: felt252) {
            let caller = get_caller_address();
            let old_bal = self.balances.read(caller);
            self.balances.write(caller, amount);
            self.emit(BalanceChanged{caller, amount, old_balance: old_bal});
            

        
        }

        fn reset_balance(ref self: ContractState){
            self.balance.write(0);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}