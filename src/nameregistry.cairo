use starknet::ContractAddress;

#[starknet::interface]
pub trait INameRegistry<TContractState> {
    fn store_name(
        ref self: TContractState, name: felt252, registration_type: NameRegistry::RegistrationType
    );
    fn get_name(self:@TContractState, address:ContractAddress) -> felt252;
    fn get_owner(self:@TContractState) -> NameRegistry::Person;
}
//contract interafces,this trait must be generic over the TContractState type.
//it is rqd for funcs to access the contract's storage. so that they can read and write to it.

#[starknet::contract]
mod NameRegistry {
    use starknet::{ContractAddress, get_caller_address, storage_access::StorageBaseAddress};
    
    #[storage]
    struct Storage {
        names:LegacyMap::<ContractAddress, felt252>,
        owner:Person,
        registration_type:LegacyMap::<ContractAddress,RegistrationType>,
        total_names:u128,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredName: StoredName,
    }
    #[derive(Drop, starknet::Event)]
    struct StoredName {
        #[key]
        user:ContractAddress,
        name:felt252,
    }

    //indexing events fields allows for more efficient queries and filtering of events. to index a field as a 
    //key of an event. simply annotate it with the #[key], by so doing any indexed field will allow queries of events
    //that contain a given value for that field with O(log(n)) time complexity, while non indexed fields require
    //any query to iterate over all events. providing O(n) time complexity. 
    #[derive(Drop, Serde, starknet::Store)]
    pub struct Person {
        address:ContractAddress,
        name:felt252,
    }
    //above we want to store  a Person struct in storage, which is only possible by implementing the Store trait for the
    //Person type.this can be simply achieved by adding a #  [derive(starknet::Store)]
    //attribute on top of our struct defn
    #[derive(Drop, Serde, starknet::Store)]
    pub enum RegistrationType {
        finite:u64,
        infinite
    }
    //similarly, Enums can only be written to storage if they implement the Store trait, which can be trivially
    //derived aslong as all associated types implement the Store trait.
    //you might have noticed that we also derived Drop and Serde on our customtypes.both of them are rqd for 
    //properly serializing args passed to entry points and deserializing their outputs.
    #[constructor]
    fn constructor(ref self:ContractState, owner:Person){
        self.names.write(owner.address, owner.name); //self.names.write(user, name);
        self.total_names.write(1);
        self.owner.write(owner);//number of args depends on the storage variable type. here we only pass in the
        //value to write to the owner variable as it is a simple variable.
    }
    //public funcs inside an impl block
    #[abi(embed_v0)]
    impl NameRegistry of super::INameRegistry<ContractState> {
        fn store_name(ref self: ContractState, name: felt252, registration_type: RegistrationType) {
            let caller = get_caller_address();
            self._store_name(caller, name, registration_type);
        }
        fn get_name(self: @ContractState, address:ContractAddress) -> felt252 {
            self.names.read(address)
        }
        fn get_owner(self:@ContractState) -> Person {
            self.owner.read()
        }
    }
    //standalone public function
    #[external(v0)]
    fn get_contract_name(self:@ContractState) -> felt252 {
        'Name Registry'
    }
    //could be a group of funcs about a same topic
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _store_name(
            ref self:ContractState,
            user: ContractAddress,
            name:felt252,
            registration_type:RegistrationType
        ) {
            let total_names = self.total_names.read();
            self.names.write(user, name);
            self.registration_type.write(user, registration_type);
            self.total_names.write(total_names + 1);
            self.emit(StoredName {user:user, name:name});
            //after defining events, we can emit them using self.emit 
            //emit func is called on self and takes a reference to self, ie state modification capabilities are rqd.
            //therefore not possible to emit events in view funcs.
        }
    }
    //free function
    fn get_owner_storage_address(self:@ContractState) -> StorageBaseAddress {
        self.owner.address()
    }
}
//the most common way for interacting with a contract's storage is thru storage variables
//storage variables allow u to store data that will be stored in the contract's storage that is itself
//stored on the block chain.these data are persistent and can be accessed and potentially modified anytime
//once the contract is deployed.
//==storage variables in starknet contracts are stored in a special struct called Storage.

//==The Storage struct is a struct like any other, except that it must be annotated with the #[storage] attribute
//this annotation tells the compiler to generate the rqd code to interact with the block chain state, and allows u 
//to define storage mappings using the dedicated LegacyMap type.

//==variables declared in the Storage struct are not stored contiguosly but in diff locations in the contract's
//storage. the storage address of a particular variable is determined by the variable's name,
//and the eventual keys of the variable if it is a mapping.

//***addresses of storage variables====
//if the variable is a single value, the address is the sn_keccak hash of the ASCII encoding of the variable's name
//sn_keccak is Starknet's version of the Keccak256 hash func.whose output is truncated to 250 bits.

//==note: if the variable is composed of multiple values(tuple, astruct or an enum), we alos use the sn_keccak
///hash of the ASCII encoding of the variables name to determine the base address in storage
/// 
/// ==if the variable is a mapping with a key, the address of the vale at key k is h 
/// you can acess the address of a storage variable by calling the address function on the variable, which returns
/// a StorageBaseAddress value.
/// 
/// ===  self.owner.address()
/// 
/// ===interacting with storage variables===
/// variables stored in the Storage struct can be accessed and modified using the read and write funcs, resp.
/// ==to read the value of the owner storage variable
/// 
/// ==to read the value of the storage variable names, which is a mapping from ContractAddress to felt252
/// 
///==storing custom types===
//the STore trait defined in the starknet::storage_access module, is used to sepcify 
//how a type should be stored in storage, inorder for a type to be stored in storage, it must implement the Store 
//trait.most types from the core library, such as unsigned integers(u8, u128, u256..), felt252, bool, ByteArray,
//ContractAddress implement the STore trait and can thus be stored without further action.

//===structs storage layout=====
//on starkknet structs are stored in storage as a sequence of primitive types. the elements of the struct
//are stored in the same order as they are defined 

//==note: tuples are similarly stored in contract's storage with the first element of the tuple being stored
//at the base address, and subsequent elements stored contiguosly.

//===enums storage layout===
//when you store an enum variant, what you're essentially storing is the variant's index and eventual associated
//values