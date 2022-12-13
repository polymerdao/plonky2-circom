use std::fmt::Write;

use anyhow::Result;
use log::Level;
use plonky2::field::extension::{Extendable, FieldExtension};
use plonky2::field::types::Field;
use plonky2::gates::noop::NoopGate;
use plonky2::hash::hash_types::RichField;
use plonky2::iop::witness::{PartialWitness, WitnessWrite};
use plonky2::plonk::circuit_builder::CircuitBuilder;
use plonky2::plonk::circuit_data::{
    CircuitConfig, CommonCircuitData, VerifierCircuitTarget, VerifierOnlyCircuitData,
};
use plonky2::plonk::config::GenericHashOut;
use plonky2::plonk::config::{AlgebraicHasher, GenericConfig, Hasher};
use plonky2::plonk::proof::ProofWithPublicInputs;
use plonky2::plonk::prover::prove;
use plonky2::util::timing::TimingTree;
use plonky2_util::log2_strict;
use serde::Serialize;

pub fn encode_hex(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        write!(&mut s, "{:02x}", b).unwrap();
    }
    s
}

fn recursive_proof<
    F: RichField + Extendable<D>,
    C: GenericConfig<D, F = F>,
    InnerC: GenericConfig<D, F = F>,
    const D: usize,
>(
    inner_proof: ProofWithPublicInputs<F, InnerC, D>,
    inner_vd: VerifierOnlyCircuitData<InnerC, D>,
    inner_cd: CommonCircuitData<F, D>,
    config: &CircuitConfig,
    min_degree_bits: Option<usize>,
    print_gate_counts: bool,
    print_timing: bool,
) -> Result<(
    ProofWithPublicInputs<F, C, D>,
    VerifierOnlyCircuitData<C, D>,
    CommonCircuitData<F, D>,
)>
where
    InnerC::Hasher: AlgebraicHasher<F>,
    [(); C::Hasher::HASH_SIZE]:,
{
    let mut builder = CircuitBuilder::<F, D>::new(config.clone());
    let mut pw = PartialWitness::new();
    let pt = builder.add_virtual_proof_with_pis::<InnerC>(&inner_cd);
    pw.set_proof_with_pis_target(&pt, &inner_proof);

    let inner_data = VerifierCircuitTarget {
        constants_sigmas_cap: builder.add_virtual_cap(inner_cd.config.fri_config.cap_height),
        circuit_digest: builder.add_virtual_hash(),
    };
    pw.set_cap_target(
        &inner_data.constants_sigmas_cap,
        &inner_vd.constants_sigmas_cap,
    );
    pw.set_hash_target(inner_data.circuit_digest, inner_vd.circuit_digest);

    builder.register_public_inputs(inner_data.circuit_digest.elements.as_slice());
    for i in 0..builder.config.fri_config.num_cap_elements() {
        builder.register_public_inputs(&inner_data.constants_sigmas_cap.0[i].elements);
    }
    builder.verify_proof::<InnerC>(&pt, &inner_data, &inner_cd);

    if print_gate_counts {
        builder.print_gate_counts(0);
    }

    if let Some(min_degree_bits) = min_degree_bits {
        // We don't want to pad all the way up to 2^min_degree_bits, as the builder will add a
        // few special gates afterward. So just pad to 2^(min_degree_bits - 1) + 1. Then the
        // builder will pad to the next power of two, 2^min_degree_bits.
        let min_gates = (1 << (min_degree_bits - 1)) + 1;
        for _ in builder.num_gates()..min_gates {
            builder.add_gate(NoopGate, vec![]);
        }
    }

    let data = builder.build::<C>();

    let mut timing = TimingTree::new("prove", Level::Debug);
    let proof = prove(&data.prover_only, &data.common, pw, &mut timing)?;
    if print_timing {
        timing.print();
    }

    println!("######################### recursive verify #########################");
    data.verify(proof.clone())?;

    Ok((proof, data.verifier_only, data.common))
}

#[derive(Serialize)]
pub struct VerifierConfig {
    hash_size: usize,
    field_size: usize,
    ext_field_size: usize,
    merkle_height_size: usize,

    num_wires_cap: usize,
    num_plonk_zs_partial_products_cap: usize,
    num_quotient_polys_cap: usize,

    // openings
    num_openings_constants: usize,
    num_openings_plonk_sigmas: usize,
    num_openings_wires: usize,
    num_openings_plonk_zs: usize,
    num_openings_plonk_zs_next: usize,
    num_openings_partial_products: usize,
    num_openings_quotient_polys: usize,

    // fri proof
    // .commit phase
    num_fri_commit_round: usize,
    fri_commit_merkle_cap_height: usize,
    // .query round
    num_fri_query_round: usize,
    // ..init
    num_fri_query_init_constants_sigmas_v: usize,
    num_fri_query_init_constants_sigmas_p: usize,
    num_fri_query_init_wires_v: usize,
    num_fri_query_init_wires_p: usize,
    num_fri_query_init_zs_partial_v: usize,
    num_fri_query_init_zs_partial_p: usize,
    num_fri_query_init_quotient_v: usize,
    num_fri_query_init_quotient_p: usize,
    // ..steps
    num_fri_query_step0_v: usize,
    num_fri_query_step0_p: usize,
    num_fri_query_step1_v: usize,
    num_fri_query_step1_p: usize,
    // .final poly
    num_fri_final_poly_ext_v: usize,
    // public inputs
    num_public_inputs: usize,
}

#[derive(Serialize)]
pub struct ProofForCircom {
    wires_cap: Vec<Vec<String>>,
    plonk_zs_partial_products_cap: Vec<Vec<String>>,
    quotient_polys_cap: Vec<Vec<String>>,

    openings_constants: Vec<Vec<String>>,
    openings_plonk_sigmas: Vec<Vec<String>>,
    openings_wires: Vec<Vec<String>>,
    openings_plonk_zs: Vec<Vec<String>>,
    openings_plonk_zs_next: Vec<Vec<String>>,
    openings_partial_products: Vec<Vec<String>>,
    openings_quotient_polys: Vec<Vec<String>>,

    fri_commit_phase_merkle_caps: Vec<Vec<Vec<String>>>,

    fri_query_init_constants_sigmas_v: Vec<Vec<String>>,
    fri_query_init_constants_sigmas_p: Vec<Vec<Vec<String>>>,
    fri_query_init_wires_v: Vec<Vec<String>>,
    fri_query_init_wires_p: Vec<Vec<Vec<String>>>,
    fri_query_init_zs_partial_v: Vec<Vec<String>>,
    fri_query_init_zs_partial_p: Vec<Vec<Vec<String>>>,
    fri_query_init_quotient_v: Vec<Vec<String>>,
    fri_query_init_quotient_p: Vec<Vec<Vec<String>>>,

    fri_query_step0_v: Vec<Vec<Vec<String>>>,
    fri_query_step0_p: Vec<Vec<Vec<String>>>,
    fri_query_step1_v: Vec<Vec<Vec<String>>>,
    fri_query_step1_p: Vec<Vec<Vec<String>>>,

    fri_final_poly_ext_v: Vec<Vec<String>>,
    fri_pow_witness: String,

    public_inputs: Vec<String>,
}

// TODO: The input should be CommonCircuitData
pub fn generate_verifier_config<
    F: RichField + Extendable<D>,
    C: GenericConfig<D, F = F>,
    const D: usize,
>(
    pwpi: &ProofWithPublicInputs<F, C, D>,
) -> anyhow::Result<VerifierConfig> {
    let proof = &pwpi.proof;
    assert_eq!(proof.opening_proof.query_round_proofs[0].steps.len(), 2);

    const HASH_SIZE: usize = 32;
    const FIELD_SIZE: usize = 8;
    const EXT_FIELD_SIZE: usize = 16;
    const MERKLE_HEIGHT_SIZE: usize = 1;

    let query_round_init_trees = &proof.opening_proof.query_round_proofs[0]
        .initial_trees_proof
        .evals_proofs;
    let query_round_steps = &proof.opening_proof.query_round_proofs[0].steps;

    let conf = VerifierConfig {
        hash_size: HASH_SIZE,
        field_size: FIELD_SIZE,
        ext_field_size: EXT_FIELD_SIZE,
        merkle_height_size: MERKLE_HEIGHT_SIZE,

        num_wires_cap: proof.wires_cap.0.len(),
        num_plonk_zs_partial_products_cap: proof.plonk_zs_partial_products_cap.0.len(),
        num_quotient_polys_cap: proof.quotient_polys_cap.0.len(),

        num_openings_constants: proof.openings.constants.len(),
        num_openings_plonk_sigmas: proof.openings.plonk_sigmas.len(),
        num_openings_wires: proof.openings.wires.len(),
        num_openings_plonk_zs: proof.openings.plonk_zs.len(),
        num_openings_plonk_zs_next: proof.openings.plonk_zs_next.len(),
        num_openings_partial_products: proof.openings.partial_products.len(),
        num_openings_quotient_polys: proof.openings.quotient_polys.len(),

        num_fri_commit_round: proof.opening_proof.commit_phase_merkle_caps.len(),
        fri_commit_merkle_cap_height: proof.opening_proof.commit_phase_merkle_caps[0].0.len(),
        num_fri_query_round: proof.opening_proof.query_round_proofs.len(),
        num_fri_query_init_constants_sigmas_v: query_round_init_trees[0].0.len(),
        num_fri_query_init_constants_sigmas_p: query_round_init_trees[0].1.siblings.len(),
        num_fri_query_init_wires_v: query_round_init_trees[1].0.len(),
        num_fri_query_init_wires_p: query_round_init_trees[1].1.siblings.len(),
        num_fri_query_init_zs_partial_v: query_round_init_trees[2].0.len(),
        num_fri_query_init_zs_partial_p: query_round_init_trees[2].1.siblings.len(),
        num_fri_query_init_quotient_v: query_round_init_trees[3].0.len(),
        num_fri_query_init_quotient_p: query_round_init_trees[3].1.siblings.len(),
        num_fri_query_step0_v: query_round_steps[0].evals.len(),
        num_fri_query_step0_p: query_round_steps[0].merkle_proof.siblings.len(),
        num_fri_query_step1_v: query_round_steps[1].evals.len(),
        num_fri_query_step1_p: query_round_steps[1].merkle_proof.siblings.len(),
        num_fri_final_poly_ext_v: proof.opening_proof.final_poly.coeffs.len(),

        num_public_inputs: pwpi.public_inputs.len(),
    };
    Ok(conf)
}

pub fn generate_proof_base64<
    F: RichField + Extendable<D>,
    C: GenericConfig<D, F = F>,
    const D: usize,
>(
    pwpi: &ProofWithPublicInputs<F, C, D>,
    conf: &VerifierConfig,
) -> anyhow::Result<String> {
    let mut proof_size: usize =
        (conf.num_wires_cap + conf.num_plonk_zs_partial_products_cap + conf.num_quotient_polys_cap)
            * conf.hash_size;

    let mut wires_cap = vec![vec!["0".to_string(); 4]; conf.num_wires_cap];
    for i in 0..conf.num_wires_cap {
        let h = pwpi.proof.wires_cap.0[i].to_vec();
        for j in 0..h.len() {
            wires_cap[i][j] = h[j].to_canonical_u64().to_string();
        }
    }

    let mut plonk_zs_partial_products_cap =
        vec![vec!["0".to_string(); 4]; conf.num_plonk_zs_partial_products_cap];
    for i in 0..conf.num_plonk_zs_partial_products_cap {
        let h = pwpi.proof.plonk_zs_partial_products_cap.0[i].to_vec();
        for j in 0..h.len() {
            plonk_zs_partial_products_cap[i][j] = h[j].to_canonical_u64().to_string();
        }
    }

    let mut quotient_polys_cap = vec![vec!["0".to_string(); 4]; conf.num_quotient_polys_cap];
    for i in 0..conf.num_quotient_polys_cap {
        let h = pwpi.proof.quotient_polys_cap.0[i].to_vec();
        for j in 0..h.len() {
            quotient_polys_cap[i][j] = h[j].to_canonical_u64().to_string();
        }
    }

    proof_size += (conf.num_openings_constants
        + conf.num_openings_plonk_sigmas
        + conf.num_openings_wires
        + conf.num_openings_plonk_zs
        + conf.num_openings_plonk_zs_next
        + conf.num_openings_partial_products
        + conf.num_openings_quotient_polys)
        * conf.ext_field_size;

    let mut openings_constants = vec![vec!["0".to_string(); 2]; conf.num_openings_constants];
    for i in 0..conf.num_openings_constants {
        openings_constants[i][0] = pwpi.proof.openings.constants[i].to_basefield_array()[0]
            .to_canonical_u64()
            .to_string();
        openings_constants[i][1] = pwpi.proof.openings.constants[i].to_basefield_array()[1]
            .to_canonical_u64()
            .to_string();
    }
    let mut openings_plonk_sigmas = vec![vec!["0".to_string(); 2]; conf.num_openings_plonk_sigmas];
    for i in 0..conf.num_openings_plonk_sigmas {
        openings_plonk_sigmas[i][0] = pwpi.proof.openings.plonk_sigmas[i].to_basefield_array()[0]
            .to_canonical_u64()
            .to_string();
        openings_plonk_sigmas[i][1] = pwpi.proof.openings.plonk_sigmas[i].to_basefield_array()[1]
            .to_canonical_u64()
            .to_string();
    }
    let mut openings_wires = vec![vec!["0".to_string(); 2]; conf.num_openings_wires];
    for i in 0..conf.num_openings_wires {
        openings_wires[i][0] = pwpi.proof.openings.wires[i].to_basefield_array()[0]
            .to_canonical_u64()
            .to_string();
        openings_wires[i][1] = pwpi.proof.openings.wires[i].to_basefield_array()[1]
            .to_canonical_u64()
            .to_string();
    }
    let mut openings_plonk_zs = vec![vec!["0".to_string(); 2]; conf.num_openings_plonk_zs];
    for i in 0..conf.num_openings_plonk_zs {
        openings_plonk_zs[i][0] = pwpi.proof.openings.plonk_zs[i].to_basefield_array()[0]
            .to_canonical_u64()
            .to_string();
        openings_plonk_zs[i][1] = pwpi.proof.openings.plonk_zs[i].to_basefield_array()[1]
            .to_canonical_u64()
            .to_string();
    }
    let mut openings_plonk_zs_next =
        vec![vec!["0".to_string(); 2]; conf.num_openings_plonk_zs_next];
    for i in 0..conf.num_openings_plonk_zs_next {
        openings_plonk_zs_next[i][0] = pwpi.proof.openings.plonk_zs_next[i].to_basefield_array()[0]
            .to_canonical_u64()
            .to_string();
        openings_plonk_zs_next[i][1] = pwpi.proof.openings.plonk_zs_next[i].to_basefield_array()[1]
            .to_canonical_u64()
            .to_string();
    }
    let mut openings_partial_products =
        vec![vec!["0".to_string(); 2]; conf.num_openings_partial_products];
    for i in 0..conf.num_openings_partial_products {
        openings_partial_products[i][0] = pwpi.proof.openings.partial_products[i]
            .to_basefield_array()[0]
            .to_canonical_u64()
            .to_string();
        openings_partial_products[i][1] = pwpi.proof.openings.partial_products[i]
            .to_basefield_array()[1]
            .to_canonical_u64()
            .to_string();
    }
    let mut openings_quotient_polys =
        vec![vec!["0".to_string(); 2]; conf.num_openings_quotient_polys];
    for i in 0..conf.num_openings_quotient_polys {
        openings_quotient_polys[i][0] = pwpi.proof.openings.quotient_polys[i].to_basefield_array()
            [0]
        .to_canonical_u64()
        .to_string();
        openings_quotient_polys[i][1] = pwpi.proof.openings.quotient_polys[i].to_basefield_array()
            [1]
        .to_canonical_u64()
        .to_string();
    }

    proof_size += (conf.num_fri_commit_round * conf.fri_commit_merkle_cap_height) * conf.hash_size;

    let mut fri_commit_phase_merkle_caps =
        vec![
            vec![vec!["0".to_string(); 4]; conf.fri_commit_merkle_cap_height];
            conf.num_fri_commit_round
        ];
    for i in 0..conf.num_fri_commit_round {
        let h = pwpi.proof.opening_proof.commit_phase_merkle_caps[i].flatten();
        assert_eq!(h.len(), 4 * conf.fri_commit_merkle_cap_height);
        for j in 0..conf.fri_commit_merkle_cap_height {
            for k in 0..4 {
                fri_commit_phase_merkle_caps[i][j][k] = h[j * 4 + k].to_canonical_u64().to_string();
            }
        }
    }

    proof_size += conf.num_fri_query_round
        * ((conf.num_fri_query_init_constants_sigmas_v
            + conf.num_fri_query_init_wires_v
            + conf.num_fri_query_init_zs_partial_v
            + conf.num_fri_query_init_quotient_v)
            * conf.field_size
            + (conf.num_fri_query_init_constants_sigmas_p
                + conf.num_fri_query_init_wires_p
                + conf.num_fri_query_init_zs_partial_p
                + conf.num_fri_query_init_quotient_p)
                * conf.hash_size
            + conf.merkle_height_size * 4);

    proof_size += conf.num_fri_query_round
        * (conf.num_fri_query_step0_v * conf.ext_field_size
            + conf.num_fri_query_step0_p * conf.hash_size
            + conf.merkle_height_size
            + conf.num_fri_query_step1_v * conf.ext_field_size
            + conf.num_fri_query_step1_p * conf.hash_size
            + conf.merkle_height_size);

    let mut fri_query_init_constants_sigmas_v =
        vec![
            vec!["0".to_string(); conf.num_fri_query_init_constants_sigmas_v];
            conf.num_fri_query_round
        ];
    let mut fri_query_init_wires_v =
        vec![vec!["0".to_string(); conf.num_fri_query_init_wires_v]; conf.num_fri_query_round];
    let mut fri_query_init_zs_partial_v =
        vec![vec!["0".to_string(); conf.num_fri_query_init_zs_partial_v]; conf.num_fri_query_round];
    let mut fri_query_init_quotient_v =
        vec![vec!["0".to_string(); conf.num_fri_query_init_quotient_v]; conf.num_fri_query_round];

    let mut fri_query_init_constants_sigmas_p =
        vec![
            vec![vec!["0".to_string(); 4]; conf.num_fri_query_init_constants_sigmas_p];
            conf.num_fri_query_round
        ];
    let mut fri_query_init_wires_p =
        vec![
            vec![vec!["0".to_string(); 4]; conf.num_fri_query_init_wires_p];
            conf.num_fri_query_round
        ];
    let mut fri_query_init_zs_partial_p =
        vec![
            vec![vec!["0".to_string(); 4]; conf.num_fri_query_init_zs_partial_p];
            conf.num_fri_query_round
        ];
    let mut fri_query_init_quotient_p =
        vec![
            vec![vec!["0".to_string(); 4]; conf.num_fri_query_init_quotient_p];
            conf.num_fri_query_round
        ];

    let mut fri_query_step0_v =
        vec![vec![vec!["0".to_string(); 2]; conf.num_fri_query_step0_v]; conf.num_fri_query_round];
    let mut fri_query_step1_v =
        vec![vec![vec!["0".to_string(); 2]; conf.num_fri_query_step1_v]; conf.num_fri_query_round];
    let mut fri_query_step0_p =
        vec![vec![vec!["0".to_string(); 4]; conf.num_fri_query_step0_p]; conf.num_fri_query_round];
    let mut fri_query_step1_p =
        vec![vec![vec!["0".to_string(); 4]; conf.num_fri_query_step1_p]; conf.num_fri_query_round];

    for i in 0..conf.num_fri_query_round {
        assert_eq!(
            pwpi.proof.opening_proof.query_round_proofs[i]
                .initial_trees_proof
                .evals_proofs
                .len(),
            4
        );
        for j in 0..conf.num_fri_query_init_constants_sigmas_v {
            fri_query_init_constants_sigmas_v[i][j] = pwpi.proof.opening_proof.query_round_proofs
                [i]
                .initial_trees_proof
                .evals_proofs[0]
                .0[j]
                .to_canonical_u64()
                .to_string();
        }
        for j in 0..conf.num_fri_query_init_wires_v {
            fri_query_init_wires_v[i][j] = pwpi.proof.opening_proof.query_round_proofs[i]
                .initial_trees_proof
                .evals_proofs[1]
                .0[j]
                .to_canonical_u64()
                .to_string();
        }
        for j in 0..conf.num_fri_query_init_zs_partial_v {
            fri_query_init_zs_partial_v[i][j] = pwpi.proof.opening_proof.query_round_proofs[i]
                .initial_trees_proof
                .evals_proofs[2]
                .0[j]
                .to_canonical_u64()
                .to_string();
        }
        for j in 0..conf.num_fri_query_init_quotient_v {
            fri_query_init_quotient_v[i][j] = pwpi.proof.opening_proof.query_round_proofs[i]
                .initial_trees_proof
                .evals_proofs[3]
                .0[j]
                .to_canonical_u64()
                .to_string();
        }
        for j in 0..conf.num_fri_query_init_constants_sigmas_p {
            let h = pwpi.proof.opening_proof.query_round_proofs[i]
                .initial_trees_proof
                .evals_proofs[0]
                .1
                .siblings[j]
                .to_vec();
            assert_eq!(h.len(), 4);
            for k in 0..4 {
                fri_query_init_constants_sigmas_p[i][j][k] = h[k].to_canonical_u64().to_string();
            }
        }
        for j in 0..conf.num_fri_query_init_wires_p {
            let h = pwpi.proof.opening_proof.query_round_proofs[i]
                .initial_trees_proof
                .evals_proofs[1]
                .1
                .siblings[j]
                .to_vec();
            assert_eq!(h.len(), 4);
            for k in 0..4 {
                fri_query_init_wires_p[i][j][k] = h[k].to_canonical_u64().to_string();
            }
        }
        for j in 0..conf.num_fri_query_init_zs_partial_p {
            let h = pwpi.proof.opening_proof.query_round_proofs[i]
                .initial_trees_proof
                .evals_proofs[2]
                .1
                .siblings[j]
                .to_vec();
            assert_eq!(h.len(), 4);
            for k in 0..4 {
                fri_query_init_zs_partial_p[i][j][k] = h[k].to_canonical_u64().to_string();
            }
        }
        for j in 0..conf.num_fri_query_init_quotient_p {
            let h = pwpi.proof.opening_proof.query_round_proofs[i]
                .initial_trees_proof
                .evals_proofs[3]
                .1
                .siblings[j]
                .to_vec();
            assert_eq!(h.len(), 4);
            for k in 0..4 {
                fri_query_init_quotient_p[i][j][k] = h[k].to_canonical_u64().to_string();
            }
        }
        for j in 0..conf.num_fri_query_step0_v {
            fri_query_step0_v[i][j][0] = pwpi.proof.opening_proof.query_round_proofs[i].steps[0]
                .evals[j]
                .to_basefield_array()[0]
                .to_canonical_u64()
                .to_string();
            fri_query_step0_v[i][j][1] = pwpi.proof.opening_proof.query_round_proofs[i].steps[0]
                .evals[j]
                .to_basefield_array()[1]
                .to_canonical_u64()
                .to_string();
        }
        for j in 0..conf.num_fri_query_step1_v {
            fri_query_step1_v[i][j][0] = pwpi.proof.opening_proof.query_round_proofs[i].steps[1]
                .evals[j]
                .to_basefield_array()[0]
                .to_canonical_u64()
                .to_string();
            fri_query_step1_v[i][j][1] = pwpi.proof.opening_proof.query_round_proofs[i].steps[1]
                .evals[j]
                .to_basefield_array()[1]
                .to_canonical_u64()
                .to_string();
        }
        assert_eq!(
            pwpi.proof.opening_proof.query_round_proofs[i].steps.len(),
            2
        );
        for j in 0..conf.num_fri_query_step0_p {
            let h = pwpi.proof.opening_proof.query_round_proofs[i].steps[0]
                .merkle_proof
                .siblings[j]
                .to_vec();
            assert_eq!(h.len(), 4);
            for k in 0..4 {
                fri_query_step0_p[i][j][k] = h[k].to_canonical_u64().to_string();
            }
        }
        for j in 0..conf.num_fri_query_step1_p {
            let h = pwpi.proof.opening_proof.query_round_proofs[i].steps[1]
                .merkle_proof
                .siblings[j]
                .to_vec();
            assert_eq!(h.len(), 4);
            for k in 0..4 {
                fri_query_step1_p[i][j][k] = h[k].to_canonical_u64().to_string();
            }
        }
    }

    proof_size += conf.num_fri_final_poly_ext_v * conf.ext_field_size;

    let mut fri_final_poly_ext_v = vec![vec!["0".to_string(); 2]; conf.num_fri_final_poly_ext_v];
    for i in 0..conf.num_fri_final_poly_ext_v {
        fri_final_poly_ext_v[i][0] = pwpi.proof.opening_proof.final_poly.coeffs[i]
            .to_basefield_array()[0]
            .to_canonical_u64()
            .to_string();
        fri_final_poly_ext_v[i][1] = pwpi.proof.opening_proof.final_poly.coeffs[i]
            .to_basefield_array()[1]
            .to_canonical_u64()
            .to_string();
    }

    proof_size += conf.field_size;

    proof_size += conf.num_public_inputs * conf.field_size;

    let mut public_inputs = vec!["0".to_string(); conf.num_public_inputs];
    for i in 0..conf.num_public_inputs {
        public_inputs[i] = pwpi.public_inputs[i].to_canonical_u64().to_string();
    }

    let circom_proof = ProofForCircom {
        wires_cap,
        plonk_zs_partial_products_cap,
        quotient_polys_cap,
        openings_constants,
        openings_plonk_sigmas,
        openings_wires,
        openings_plonk_zs,
        openings_plonk_zs_next,
        openings_partial_products,
        openings_quotient_polys,
        fri_commit_phase_merkle_caps,
        fri_query_init_constants_sigmas_v,
        fri_query_init_constants_sigmas_p,
        fri_query_init_wires_v,
        fri_query_init_wires_p,
        fri_query_init_zs_partial_v,
        fri_query_init_zs_partial_p,
        fri_query_init_quotient_v,
        fri_query_init_quotient_p,
        fri_query_step0_v,
        fri_query_step0_p,
        fri_query_step1_v,
        fri_query_step1_p,
        fri_final_poly_ext_v,
        fri_pow_witness: pwpi
            .proof
            .opening_proof
            .pow_witness
            .to_canonical_u64()
            .to_string(),
        public_inputs,
    };

    let proof_bytes = pwpi.to_bytes();
    assert_eq!(proof_bytes.len(), proof_size);
    println!("proof size: {}", proof_size);

    Ok(serde_json::to_string(&circom_proof).unwrap())
}

pub fn generate_circom_verifier<
    F: RichField + Extendable<D>,
    C: GenericConfig<D, F = F>,
    const D: usize,
>(
    conf: &VerifierConfig,
    common: &CommonCircuitData<F, D>,
    verifier_only: &VerifierOnlyCircuitData<C, D>,
) -> anyhow::Result<(String, String)> {
    assert_eq!(F::BITS, 64);
    assert_eq!(F::Extension::BITS, 128);
    println!("Generating Circom files ...");

    // Load template contract
    let mut constants = std::fs::read_to_string("./src/template_constants.circom")
        .expect("Something went wrong reading the file");

    let k_is = &common.k_is;
    let mut k_is_str = "".to_owned();
    for i in 0..k_is.len() {
        k_is_str += &*("  k_is[".to_owned()
            + &*i.to_string()
            + "] = "
            + &*k_is[i].to_canonical_u64().to_string()
            + ";\n");
    }
    constants = constants.replace("  $SET_K_IS;\n", &*k_is_str);

    let reduction_arity_bits = &common.fri_params.reduction_arity_bits;
    let mut reduction_arity_bits_str = "".to_owned();
    for i in 0..reduction_arity_bits.len() {
        reduction_arity_bits_str += &*("  bits[".to_owned()
            + &*i.to_string()
            + "] = "
            + &*reduction_arity_bits[i].to_string()
            + ";\n");
    }
    constants = constants.replace("  $SET_REDUCTION_ARITY_BITS;\n", &*reduction_arity_bits_str);
    constants = constants.replace(
        "$NUM_REDUCTION_ARITY_BITS",
        &*reduction_arity_bits.len().to_string(),
    );

    constants = constants.replace("$NUM_PUBLIC_INPUTS", &*conf.num_public_inputs.to_string());
    constants = constants.replace("$NUM_WIRES_CAP", &*conf.num_wires_cap.to_string());
    constants = constants.replace(
        "$NUM_PLONK_ZS_PARTIAL_PRODUCTS_CAP",
        &*conf.num_plonk_zs_partial_products_cap.to_string(),
    );
    constants = constants.replace(
        "$NUM_QUOTIENT_POLYS_CAP",
        &*conf.num_quotient_polys_cap.to_string(),
    );
    constants = constants.replace(
        "$NUM_OPENINGS_CONSTANTS",
        &*conf.num_openings_constants.to_string(),
    );
    constants = constants.replace(
        "$NUM_OPENINGS_PLONK_SIGMAS",
        &*conf.num_openings_plonk_sigmas.to_string(),
    );
    constants = constants.replace("$NUM_OPENINGS_WIRES", &*conf.num_openings_wires.to_string());
    constants = constants.replace(
        "$NUM_OPENINGS_PLONK_ZS0",
        &*conf.num_openings_plonk_zs.to_string(),
    );
    constants = constants.replace(
        "$NUM_OPENINGS_PLONK_ZS_NEXT",
        &*conf.num_openings_plonk_zs_next.to_string(),
    );
    constants = constants.replace(
        "$NUM_OPENINGS_PARTIAL_PRODUCTS",
        &*conf.num_openings_partial_products.to_string(),
    );
    constants = constants.replace(
        "$NUM_OPENINGS_QUOTIENT_POLYS",
        &*conf.num_openings_quotient_polys.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_COMMIT_ROUND",
        &*conf.num_fri_commit_round.to_string(),
    );
    constants = constants.replace(
        "$FRI_COMMIT_MERKLE_CAP_HEIGHT",
        &*conf.fri_commit_merkle_cap_height.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_ROUND",
        &*conf.num_fri_query_round.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_V",
        &*conf.num_fri_query_init_constants_sigmas_v.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_P",
        &*conf.num_fri_query_init_constants_sigmas_p.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_INIT_WIRES_V",
        &*conf.num_fri_query_init_wires_v.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_INIT_WIRES_P",
        &*conf.num_fri_query_init_wires_p.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_INIT_ZS_PARTIAL_V",
        &*conf.num_fri_query_init_zs_partial_v.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_INIT_ZS_PARTIAL_P",
        &*conf.num_fri_query_init_zs_partial_p.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_INIT_QUOTIENT_V",
        &*conf.num_fri_query_init_quotient_v.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_INIT_QUOTIENT_P",
        &*conf.num_fri_query_init_quotient_p.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_STEP0_V",
        &*conf.num_fri_query_step0_v.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_STEP0_P",
        &*conf.num_fri_query_step0_p.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_STEP1_V",
        &*conf.num_fri_query_step1_v.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_QUERY_STEP1_P",
        &*conf.num_fri_query_step1_p.to_string(),
    );
    constants = constants.replace(
        "$NUM_FRI_FINAL_POLY_EXT_V",
        &*conf.num_fri_final_poly_ext_v.to_string(),
    );
    constants = constants.replace(
        "$NUM_CHALLENGES",
        &*common.config.num_challenges.to_string(),
    );

    let circuit_digest = verifier_only.circuit_digest.to_vec();
    let mut circuit_digest_str = "".to_owned();
    for i in 0..circuit_digest.len() {
        circuit_digest_str += &*("  cd[".to_owned()
            + &*i.to_string()
            + "] = "
            + &*circuit_digest[i].to_canonical_u64().to_string()
            + ";\n");
    }
    constants = constants.replace("  $SET_CIRCUIT_DIGEST;\n", &*circuit_digest_str);

    constants = constants.replace(
        "$FRI_RATE_BITS",
        &*common.config.fri_config.rate_bits.to_string(),
    );
    constants = constants.replace("$DEGREE_BITS", &*common.degree_bits().to_string());
    constants = constants.replace(
        "$NUM_GATE_CONSTRAINTS",
        &*common.num_gate_constraints.to_string(),
    );
    constants = constants.replace(
        "$QUOTIENT_DEGREE_FACTOR",
        &*common.quotient_degree_factor.to_string(),
    );
    constants = constants.replace(
        "$MIN_FRI_POW_RESPONSE",
        &*(common.config.fri_config.proof_of_work_bits + (64 - F::order().bits()) as u32)
            .to_string(),
    );
    let g = F::Extension::primitive_root_of_unity(common.degree_bits());
    constants = constants.replace(
        "$G_FROM_DEGREE_BITS_0",
        &g.to_basefield_array()[0].to_string(),
    );
    constants = constants.replace(
        "$G_FROM_DEGREE_BITS_1",
        &g.to_basefield_array()[1].to_string(),
    );
    let log_n = log2_strict(common.fri_params.lde_size());
    constants = constants.replace("$LOG_SIZE_OF_LDE_DOMAIN", &*log_n.to_string());
    constants = constants.replace(
        "$MULTIPLICATIVE_GROUP_GENERATOR",
        &*F::MULTIPLICATIVE_GROUP_GENERATOR.to_string(),
    );
    constants = constants.replace(
        "$PRIMITIVE_ROOT_OF_UNITY_LDE",
        &*F::primitive_root_of_unity(log_n).to_string(),
    );
    // TODO: add test with config zero_knoledge = true
    constants = constants.replace(
        "$ZERO_KNOWLEDGE",
        &*common.config.zero_knowledge.to_string(),
    );
    let g = F::primitive_root_of_unity(1);
    constants = constants.replace("$G_ARITY_BITS_1", &g.to_string());
    let g = F::primitive_root_of_unity(2);
    constants = constants.replace("$G_ARITY_BITS_2", &g.to_string());
    let g = F::primitive_root_of_unity(3);
    constants = constants.replace("$G_ARITY_BITS_3", &g.to_string());
    let g = F::primitive_root_of_unity(4);
    constants = constants.replace("$G_ARITY_BITS_4", &g.to_string());

    // Load gate template
    let mut gates_lib = std::fs::read_to_string("./src/template_gates.circom")
        .expect("Something went wrong reading the file");

    let num_selectors = common.selectors_info.num_selectors();
    constants = constants.replace("$NUM_SELECTORS", &num_selectors.to_string());
    let mut evaluate_gate_constraints_str = "".to_owned();
    let mut last_component_name = "".to_owned();
    for (row, gate) in common.gates.iter().enumerate() {
        if gate.0.id().eq("NoopGate") {
            continue;
        }
        let selector_index = common.selectors_info.selector_indices[row];
        let group_range = common.selectors_info.groups[selector_index].clone();
        let mut c = 0;

        evaluate_gate_constraints_str = evaluate_gate_constraints_str + "\n";
        let mut filter_str = "filter <== ".to_owned();
        let filter_chain = group_range
            .filter(|&i| i != row)
            .chain((num_selectors > 1).then_some(u32::MAX as usize));
        for i in filter_chain {
            filter_str += &*("GlExtMul()(GlExtSub()(GlExt(".to_owned()
                + &i.to_string()
                + ", 0)(), "
                + "constants["
                + &*selector_index.to_string()
                + "]), ");
            c = c + 1;
        }
        filter_str += &*("GlExt(1, 0)()".to_owned());
        for _ in 0..c {
            filter_str = filter_str + ")";
        }
        filter_str = filter_str + ";";

        let mut eval_str = "  // ".to_owned() + &*gate.0.id() + "\n";
        let gate_name = gate.0.id();
        if gate_name.eq("PublicInputGate")
            || gate_name[0..11].eq("BaseSumGate")
            || gate_name[0..12].eq("ConstantGate")
            || gate_name[0..12].eq("PoseidonGate")
            || gate_name[0..12].eq("ReducingGate")
            || gate_name[0..14].eq("ArithmeticGate")
            || gate_name[0..15].eq("PoseidonMdsGate")
            || gate_name[0..16].eq("MulExtensionGate")
            || gate_name[0..16].eq("RandomAccessGate")
            || gate_name[0..18].eq("ExponentiationGate")
            || gate_name[0..21].eq("ReducingExtensionGate")
            || gate_name[0..23].eq("ArithmeticExtensionGate")
            || gate_name[0..26].eq("LowDegreeInterpolationGate")
        {
            //TODO: use num_coeff as a param (same TODO for other gates)
            let mut code_str = gate.0.export_circom_verification_code();
            code_str = code_str.replace("$SET_FILTER;", &*filter_str);
            let v: Vec<&str> = code_str.split(' ').collect();
            let template_name = &v[1][0..v[1].len() - 2];
            let component_name = "c_".to_owned() + template_name;
            eval_str +=
                &*("  component ".to_owned() + &*component_name + " = " + template_name + "();\n");
            eval_str += &*("  ".to_owned() + &*component_name + ".constants <== constants;\n");
            eval_str += &*("  ".to_owned() + &*component_name + ".wires <== wires;\n");
            eval_str += &*("  ".to_owned()
                + &*component_name
                + ".public_input_hash <== public_input_hash;\n");
            if last_component_name == "" {
                eval_str +=
                    &*("  ".to_owned() + &*component_name + ".constraints <== constraints;\n");
            } else {
                eval_str += &*("  ".to_owned()
                    + &*component_name
                    + ".constraints <== "
                    + &*last_component_name
                    + ".out;\n");
            }
            gates_lib += &*(code_str + "\n");
            last_component_name = component_name.clone();
        } else {
            todo!("{}", "gate not implemented: ".to_owned() + &gate_name)
        }
        evaluate_gate_constraints_str += &*eval_str;
    }

    evaluate_gate_constraints_str += &*("  out <== ".to_owned() + &*last_component_name + ".out;");
    gates_lib = gates_lib.replace(
        "  $EVALUATE_GATE_CONSTRAINTS;",
        &evaluate_gate_constraints_str,
    );

    gates_lib = gates_lib.replace(
        "$NUM_GATE_CONSTRAINTS",
        &*common.num_gate_constraints.to_string(),
    );
    gates_lib = gates_lib.replace("$NUM_SELECTORS", &num_selectors.to_string());
    gates_lib = gates_lib.replace(
        "$NUM_OPENINGS_CONSTANTS",
        &*conf.num_openings_constants.to_string(),
    );
    gates_lib = gates_lib.replace("$NUM_OPENINGS_WIRES", &*conf.num_openings_wires.to_string());
    gates_lib = gates_lib.replace("$F_EXT_W", &*F::W.to_basefield_array()[0].to_string());

    let sigma_cap_count = 1 << common.config.fri_config.cap_height;
    constants = constants.replace("$SIGMA_CAP_COUNT", &*sigma_cap_count.to_string());

    let mut sigma_cap_str = "".to_owned();
    for i in 0..sigma_cap_count {
        let cap = verifier_only.constants_sigmas_cap.0[i];
        let hash = cap.to_vec();
        assert_eq!(hash.len(), 4);
        sigma_cap_str += &*("  sc[".to_owned()
            + &*i.to_string()
            + "][0] = "
            + &*hash[0].to_canonical_u64().to_string()
            + ";\n");
        sigma_cap_str += &*("  sc[".to_owned()
            + &*i.to_string()
            + "][1] = "
            + &*hash[1].to_canonical_u64().to_string()
            + ";\n");
        sigma_cap_str += &*("  sc[".to_owned()
            + &*i.to_string()
            + "][2] = "
            + &*hash[2].to_canonical_u64().to_string()
            + ";\n");
        sigma_cap_str += &*("  sc[".to_owned()
            + &*i.to_string()
            + "][3] = "
            + &*hash[3].to_canonical_u64().to_string()
            + ";\n");
    }
    constants = constants.replace("  $SET_SIGMA_CAP;\n", &*sigma_cap_str);

    Ok((constants, gates_lib))
}

#[cfg(test)]
mod tests {
    use std::fs::File;
    use std::io::Write;
    use std::path::Path;

    use crate::config::PoseidonBN128GoldilocksConfig;
    use anyhow::Result;
    use plonky2::field::extension::Extendable;
    use plonky2::fri::reduction_strategies::FriReductionStrategy;
    use plonky2::fri::FriConfig;
    use plonky2::hash::hash_types::RichField;
    use plonky2::iop::witness::WitnessWrite;
    use plonky2::plonk::circuit_data::{CommonCircuitData, VerifierOnlyCircuitData};
    use plonky2::plonk::config::{Hasher, PoseidonGoldilocksConfig};
    use plonky2::plonk::proof::ProofWithPublicInputs;
    use plonky2::{
        gates::noop::NoopGate,
        iop::witness::PartialWitness,
        plonk::{
            circuit_builder::CircuitBuilder, circuit_data::CircuitConfig, config::GenericConfig,
        },
    };

    use crate::verifier::{
        generate_circom_verifier, generate_proof_base64, generate_verifier_config, recursive_proof,
    };

    /// Creates a dummy proof which should have roughly `num_dummy_gates` gates.
    fn dummy_proof<F: RichField + Extendable<D>, C: GenericConfig<D, F = F>, const D: usize>(
        config: &CircuitConfig,
        num_dummy_gates: u64,
        num_public_inputs: u64,
    ) -> Result<(
        ProofWithPublicInputs<F, C, D>,
        VerifierOnlyCircuitData<C, D>,
        CommonCircuitData<F, D>,
    )>
    where
        [(); C::Hasher::HASH_SIZE]:,
    {
        let mut builder = CircuitBuilder::<F, D>::new(config.clone());
        for _ in 0..num_dummy_gates {
            builder.add_gate(NoopGate, vec![]);
        }
        let mut pi = Vec::new();
        if num_public_inputs > 0 {
            pi = builder.add_virtual_targets(num_public_inputs as usize);
            builder.register_public_inputs(&pi);
        }

        let data = builder.build::<C>();
        let mut inputs = PartialWitness::new();
        if num_public_inputs > 0 {
            for i in 0..num_public_inputs {
                inputs.set_target(pi[i as usize], F::from_canonical_u64(i));
            }
        }
        let proof = data.prove(inputs)?;
        data.verify(proof.clone())?;

        Ok((proof, data.verifier_only, data.common))
    }

    #[test]
    fn test_verifier_without_public_inputs() -> Result<()> {
        const D: usize = 2;
        type C = PoseidonBN128GoldilocksConfig;
        type F = <C as GenericConfig<D>>::F;
        let standard_config = CircuitConfig::standard_recursion_config();
        // A high-rate recursive proof, designed to be verifiable with fewer routed wires.
        let high_rate_config = CircuitConfig {
            fri_config: FriConfig {
                rate_bits: 7,
                proof_of_work_bits: 16,
                num_query_rounds: 12,
                ..standard_config.fri_config.clone()
            },
            ..standard_config
        };
        // A final proof, optimized for size.
        let final_config = CircuitConfig {
            num_routed_wires: 37,
            fri_config: FriConfig {
                rate_bits: 8,
                cap_height: 0,
                proof_of_work_bits: 20,
                reduction_strategy: FriReductionStrategy::MinSize(None),
                num_query_rounds: 10,
            },
            ..high_rate_config
        };

        let (proof, vd, cd) = dummy_proof::<F, C, D>(&final_config, 4_000, 0)?;

        let conf = generate_verifier_config(&proof)?;
        let (circom_constants, circom_gates) = generate_circom_verifier(&conf, &cd, &vd)?;

        let mut circom_file = File::create("./circom/circuits/constants.circom")?;
        circom_file.write_all(circom_constants.as_bytes())?;
        circom_file = File::create("./circom/circuits/gates.circom")?;
        circom_file.write_all(circom_gates.as_bytes())?;

        let proof_json = generate_proof_base64(&proof, &conf)?;

        if !Path::new("./circom/test/data").is_dir() {
            std::fs::create_dir("./circom/test/data")?;
        }

        let mut proof_file = File::create("./circom/test/data/proof.json")?;
        proof_file.write_all(proof_json.as_bytes())?;

        let mut conf_file = File::create("./circom/test/data/conf.json")?;
        conf_file.write_all(serde_json::to_string(&conf)?.as_ref())?;

        Ok(())
    }

    #[test]
    fn test_verifier_with_public_inputs() -> Result<()> {
        const D: usize = 2;
        type C = PoseidonBN128GoldilocksConfig;
        type F = <C as GenericConfig<D>>::F;
        let standard_config = CircuitConfig::standard_recursion_config();
        let (proof, vd, cd) = dummy_proof::<F, C, D>(&standard_config, 4_000, 4)?;

        let conf = generate_verifier_config(&proof)?;
        let (circom_constants, circom_gates) = generate_circom_verifier(&conf, &cd, &vd)?;

        let mut circom_file = File::create("./circom/circuits/constants.circom")?;
        circom_file.write_all(circom_constants.as_bytes())?;
        circom_file = File::create("./circom/circuits/gates.circom")?;
        circom_file.write_all(circom_gates.as_bytes())?;

        let proof_json = generate_proof_base64(&proof, &conf)?;

        if !Path::new("./circom/test/data").is_dir() {
            std::fs::create_dir("./circom/test/data")?;
        }

        let mut proof_file = File::create("./circom/test/data/proof.json")?;
        proof_file.write_all(proof_json.as_bytes())?;

        let mut conf_file = File::create("./circom/test/data/conf.json")?;
        conf_file.write_all(serde_json::to_string(&conf)?.as_ref())?;

        Ok(())
    }

    #[test]
    fn test_recursive_verifier() -> Result<()> {
        const D: usize = 2;
        type C = PoseidonGoldilocksConfig;
        type F = <C as GenericConfig<D>>::F;
        let standard_config = CircuitConfig::standard_recursion_config();

        let (proof, vd, cd) = dummy_proof::<F, C, D>(&standard_config, 4_000, 4)?;
        let (proof, vd, cd) =
            recursive_proof::<F, C, C, D>(proof, vd, cd, &standard_config, None, true, true)?;

        type CBn128 = PoseidonBN128GoldilocksConfig;
        let (proof, vd, cd) =
            recursive_proof::<F, CBn128, C, D>(proof, vd, cd, &standard_config, None, true, true)?;

        let conf = generate_verifier_config(&proof)?;
        let (circom_constants, circom_gates) = generate_circom_verifier(&conf, &cd, &vd)?;

        let mut circom_file = File::create("./circom/circuits/constants.circom")?;
        circom_file.write_all(circom_constants.as_bytes())?;
        circom_file = File::create("./circom/circuits/gates.circom")?;
        circom_file.write_all(circom_gates.as_bytes())?;

        let proof_json = generate_proof_base64(&proof, &conf)?;

        if !Path::new("./circom/test/data").is_dir() {
            std::fs::create_dir("./circom/test/data")?;
        }

        let mut proof_file = File::create("./circom/test/data/proof.json")?;
        proof_file.write_all(proof_json.as_bytes())?;

        let mut conf_file = File::create("./circom/test/data/conf.json")?;
        conf_file.write_all(serde_json::to_string(&conf)?.as_ref())?;

        Ok(())
    }
}
