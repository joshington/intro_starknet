//===contract funcs===
//funcs can access the contract's state easily via self:ContractState, which abstracts away the complexity of 
//underlying system calls(storage_read_syscall and storage_write_syscall), the compiler provides 2 modifiers
//ref and @ to decorate self, which intends to distinguish view and external funcs.

//===constructors===
//special type of func that only runs once when deploying a contract, and can be used to initialize the state 
//of a contract.

#[constructor]
fn constructor(ref self: ContractState, owner:Person){
    self.names.write(owner.address, owner.name);
    self.total_name.write(1);
    self.owner.write(owner);
}
//a contract cant have more than one constructor.
//the constructor func must be named constructor, and must be annotated with the #[constructor] attribute.
//constructor func might take args, whcih are passed when deploying the contract.
//==constructor function must take self as a first arg, corresponding to the state of the contract, generally
//passed by reference with the ref keyword to be able to modify the contract's state 

//===public funcs====
//public funcs are accessible from outside of the contract.they are usually defined inside an implementation
//block annotated with the #[abi(embed_v0)] attribute, but might also be defined independently under the  
//#[external(v0)] attribute.

//the #[abi(embed_v0)] attribute means that all funcs embedded inside it are implementations of the starknet interface
//of the contract and therefore potential entry points.

//annotating an impl block with the #[abi(embed_v0)] attribute only affects the visibility(public vs private/internal)
//of the funcs it contains, but it doesnt inform us on the ability of these funcs to modify the state of the contract.


//public funcs inside an impl block===
#[abi(embed_v0)]
impl NameRegistry of super::INameRegistry<ContractState> {
    fn store_name(ref self: ContractState, name: felt252, registration_type: RegistrationType) {
        let caller = get_caller_address();
        self._store_name(caller, name, registration_type);
    }

    fn get_name(self:@ContractState, address:ContractAddress) -> felt252 {
        self.names.read(address)
    }
    fn get_owner(self:@ContractState) -> Person {
        self.owner.read()
    }
}
//similarly to the constructor func, all public funcs either standalone funcs annotated with #[external(v0)]
//of funcs within an impl block annotated with the # [abi(embed_v0)] attribute must take self as a first argument.
//==note: its not the case for private funcs.

//===externakl funcs===
//external funcs are public funcs where the self:ContractState arg is passed by reference with the ref keyword
//which exposes both the read and write access to storage variables. this allows modifying the state of the contract
//via self directly.

fn store_name(ref self:ContractState, name:felt252, registration_type:RegistrationType){
    let caller = get_caller_address();
    self._store_name(caller, name, registration_type);
}

//==view funcs===
//view funcs are public funcs where the self:ContractState argument is passed as a snapshot, which only allows the
//read access to storage variables, and restricts writes to storage made via self by causing compilation errors.
//compiler will mark their state_mutability to view, preventing any state modification thru self direclty.
fn get_name(self:@ContractState, address:ContractAddress) -> felt252 {
    self.names.read(address)
}
//==state mutability of public funcs==
//passing self as a snapshot only restricts the storage write access via self at compile time. it doesnot prevent
//state modification via direct system calls, nor calling another contract that would modify the state.
//read-only property of view funcs is not enforced on starknet, and sending a transaction targeting 
//aview function could chnage the state.
//==even though external and view funcs are distinguished by cairo compiler, all public funcs can be called
//thru an invoke transaction and have the potential to modify states on starkent.
//also. all public funcs can be queried via starknet_call on starknet, which will not create a transaction and
//hence will not change the state.

//===standalone public funcs===
//its possible to define public fucns outside of an implementation of a trait, using the #[external(v0)] attribute
//this will automatically generate the corresponding ABI, allowing these standalone public funcs to be callable
//by anyone from the outside.these funcs can also be called  from within the contract just like any function in 
//starkent contracts. first parameter must be self.

//==standalone public func
#[external(v0)]
fn get_contract_name(self:@ContractState) -> felt252 {
    'Name Registry'
}


//==private funcs===
//funcs that are not defined with the #[external(v0)] attribute or inside a block annotated with the #[abi(embed_v0)]
//attribute are private funcs(also called internal funcs). they can only be called from within the contract.

//==they can be grouped in a dedicated impl block or just be added as free funcs inside the contract module.
//==the #[generate_trait] attribute is mostly used to define private impl blocks. it might also be used
//in addition to #[abi(per_item)] to define the various entrypoints of a contract.
