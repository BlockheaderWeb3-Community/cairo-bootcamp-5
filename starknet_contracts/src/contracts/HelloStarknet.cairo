/// Simple contract for managing balance.
#[starknet::contract]
pub mod HelloStarknet {
    
    use starknet_contracts::interfaces::IHelloStarknet::IHellostarknet;
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
    }

    #[derive(Drop, starknet::Event)]
    pub struct BalanceIncreased {
        pub caller: ContractAddress,
        pub amount: felt252,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of IHellostarknet<ContractState> {
        fn set_balance(ref self: ContractState, amount: felt252) {
            self.balance.write(amount);
        }
        fn reset_balance(ref self: ContractState) {
            self.balance.write(0);
        }
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

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}

// this is the link to a hackmd file detailing the steps taken to achieve the process
// https://hackmd.io/@demigodjayydy/B1uVi-23xx

// stark token transfer transaction hash: 0x007d9c57cc95103408b263c3743b1b88b42277870555dbeb1b2b09e4e60143e4