//to declare a mapping, use the LegacyMap type enclosed in angle brackets, specifying the key and value types.
//can aswell create more complex mappings with multiple keys.

#[storage]
struct Storage {
    allowances:LegacyMap::<(ContractAddress, ContractAddress), u256>
}
//if the key of a mapping is astruct, each element of the struct constitutes a key.
//moreover the struct should implement the Hash trait, which can be derived with the #[derive(Hash)] attribute.