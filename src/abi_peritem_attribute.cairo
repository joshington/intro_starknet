//===[abi(per_item)] attribute
//==u can also define the entrypoint type of funcs individually inside the impl block using the #[abi(per_item)]
//attribute on top of your impl.it is often used with the #[generate_trait]
//attribute , as it allows you to define entrypoints without an explicit interface.in this case the funcs will not
//be grouped under an impl in the abi. note that when using #[abi(per_item)] attribute, public fucns need to be annotated
//with the #[external(v0)] attribute- otherwise, they will not be exposed and will be considered as private funcs.

#[starknet::contract]
mod AbiAttribute {
    #[storage]
    struct Storage {}

    #[abi(per_item)]
    #[generate_trait]
    impl SomeImpl of SomeTrait {
        #[constructor]
        //constructor func
        fn constructor(ref self: ContractState) {}

        #[external(v0)]
        //public func
        fn external_function(ref self:ContractState, arg1:felt252) {}

        #[li_handler]
        //l1_handler func
        fn handle_message(ref self:ContractState, from_address:felt252, arg:felt252) {}

        //internal func
        fn internal_function(self:@ContractState) {}
    }
}