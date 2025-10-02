#[starknet::contract]
pub mod Counter {
    // use Starknet::ContractAddress;
    // use Starknet::get_caller_address;
    use starknet_contracts::interfaces::ICounter::ICounter;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        count: u32,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CountUpdated : CountUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct CountUpdated {
        old_value: u32,
        new_value: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.count.write(0);
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState> {
        fn get_count(self: @ContractState) -> u32 {
            self.count.read()
        }

        fn increment(ref self: ContractState) {
            let old_value = self.count.read();
            let new_value = old_value + 1;
            self.count.write(new_value);
            self.emit(CountUpdated { old_value, new_value });
        }

        fn decrement(ref self: ContractState) {
            let old_value = self.count.read();
            assert(old_value > 0, 'Count cannot be negative');
            let new_value = old_value - 1;
            self.count.write(new_value);
            self.emit(CountUpdated { old_value, new_value });
        }
    }
}

// sncast deploy --url https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_8/Z8ps3lEeb_j7VOniV_nSVx4o1940CLWl --cl
// ass-hash 0x03c4cf8f4d177e4ee089f46fa8ac00e628ebc2304acfaa004c95c79eab03963a
// command: deploy
// contract_address: 0x00c8fe524538e9c04d6254e4b928d847c8cd0da8572f01fa40d37307b20e229b
// transaction_hash: 0x0638e2f68620df0e28a77fe004295657f49fa881938fc600a28f98ed7c7efccd


// To see deployment details, visit:
// contract: https://sepolia.starkscan.co/contract/0x00c8fe524538e9c04d6254e4b928d847c8cd0da8572f01fa40d37307b20e229b
// transaction: https://sepolia.starkscan.co/tx/0x0638e2f68620df0e28a77fe004295657f49fa881938fc600a28f98ed7c7efccd