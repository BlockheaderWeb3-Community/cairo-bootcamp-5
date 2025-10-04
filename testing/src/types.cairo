use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct StakeDetails {
    pub owner: ContractAddress,
    pub duration: u64,
    pub amount: u256,
    pub valid: bool,
}
