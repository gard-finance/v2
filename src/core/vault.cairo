#[starknet::contract]
mod Vault {
    use vaults::interfaces::erc20;
    use vaults::interfaces::erc20::IERC20Dispatcher;
    use vaults::interfaces::erc20::IERC20DispatcherTrait;
    use vaults::interfaces::erc4626;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;

    #[storage]
    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _decimals: u8,
        _total_supply: u256,
        _balances: LegacyMap<ContractAddress, u256>,
        _allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        _asset: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deposit: erc4626::Deposit,
        Withdraw: erc4626::Withdraw,
        Transfer: erc20::Transfer,
        Approval: erc20::Approval
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, _name: felt252, _symbol: felt252, _asset: ContractAddress
    ) {
        self._name.write(_name);
        self._symbol.write(_symbol);
        self._asset.write(_asset);
        self._decimals.write(18);
    }

    impl ERC20 of erc20::IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }
        fn symbol(self: @ContractState) -> felt252 {
            self._symbol.read()
        }
        fn decimals(self: @ContractState) -> u8 {
            self._decimals.read()
        }
        fn total_supply(self: @ContractState) -> u256 {
            self._total_supply.read()
        }
        fn totalSupply(self: @ContractState) -> u256 {
            self._total_supply.read()
        }
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self._balances.read(account)
        }
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self._balances.read(account)
        }
        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self._allowances.read((owner, spender))
        }
        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
            _transfer(ref self, get_caller_address(), to, amount)
        }
        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
        ) -> bool {
            let allowance = self._allowances.read((from, get_caller_address()));
            self._allowances.write((from, get_caller_address()), allowance - amount);
            _transfer(ref self, from, to, amount)
        }
        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
        ) -> bool {
            ERC20::transfer_from(ref self, from, to, amount)
        }
        fn approve(ref self: ContractState, spender: ContractAddress, value: u256) -> bool {
            self._allowances.write((get_caller_address(), spender), value);
            true
        }
    }

    fn _transfer(
        ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
    ) -> bool {
        let from_balance = self._balances.read(from);
        self._balances.write(from, from_balance - amount);
        let to_balance = self._balances.read(to);
        self._balances.write(to, to_balance + amount);
        true
    }

    fn _mint(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
        self._balances.write(to, self._balances.read(to) + amount);
        self._total_supply.write(self._total_supply.read() + amount);
        true
    }

    fn _burn(ref self: ContractState, from: ContractAddress, amount: u256) -> bool {
        self._balances.write(from, self._balances.read(from) - amount);
        self._total_supply.write(self._total_supply.read() - amount);
        true
    }

    impl ERC4626 of erc4626::IERC4626<ContractState> {
        fn asset(self: @ContractState) -> ContractAddress {
            self._asset.read()
        }
        fn total_assets(self: @ContractState) -> u256 {
            IERC20Dispatcher {
                contract_address: ERC4626::asset(self)
            }.balance_of(get_contract_address())
        }
        fn convert_to_shares(self: @ContractState, assets: u256) -> u256 {
            assets * ERC20::total_supply(self) / ERC4626::total_assets(self)
        }
        fn convert_to_assets(self: @ContractState, shares: u256) -> u256 {
            shares * ERC4626::total_assets(self) / ERC20::total_supply(self)
        }
        fn max_deposit(self: @ContractState, receiver: ContractAddress) -> u256 {
            erc20::IERC20Dispatcher {
                contract_address: ERC4626::asset(self)
            }.total_supply() - ERC4626::total_assets(self)
        }
        fn preview_deposit(self: @ContractState, assets: u256) -> u256 {
            ERC4626::convert_to_shares(self, assets)
        }
        fn deposit(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256 {
            IERC20Dispatcher {
                contract_address: ERC4626::asset(@self)
            }.transfer_from(get_caller_address(), get_contract_address(), assets);
            let shares = ERC4626::convert_to_shares(@self, assets);
            _mint(ref self, receiver, shares);
            shares
        }
        fn max_mint(self: @ContractState, receiver: ContractAddress) -> u256 {
            ERC4626::convert_to_shares(self, ERC4626::max_deposit(self, receiver))
        }
        fn preview_mint(self: @ContractState, shares: u256) -> u256 {
            ERC4626::convert_to_assets(self, shares)
        }
        fn mint(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256 {
            let assets = ERC4626::convert_to_assets(@self, shares);
            IERC20Dispatcher {
                contract_address: ERC4626::asset(@self)
            }.transfer_from(get_caller_address(), get_contract_address(), assets);
            _mint(ref self, receiver, shares);
            shares
        }
        fn max_withdraw(self: @ContractState, receiver: ContractAddress) -> u256 {
            ERC4626::convert_to_assets(self, ERC20::balance_of(self, receiver))
        }
        fn preview_withdraw(self: @ContractState, assets: u256) -> u256 {
            ERC4626::convert_to_shares(self, assets)
        }
        fn withdraw(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256 {
            let shares = ERC4626::convert_to_shares(@self, assets);
            _burn(ref self, receiver, shares);
            IERC20Dispatcher {
                contract_address: ERC4626::asset(@self)
            }.transfer(get_caller_address(), assets);
            shares
        }
        fn max_redeem(self: @ContractState, receiver: ContractAddress) -> u256 {
            ERC20::balance_of(self, receiver)
        }
        fn preview_redeem(self: @ContractState, shares: u256) -> u256 {
            ERC4626::convert_to_assets(self, shares)
        }
        fn redeem(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256 {
            _burn(ref self, receiver, shares);
            let assets = ERC4626::convert_to_assets(@self, shares);
            IERC20Dispatcher {
                contract_address: ERC4626::asset(@self)
            }.transfer(get_caller_address(), assets);
            assets
        }
    }
}
