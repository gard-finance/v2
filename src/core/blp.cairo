use starknet::ContractAddress;

#[starknet::interface]
trait IBridgeableLP<ContractState> {
    fn bridge(ref self: ContractState, from: ContractAddress, to: felt252, amount: u256);
    fn ethereum_bridge(self: @ContractState) -> felt252;
}

#[starknet::contract]
mod BLP {
    use vaults::interfaces::erc20;
    use vaults::interfaces::erc20::IERC20Dispatcher;
    use vaults::interfaces::erc20::IERC20DispatcherTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::syscalls::send_message_to_l1_syscall;
    use super::IBridgeableLP;
    use array::ArrayTrait;
    use traits::Into;

    #[storage]
    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _decimals: u8,
        _total_supply: u256,
        _balances: LegacyMap<ContractAddress, u256>,
        _allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        _ethereum_bridge: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: erc20::Transfer,
        Approval: erc20::Approval
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        _name: felt252,
        _symbol: felt252,
        _asset: ContractAddress,
        _ethereum_bridge: felt252
    ) {
        self._name.write(_name);
        self._symbol.write(_symbol);
        self._decimals.write(18);
        self._ethereum_bridge.write(_ethereum_bridge);
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

    #[l1_handler]
    fn bridge(ref self: ContractState, from_address: felt252, to: ContractAddress, amount: u256) {
        assert(from_address == self._ethereum_bridge.read(), 'Invalid from');
        _mint(ref self, to, amount);
    }

    impl BridgeableLP of IBridgeableLP<ContractState> {
        fn bridge(ref self: ContractState, from: ContractAddress, to: felt252, amount: u256) {
            if (from != get_caller_address()) {
                self
                    ._allowances
                    .write(
                        (from, get_caller_address()),
                        self._allowances.read((from, get_caller_address())) - amount
                    );
            }
            _burn(ref self, from, amount);
            let mut payload = ArrayTrait::new();
            payload.append(to);
            payload.append(amount.low.into());
            payload.append(amount.high.into());
            send_message_to_l1_syscall(self._ethereum_bridge.read(), payload.span())
                .unwrap_syscall();
        }
        fn ethereum_bridge(self: @ContractState) -> felt252 {
            self._ethereum_bridge.read()
        }
    }
}
