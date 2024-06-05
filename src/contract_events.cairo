//===contract events===
//events are custom data structures emitted by smart contracts during execution.they provide a way for smart
//contracts to communicate with the external world by logging info about specific occurences in a contract.

//defining events==, all events in acontract are defined under the Event enum which must implement the
//starknet::Event trait. this trait is defined in library as follows.

trait Event<T> {
    fn append_keys_and_data(self:T, ref keys:Array<felt252>, ref data: Array<felt252>);
    fn deserialize(ref keys: Span<felt252>, ref data: Span<felt252>) -> Option<T>;
}

//the #[derive(starknet::Event)] attribute causes the compiler to generate an implementation for the above trait

#[event]
#[derive(Drop, starknet::Event)]
enum Event {
    StoredName: StoredName,
}
//each variant of the Event enum has to be a struct or an enum, and each variant needs to implement 
//the starknet::Event trait itself. moreover the members of these variants must implement the Serde trait. as keys/data
//are added to the event using a serialization process.

//===indexing event fields allows for more efficient queries and filtering of events.