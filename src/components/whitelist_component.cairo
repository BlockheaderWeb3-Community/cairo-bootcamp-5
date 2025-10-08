use starknet::ContractAddress;

#[starknet::interface]
pub trait IWhitelist<TContractState> {
    fn add_to_whitelist(ref self: TContractState, address: ContractAddress);
    fn remove_from_whitelist(ref self: TContractState, address: ContractAddress);
    fn is_whitelisted(self: @TContractState, address: ContractAddress) -> bool;
}

#[starknet::component]
pub mod WhitelistComponent {
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};
    use super::IWhitelist;

    #[storage]
    pub struct Storage {
        admin: ContractAddress,
        whitelist_addresses: Map<ContractAddress, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        AddressAdded: AddressAdded,
        AddressRemoved: AddressRemoved,
    }

    #[derive(Drop, starknet::Event)]
    pub struct AddressAdded {
        address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct AddressRemoved {
        address: ContractAddress,
    }

    #[embeddable_as(WhitelistComponent)]
    pub impl WhitelistComponentImpl<
        TContractState, +HasComponent<TContractState>,
    > of IWhitelist<ComponentState<TContractState>> {
        fn add_to_whitelist(ref self: ComponentState<TContractState>, address: ContractAddress) {
            self.only_admin(get_caller_address());
            self.whitelist_addresses.write(address, true);
            self.emit(Event::AddressAdded(AddressAdded { address }));
        }

        fn remove_from_whitelist(
            ref self: ComponentState<TContractState>, address: ContractAddress,
        ) {
            self.only_admin(get_caller_address());
            self.whitelist_addresses.write(address, false);
            self.emit(Event::AddressRemoved(AddressRemoved { address }));
        }

        fn is_whitelisted(self: @ComponentState<TContractState>, address: ContractAddress) -> bool {
            self.whitelist_addresses.read(address)
        }
    }

    #[generate_trait]
    pub impl PrivateImpl<
        TContractState, +HasComponent<TContractState>,
    > of PrivateTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, admin: ContractAddress) {
            self.admin.write(admin);
        }

        fn only_admin(self: @ComponentState<TContractState>, caller: ContractAddress) {
            let admin: ContractAddress = self.admin.read();

            assert(caller == admin, 'Caller not Admin');
        }
    }
}
