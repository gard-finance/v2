use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<ContractState> {
    fn name(self: @ContractState) -> felt252;
    fn symbol(self: @ContractState) -> felt252;
    fn decimals(self: @ContractState) -> u8;
    fn total_supply(self: @ContractState) -> u256;
    fn totalSupply(self: @ContractState) -> u256;
    fn balance_of(self: @ContractState, account: ContractAddress) -> u256;
    fn balanceOf(self: @ContractState, account: ContractAddress) -> u256;
    fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
    ) -> bool;
    fn transferFrom(
        ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: ContractState, spender: ContractAddress, value: u256) -> bool;
}


#[event]
#[derive(Drop, starknet::Event)]
struct Transfer {
    from: ContractAddress,
    to: ContractAddress,
    value: u256,
}

#[event]
#[derive(Drop, starknet::Event)]
struct Approval {
    owner: ContractAddress,
    spender: ContractAddress,
    value: u256,
}
