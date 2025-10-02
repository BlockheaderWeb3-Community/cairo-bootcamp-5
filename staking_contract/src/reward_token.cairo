// reward_token.cairo
%lang starknet

use starknet::ContractAddress;
use core::integer::u256;
use starknet::storage::LegacyMap;
use starknet::event;

#[storage]
struct Storage {
    balances: LegacyMap<ContractAddress, u256>,
    total_supply: u256,
    name: felt252,
    symbol: felt252
}

#[event]
struct Transfer {
    from: ContractAddress,
    to: ContractAddress,
    value: u256
}

#[contract]
mod RewardToken {
    use super::{Storage, Transfer};
    use starknet::ContractAddress;
    use core::integer::u256;

    #[constructor]
    fn constructor(
        ref self: Storage,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        owner: ContractAddress
    ) {
        self.name = name;
        self.symbol = symbol;
        self.total_supply = initial_supply;
        self.balances.write(owner, initial_supply);
        emit!(Transfer { from: ContractAddress::from(0), to: owner, value: initial_supply });
    }

    #[external(v0)]
    fn name(self: @Storage) -> felt252 {
        self.name
    }

    #[external(v0)]
    fn symbol(self: @Storage) -> felt252 {
        self.symbol
    }

    #[external(v0)]
    fn totalSupply(self: @Storage) -> u256 {
        self.total_supply
    }

    #[external(v0)]
    fn balanceOf(self: @Storage, owner: ContractAddress) -> u256 {
        self.balances.read(owner)
    }

    #[external(v0)]
    fn transfer(ref self: Storage, to: ContractAddress, amount: u256) {
        let sender = starknet::get_caller_address();
        let sender_balance = self.balances.read(sender);
        assert(sender_balance >= amount, 'Insufficient balance');

        self.balances.write(sender, sender_balance - amount);

        let receiver_balance = self.balances.read(to);
        self.balances.write(to, receiver_balance + amount);

        emit!(Transfer { from: sender, to, value: amount });
    }
}
