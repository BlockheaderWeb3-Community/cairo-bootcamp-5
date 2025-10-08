#[starknet::contract]
mod WhitelistedContract {
    use starknet::get_caller_address;
    use crate::components::whitelist_component::WhitelistComponent;

    // Declare component
    component!(path: WhitelistComponent, storage: whitelist, event: WhitelistEvent);

    // Implement component
    #[abi(embed_v0)]
    impl whitelistImpl = WhitelistComponent::WhitelistComponent<ContractState>;
    impl whitelistInternalImpl = WhitelistComponent::PrivateImpl<ContractState>;

    #[storage]
    pub struct Storage {
        // Add component to storage struct
        #[substorage(v0)]
        whitelist: WhitelistComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        // Add component to event enum
        WhitelistEvent: WhitelistComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let deployer = get_caller_address();
        // Initialize component
        self.whitelist.initializer(deployer);
    }

    #[external(v0)]
    fn whitelisted_function(ref self: ContractState) -> felt252 {
        // Only whitelisted addresses can call this function
        let caller = get_caller_address();

        // Use component to perform assetion
        let is_whitelisted = self.whitelist.is_whitelisted(caller);
        assert(is_whitelisted, 'ADDRESS NOT WHITELISTED');

        'success'
    }
}
