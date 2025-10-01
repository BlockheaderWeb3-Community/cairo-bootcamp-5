use starknet::ContractAddress;

#[starknet::interface]
trait IHelloStarknet<TContractState> {
    fn increase_balance(ref self: TContractState, amount: felt252);
    fn get_balance(self: @TContractState) -> felt252;
    fn set_balance(ref self: TContractState, new_balance: felt252);
    fn reset_balance(ref self: TContractState);
}

#[derive(Drop, starknet::Event)]
enum Event {
    BalanceIncreased: BalanceIncreased,
}

#[derive(Drop, starknet::Event)]
struct BalanceIncreased {
    caller: ContractAddress,
    amount: felt252,
}

#[starknet::contract]
mod HelloStarknet {
    use super::IHelloStarknet;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        balance: felt252,
        balances: Map<ContractAddress, felt252>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BalanceIncreased: BalanceIncreased,
    }

    #[derive(Drop, starknet::Event)]
    struct BalanceIncreased {
        caller: ContractAddress,
        amount: felt252,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');

            let caller = get_caller_address();
            let new_total = self.balance.read() + amount;
            self.balance.write(new_total);

            let user_balance = self.balances.read(caller);
            self.balances.write(caller, user_balance + amount);

            self.emit(BalanceIncreased { caller, amount });
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }

        fn set_balance(ref self: ContractState, new_balance: felt252) {
            self.balance.write(new_balance);
        }

        fn reset_balance(ref self: ContractState) {
            self.balance.write(0);
        }
    }
}
