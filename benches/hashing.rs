use criterion::{criterion_group, criterion_main, BatchSize, Criterion};
use plonky2::field::goldilocks_field::GoldilocksField;
use plonky2::hash::hash_types::RichField;
use plonky2::hash::hashing::PlonkyPermutation;
use plonky2::hash::hashing::SPONGE_WIDTH;
use plonky2::hash::poseidon::PoseidonPermutation;
use plonky2_circom_verifier::config::PoseidonBN128Permutation;
use std::any::type_name;

pub(crate) fn bench_gl_poseidon<F: RichField>(c: &mut Criterion) {
    c.bench_function(
        &format!("goldilocks poseidon<{}, {SPONGE_WIDTH}>", type_name::<F>()),
        |b| {
            b.iter_batched(
                || F::rand_arr::<SPONGE_WIDTH>(),
                |state| PoseidonPermutation::permute(state),
                BatchSize::SmallInput,
            )
        },
    );
}

pub(crate) fn bench_bn128_poseidon<F: RichField>(c: &mut Criterion) {
    c.bench_function(
        &format!("bn128 poseidon<{}, {SPONGE_WIDTH}>", type_name::<F>()),
        |b| {
            b.iter_batched(
                || F::rand_arr::<SPONGE_WIDTH>(),
                |state| PoseidonBN128Permutation::permute(state),
                BatchSize::SmallInput,
            )
        },
    );
}

fn criterion_benchmark(c: &mut Criterion) {
    bench_gl_poseidon::<GoldilocksField>(c);
    bench_bn128_poseidon::<GoldilocksField>(c);
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
