

//==to embed the Ownable Cpt defined above, we would do the following

#[starknet::contract]
mod OwnableCounter {
    use listing_01_ownable::component::ownable_component;

    component!(path: ownable_component, storage:ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = ownable_component::Ownable<ContractState>;

    impl OwnableInternalImpl = ownable_component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter:u128,
        #[substorage(v0)]
        ownable: ownable_component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: ownable_component::Event
    }

    #[abi(embed_v0)]
    fn foo(ref self:ContractState) {
        self.ownable.assert_only_owner();
        self.counter.write(self.counter.read() + 1);
    }
}
//cpt logic is now seamlessly part of the contract we can now interact with the cpts functions externally
//by calling them using the IOwnableDispatcher instantiated with the contract's address.