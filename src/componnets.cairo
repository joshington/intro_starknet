//component => separate module that can contain storage, events and functions
//unlike a contract, a cpt cannot be delcared or deployed.
//its logic will eventually be part of the contract's bytecode it has been embedded in


//cpt => storage variables, events and external and internal funcs
//unike acontract, a cpt cannot be deployed on its owne. the cpt code becomes part of the contract its embedded to.

//actual implementation of the cpt's external logic is done in an impl block marked as 
// #[embeddable_as(name)]. usually this impl block will be an implementation of the trait defining the
//interface of the cpt. ==> name here refers to the cpt. it is diff than the name of your impl.

//===Ownable component===

#[starknet::interface]
trait IOwnable<TContractState> {
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner:ContractAddress);
    fn renounce_ownership(ref self: TContractState);
}

//using cpts inside a contract--- the major strength of cpts is how it allows reusing already built primitives
//inside your contracts with restricted amount of boilerplate. to intergrate a cpt u need to.
//1. declare it with the component!() macro, specifying
//1. the path to the cpt path::to::component.
//2.the name of the variable in your contract's storage referring to this cpt's storage(e.g ownable)
//3. name of the variant in your contract's event enum referring to this cpt's events. e.g(OwnableEvent)
//storage variable must be annotated with the #[substorage(v0)] attribute.




#[starknet::component]
pub mod ownable_component {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use super::Errors;
    use core::num::traits::Zero;

    #[storage]
    struct Storage {
        owner: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OwnershipTransferred: OwnershipTransferred
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner:ContractAddress,
        new_owner: ContractAddress,
    }

    // #[embeddable_as] attribute is used to mark the impl as embeddable inside a contract.it allows us to specify
    //the name of the impl that will be used in the contract to refer to this cpt.in this cpt wil be referred to as
    //Ownable in contracts embedding it
    #[embeddable_as(Ownable)]
    impl OwnableImpl<
        TContractState, +HasComponent<TContractState>
    > of super::IOwnable<ComponentState<TContractState>> {
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }
        fn transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner:ContractAddress
        ) {
            assert(!new_owner.is_zero(), Errors::ZERO_ADDRESS_OWNER);
            self.assert_only_owner();
            self._transfer_ownership(new_owner);
        }
        fn renounce_ownership(ref self: ComponentState<TContractState>) {
            self.assert_only_owner();
            self._transfer_ownership(Zero::zero());
        }
    }
    //==exposing the assert_only_owner as part of the interface wouldnt make sense, as its only meant to be 
    //uses internally by a contract emmbeding the cpt.
    //TContractState must implement the HasComponent<T> trait. allows us to use the cpt in any contract,
    //aslong as the contract implements the HasComponent trait.

    //major difference from a regular smart contract is that access to storage and events is done via
    //the generic ComponentState<T
    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, owner:ContractAddress) {
            self._transfer_ownership(owner);
        }
        fn assert_only_owner(self:@ComponentState<TContractState>){
            let owner:ContractAddress = self.owner.read();
            let caller:ContractAddress = get_caller_address();
            assert(!caller.is_zero(), Errors::ZERO_ADDRESS_CALLER);
            assert(caller == owner, Errors::NOT_OWNER);
        }
        fn _transfer_ownership(
            ref self:ComponentState<TContractState>, new_owner: ContractAddress
        ) {
            let previous_owner:ContractAddress = self.owner.read();
            self.owner.write(new_owner);
            self 
                .emit(
                    OwnershipTransferred { previous_owner: previous_owner, new_owner: new_owner }
                );
        }
    }
}