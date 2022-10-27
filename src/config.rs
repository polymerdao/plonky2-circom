use std::mem::size_of;

extern crate ff;
use ff::*;
use num::bigint::BigUint;
use num::ToPrimitive;
use poseidon_rs::{Fr, Poseidon};

use plonky2::hash::hash_types::{HashOut, RichField};
use plonky2::hash::hashing::{compress, hash_n_to_hash_no_pad, PlonkyPermutation, SPONGE_WIDTH};
use plonky2::plonk::config::Hasher;

pub struct PoseidonBN128Permutation;
impl<F: RichField> PlonkyPermutation<F> for PoseidonBN128Permutation {
    fn permute(input: [F; SPONGE_WIDTH]) -> [F; SPONGE_WIDTH] {
        assert_eq!(SPONGE_WIDTH, 12);

        let mut state = vec![0u8; SPONGE_WIDTH * size_of::<u64>()];
        for i in 0..SPONGE_WIDTH {
            // println!("{}", input[i].to_canonical_biguint().to_str_radix(16));
            state[i * size_of::<u64>()..(i + 1) * size_of::<u64>()]
                .copy_from_slice(&input[i].to_canonical_u64().to_be_bytes());
        }

        const WIDTH: usize = 4;
        const NUM_GL_ELEM: usize = SPONGE_WIDTH / WIDTH;
        let mut arr = [Fr::zero(); WIDTH];
        for i in 0..WIDTH {
            let bi = BigUint::from_bytes_be(
                &state
                    [i * NUM_GL_ELEM * size_of::<u64>()..(i + 1) * NUM_GL_ELEM * size_of::<u64>()],
            );
            // println!("{}", bi.to_str_radix(16));
            arr[i] = Fr::from_str(&bi.to_str_radix(10)).unwrap();
            // println!("{}", arr[i].to_string())
        }
        let poseidon = Poseidon::new();
        let h = poseidon.permute(arr.clone());
        let mut res = [F::ZERO; SPONGE_WIDTH];
        for i in 0..WIDTH {
            let gls = h[i].to_string();
            // println!("{}", gls);
            for j in 0..NUM_GL_ELEM {
                let gl = u64::from_str_radix(
                    &gls[5 + 2 * size_of::<u64>() + j * 2 * size_of::<u64>()
                        ..5 + 2 * size_of::<u64>() + (j + 1) * 2 * size_of::<u64>()],
                    16,
                )
                .unwrap();
                res[i * NUM_GL_ELEM + j] = F::from_canonical_u64(gl % F::order().to_u64().unwrap());
                // println!("{}", res[i * NUM_GL_ELEM + j].to_canonical_biguint().to_str_radix(16));
            }
        }
        res
    }
}

#[derive(Copy, Clone, Debug, Eq, PartialEq)]
pub struct PoseidonBN128Hash;
impl<F: RichField> Hasher<F> for PoseidonBN128Hash {
    const HASH_SIZE: usize = 4 * 8;
    type Hash = HashOut<F>;
    type Permutation = PoseidonBN128Permutation;

    fn hash_no_pad(input: &[F]) -> Self::Hash {
        hash_n_to_hash_no_pad::<F, Self::Permutation>(input)
    }

    fn hash_public_inputs(input: &[F]) -> Self::Hash {
        PoseidonBN128Hash::hash_no_pad(input)
    }

    fn two_to_one(left: Self::Hash, right: Self::Hash) -> Self::Hash {
        compress::<F, Self::Permutation>(left, right)
    }
}

#[cfg(test)]
mod tests {
    use anyhow::Result;
    use plonky2::field::types::Field;
    use plonky2::plonk::config::{GenericConfig, Hasher, PoseidonGoldilocksConfig};

    use crate::config::PoseidonBN128Hash;

    #[test]
    fn test_poseidon_bn128() -> Result<()> {
        const D: usize = 2;
        type C = PoseidonGoldilocksConfig;
        type F = <C as GenericConfig<D>>::F;

        let mut v = Vec::new();
        v.push(F::from_canonical_u64(8917524657281059100u64));
        v.push(F::from_canonical_u64(13029010200779371910u64));
        v.push(F::from_canonical_u64(16138660518493481604u64));
        v.push(F::from_canonical_u64(17277322750214136960u64));
        v.push(F::from_canonical_u64(1441151880423231822u64));
        let h = PoseidonBN128Hash::hash_no_pad(&v);
        assert_eq!(h.elements[0].0, 16736853722845225729u64);
        assert_eq!(h.elements[1].0, 1446699130810517790u64);
        assert_eq!(h.elements[2].0, 15445626857806971868u64);
        assert_eq!(h.elements[3].0, 6331160477881736675u64);

        Ok(())
    }
}
