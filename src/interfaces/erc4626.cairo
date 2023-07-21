use starknet::ContractAddress;

#[starknet::inteface]
trait IERC4626<ContractState> {
    fn asset(self: @ContractState) -> ContractAddress;
    fn total_assets(self: @ContractState) -> u256;
    fn convert_to_shares(self: @ContractState, assets: u256) -> u256;
    fn convert_to_assets(self: @ContractState, shares: u256) -> u256;
    fn max_deposit(self: @ContractState, receiver: ContractAddress) -> u256;
    fn preview_deposit(self: @ContractState, assets: u256) -> u256;
    fn deposit(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256;
    fn max_mint(self: @ContractState, receiver: ContractAddress) -> u256;
    fn preview_mint(self: @ContractState, shares: u256) -> u256;
    fn mint(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256;
    fn max_withdraw(self: @ContractState, receiver: ContractAddress) -> u256;
    fn preview_withdraw(self: @ContractState, assets: u256) -> u256;
    fn withdraw(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256;
    fn max_redeem(self: @ContractState, receiver: ContractAddress) -> u256;
    fn preview_redeem(self: @ContractState, shares: u256) -> u256;
    fn redeem(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256;
}

#[event]
#[derive(Drop, starknet::Event)]
struct Deposit {
    sender: ContractAddress,
    owner: ContractAddress,
    assets: u256,
    shares: u256
}

#[event]
#[derive(Drop, starknet::Event)]
struct Withdraw {
    sender: ContractAddress,
    receiver: ContractAddress,
    owner: ContractAddress,
    assets: u256,
    shares: u256
}
