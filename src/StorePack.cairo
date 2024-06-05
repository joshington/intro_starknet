//cairo provides StorePacking Trait to enable packing struct fields into fewer storage slots.
//StorePacking<T, Packed> - generic trait taking the type u want to pack (T) and the destination type(PackedT) as params
//==> provides pack and unpack


use starknet::storage_access::StorePacking;

#[derive(Drop, Serde)]
struct Sizes {
    tiny: u8,
    small:u32,
    medium:u64,
}

const TWO_POW_8: u128 = 0x100;
const TWO_POW_40: u128 = 0x10000000000;

//used to shift left in the pack function and shift right in the unpack function.

const MASK_8: u128 = 0xff;
const MASK_32: u128 = 0xffffffff;
//MASK_8 and MASK_32 are used to isolate a variable in the unpack function
///all the variables from the stroage are converted to u128 to be able to use bitwise operators.






impl SizesStorePacking of StorePacking<Sizes, u128> {
    fn pack(value: Sizes) -> u128 {
        value.tiny.into() + (value.small.into() * TWO_POW_8) + (value.medium.into() * TWO_POW_40)
    }

    fn unpack(value: u128) -> Sizes {
        let tiny = value & MASK_8;
        let small = (value / TWO_POW_8) & MASK_32;
        let medium = (value / TWO_POW_40);

        Sizes {
            tiny: tiny.try_into().unwrap(),
            small: small.try_into().unwrap(),
            medium: medium.try_into().unwrap(),
        }
    }
}

#[starknet::contract]
mod SizeFactory {
    use super::Sizes;
    use super::SizesStorePacking; //must to import it.

    #[storage]
    struct Storage {
        remaining_sizes: Sizes
    }

    #[abi(embed_v0)]
    fn update_sizes(ref self: ContractState, sizes: Sizes) {
        //will automatically pack the struct into a single u128
        self.remaining_sizes.write(sizes);
    }

    #[abi(embed_v0)]
    fn get_sizes(ref self:ContractState) -> Sizes {
        //this will automatically unpack the packed-representation into the Sizes struct.
        self.remaining_sizes.read()
    }
}