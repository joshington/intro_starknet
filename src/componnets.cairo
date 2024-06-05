//component => separate module that can contain storage, events and functions
//unlike a contract, a cpt cannot be delcared or deployed.
//its logic will eventually be part of the contract's bytecode it has been embedded in


//cpt => storage variables, events and external and internal funcs
//unike acontract, a cpt cannot be deployed on its owne. the cpt code becomes part of the contract its embedded to.

//actual implementation of the cpt's external logic is done in an impl block marked as 
// #[embeddable_as(name)]. usually this impl block will be an implementation of the trait defining the
//interface of the cpt. ==> name here refers to the cpt. it is diff than the name of your impl.

//===Ownable component===