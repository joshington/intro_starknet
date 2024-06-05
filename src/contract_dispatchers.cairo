//contract dispatchers, library dispatchers and system calls.

//each time a contract interface is defined, 2 dispatchers are automatically created and exported by the compiler
//1. contract dispatcher: IERC20Dispatcher
//2. library dispatcher: IERC20LibraryDispatcher

//==compiler also generates a trait IERC20DispatcherTrait, allowing us to call the functions defined in the interface
//on the dispatcher struct.

use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    fn name(self: @TContractState) -> felt252;

    fn symbol(self: @TContractState) -> felt252;

    fn decimals(self: @TContractState) -> u8;

    fn total_supply(self: @TContractState) -> u256;

    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;

    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;

    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;

    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;

    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
}

trait IERC20DispatcherTrait<T> {
    fn name(self:T) -> felt252;
    fn transfer(self:T, recipient:ContractAddress, amount:u256);
}

#[derive(Copy, Drop, starknet::Store, Serde)]
struct IERC20Dispatcher {
    contract_address:ContractAddress,
}


#[derive(Copy, Drop, starknet::Store, Serde)]
struct IERC20LibraryDispatcher {
    class_hash:starknet::ClassHash,
}

impl IERC20LibraryDispatcherImpl of IERC20DispatcherTrait<IERC20LibraryDispatcher> {
    fn name(
        self: IERC20LibraryDispatcher
    ) -> felt252 { // starknet::syscalls::library_call_syscall  is called in here
    }
    fn transfer(
        self: IERC20LibraryDispatcher, recipient: ContractAddress, amount: u256
    ) { // starknet::syscalls::library_call_syscall  is called in here
    }
}

impl IERC20DispatcherImpl of IERC20DispatcherTrait<IERC20Dispatcher> {
    fn name(
        self:IERC20Dispatcher
    ) -> felt252 { //starknet::call_contract_syscall is called in here.
    }

    fn transfer(
        self:IERC20Dispatcher, recipient:ContractAddress,amount:u256
    ) { //starknet::call_contract_syscall is called in here

    }
}

//calling contracts using the contract dispatcher===
//example below uses a dispatcher to call funcs defined on an ERC-20 token. calling transfer_token will modify the 
//state of the contract deployed at contract_address.
#[starknet::contract]
mod TokenWrapper {
    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;
    use super::ITokenWrapper;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}
    impl TokenWrapper of ITokenWrapper<ContractState> {
        fn token_name(self: @ContractState, contract_address: ContractAddress) -> felt252 {
            IERC20Dispatcher { contract_address }.name()
        }
        fn transfer_token(
            ref self:ContractState,
            contract_address:ContractAddress,
            recipient:ContractAddress,
            amount:u256
        ) -> bool {
            IERC20Dispatcher {contract_address}.transfer(recipient, amount)
        }
    }
}

#[starknet::interface]
trait IContractA<TContractState> {
    fn set_value(ref self:TContractState, value:u128);
    fn get_value(self:@TContractState) -> u128;
}

#[starknet::contract]
mod ContractA {
    use super::{IContractADispatcherTrait, IContractALibraryDispatcher};
    use starknet::{ContractAddress, class_hash::class_hash_const};

    #[storage]
    struct Storage {
        value:u128
    }
}

#[abi(embed_v0)]
impl ContractA of super::IContractA<ContractState> {
    fn set_value(ref self:ContractState, value:u128){
        IContractALibraryDispatcher {class_hash:class_hash_const::<0x1234>()}
            .set_value(value)
    }

    fn get_value(self: @ContractState) -> u128 {
        self.value.read()
    }
}

//using these syscalls can be handy for customised error handling or to get more control over the serialization/deserialization
//of the call data and the returned data.
//===how to use a call_contract_syscall to call the transfer function of an ERC20 contract.

use starknet::ContractAddress;
#[starknet::interface]
trait ITokenWrapper<TContractState> {
    fn transfer_token(
        ref self:TContractState,
        address:ContractAddress,
        sender:ContractAddress,
        recipient:ContractAddress,
        amount: u256
    ) -> bool;
}

#[starknet::contract]
mod TokenWrapper {
    use super::ITokenWrapper;
    use core::serde::Serde;
    use starknet::{SyscallResultTrait, ContractAddress, syscalls};

    #[storage]
    struct Storage {}

    impl TokenWrapper of ITokenWrapper<ContractState> {
        fn transfer_token(
            ref self:ContractState,
            address: ContractAddress,
            sender:ContractAddress,
            recipient:ContractAddress,
            amount:u256 
        ) -> bool {
            let mut call_data: Array<felt252> = ArrayTrait::new();
            Serde::serialize(@sender, ref call_data);
            Serde::serialize(@recipient, ref call_data);
            Serde::serialize(@amount, ref call_data);

            let mut res = syscalls::call_contract_syscall(
                address, selector!("transferFrom"), call_data.span()
            )
                .unwrap_syscall();

            Serde::<bool>::deserialize(ref res).unwrap()
        }
    }
}

//library dispatcher
//key diff btn the contract dispatcher and the library dispatcher lies in the execution
//context of the logic defined in the class. while regular dispatchers are used to call funcs from
//contracts with an associated state, library


//===Entrypoint selector====
//in the context of asmart contract, a selector is aunique identifier for a specific entrypoint of a contract.
//when a transaction is sent to a contract, it included the selector in the calldata to specify which function
//should be executed.