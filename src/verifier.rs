use std::fmt::Write;

use anyhow::Result;
use log::Level;
use plonky2::field::extension::{Extendable, FieldExtension};
use plonky2::field::types::Field;
use plonky2::gates::noop::NoopGate;
use plonky2::hash::hash_types::RichField;
use plonky2::iop::witness::{PartialWitness, Witness};
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
    inner_cd: CommonCircuitData<F, InnerC, D>,
    config: &CircuitConfig,
    min_degree_bits: Option<usize>,
    print_gate_counts: bool,
    print_timing: bool,
) -> Result<(
    ProofWithPublicInputs<F, C, D>,
    VerifierOnlyCircuitData<C, D>,
    CommonCircuitData<F, C, D>,
)>
where
    InnerC::Hasher: AlgebraicHasher<F>,
    [(); C::Hasher::HASH_SIZE]:,
{
    let mut builder = CircuitBuilder::<F, D>::new(config.clone());
    let mut pw = PartialWitness::new();
    let pt = builder.add_virtual_proof_with_pis(&inner_cd);
    pw.set_proof_with_pis_target(&pt, &inner_proof);

    let inner_data = VerifierCircuitTarget {
        constants_sigmas_cap: builder.add_virtual_cap(inner_cd.config.fri_config.cap_height),
    };
    pw.set_cap_target(
        &inner_data.constants_sigmas_cap,
        &inner_vd.constants_sigmas_cap,
    );

    builder.verify_proof(pt, &inner_data, &inner_cd);

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

    const HASH_SIZE: usize = 25;
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
    // total size: 75
    let mut proof_size: usize =
        (conf.num_wires_cap + conf.num_plonk_zs_partial_products_cap + conf.num_quotient_polys_cap)
            * conf.hash_size;

    // total size: 3355
    proof_size += (conf.num_openings_constants
        + conf.num_openings_plonk_sigmas
        + conf.num_openings_wires
        + conf.num_openings_plonk_zs
        + conf.num_openings_plonk_zs_next
        + conf.num_openings_partial_products
        + conf.num_openings_quotient_polys)
        * conf.ext_field_size;

    // 3405
    proof_size += (conf.num_fri_commit_round * conf.fri_commit_merkle_cap_height) * conf.hash_size;
    // 39685
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
    // 50015
    proof_size += conf.num_fri_query_round
        * (conf.num_fri_query_step0_v * conf.ext_field_size
            + conf.num_fri_query_step0_p * conf.hash_size
            + conf.merkle_height_size
            + conf.num_fri_query_step1_v * conf.ext_field_size
            + conf.num_fri_query_step1_p * conf.hash_size
            + conf.merkle_height_size);

    // 51039
    proof_size += conf.num_fri_final_poly_ext_v * conf.ext_field_size;

    // 51047
    proof_size += conf.field_size;

    proof_size += conf.num_public_inputs * conf.field_size;

    let proof_bytes = pwpi.to_bytes()?;
    assert_eq!(proof_bytes.len(), proof_size);

    Ok(base64::encode(proof_bytes))
}

pub fn generate_solidity_verifier<
    F: RichField + Extendable<D>,
    C: GenericConfig<D, F = F>,
    const D: usize,
>(
    conf: &VerifierConfig,
    common: &CommonCircuitData<F, C, D>,
    verifier_only: &VerifierOnlyCircuitData<C, D>,
) -> anyhow::Result<(String, String, String)> {
    assert_eq!(
        25,
        C::Hasher::HASH_SIZE,
        "Only support KeccakHash<25> right now"
    );
    assert_eq!(F::BITS, 64);
    assert_eq!(F::Extension::BITS, 128);
    println!("Generating solidity verifier files ...");

    // Load template contract
    let mut contract = std::fs::read_to_string("./src/template_main.sol")
        .expect("Something went wrong reading the file");

    let k_is = &common.k_is;
    let mut k_is_str = "".to_owned();
    for i in 0..k_is.len() {
        k_is_str += &*("        k_is[".to_owned()
            + &*i.to_string()
            + "] = "
            + &*k_is[i].to_canonical_u64().to_string()
            + ";\n");
    }
    contract = contract.replace("        $SET_K_IS;\n", &*k_is_str);

    let reduction_arity_bits = &common.fri_params.reduction_arity_bits;
    let mut reduction_arity_bits_str = "".to_owned();
    for i in 0..reduction_arity_bits.len() {
        reduction_arity_bits_str += &*("        bits[".to_owned()
            + &*i.to_string()
            + "] = "
            + &*reduction_arity_bits[i].to_string()
            + ";\n");
    }
    contract = contract.replace(
        "        $SET_REDUCTION_ARITY_BITS;\n",
        &*reduction_arity_bits_str,
    );
    contract = contract.replace(
        "$NUM_REDUCTION_ARITY_BITS",
        &*reduction_arity_bits.len().to_string(),
    );

    contract = contract.replace("$NUM_WIRES_CAP", &*conf.num_wires_cap.to_string());
    contract = contract.replace(
        "$NUM_PLONK_ZS_PARTIAL_PRODUCTS_CAP",
        &*conf.num_plonk_zs_partial_products_cap.to_string(),
    );
    contract = contract.replace(
        "$NUM_QUOTIENT_POLYS_CAP",
        &*conf.num_quotient_polys_cap.to_string(),
    );
    contract = contract.replace(
        "$NUM_OPENINGS_CONSTANTS",
        &*conf.num_openings_constants.to_string(),
    );
    contract = contract.replace(
        "$NUM_OPENINGS_PLONK_SIGMAS",
        &*conf.num_openings_plonk_sigmas.to_string(),
    );
    contract = contract.replace("$NUM_OPENINGS_WIRES", &*conf.num_openings_wires.to_string());
    contract = contract.replace(
        "$NUM_OPENINGS_PLONK_ZS0",
        &*conf.num_openings_plonk_zs.to_string(),
    );
    contract = contract.replace(
        "$NUM_OPENINGS_PLONK_ZS_NEXT",
        &*conf.num_openings_plonk_zs_next.to_string(),
    );
    contract = contract.replace(
        "$NUM_OPENINGS_PARTIAL_PRODUCTS",
        &*conf.num_openings_partial_products.to_string(),
    );
    contract = contract.replace(
        "$NUM_OPENINGS_QUOTIENT_POLYS",
        &*conf.num_openings_quotient_polys.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_COMMIT_ROUND",
        &*conf.num_fri_commit_round.to_string(),
    );
    contract = contract.replace(
        "$FRI_COMMIT_MERKLE_CAP_HEIGHT",
        &*conf.fri_commit_merkle_cap_height.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_ROUND",
        &*conf.num_fri_query_round.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_V",
        &*conf.num_fri_query_init_constants_sigmas_v.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_P",
        &*conf.num_fri_query_init_constants_sigmas_p.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_INIT_WIRES_V",
        &*conf.num_fri_query_init_wires_v.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_INIT_WIRES_P",
        &*conf.num_fri_query_init_wires_p.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_INIT_ZS_PARTIAL_V",
        &*conf.num_fri_query_init_zs_partial_v.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_INIT_ZS_PARTIAL_P",
        &*conf.num_fri_query_init_zs_partial_p.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_INIT_QUOTIENT_V",
        &*conf.num_fri_query_init_quotient_v.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_INIT_QUOTIENT_P",
        &*conf.num_fri_query_init_quotient_p.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_STEP0_V",
        &*conf.num_fri_query_step0_v.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_STEP0_P",
        &*conf.num_fri_query_step0_p.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_STEP1_V",
        &*conf.num_fri_query_step1_v.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_QUERY_STEP1_P",
        &*conf.num_fri_query_step1_p.to_string(),
    );
    contract = contract.replace(
        "$NUM_FRI_FINAL_POLY_EXT_V",
        &*conf.num_fri_final_poly_ext_v.to_string(),
    );
    contract = contract.replace(
        "$NUM_CHALLENGES",
        &*common.config.num_challenges.to_string(),
    );

    let circuit_digest = common.circuit_digest;
    contract = contract.replace(
        "$CIRCUIT_DIGEST",
        &*("0x".to_owned() + &encode_hex(&circuit_digest.to_bytes())),
    );

    contract = contract.replace(
        "$FRI_RATE_BITS",
        &*common.config.fri_config.rate_bits.to_string(),
    );
    contract = contract.replace("$DEGREE_BITS", &*common.degree_bits.to_string());
    contract = contract.replace(
        "$NUM_GATE_CONSTRAINTS",
        &*common.num_gate_constraints.to_string(),
    );
    contract = contract.replace(
        "$QUOTIENT_DEGREE_FACTOR",
        &*common.quotient_degree_factor.to_string(),
    );
    contract = contract.replace(
        "$MIN_FRI_POW_RESPONSE",
        &*(common.config.fri_config.proof_of_work_bits + (64 - F::order().bits()) as u32)
            .to_string(),
    );
    let g = F::Extension::primitive_root_of_unity(common.degree_bits);
    contract = contract.replace(
        "$G_FROM_DEGREE_BITS_0",
        &g.to_basefield_array()[0].to_string(),
    );
    contract = contract.replace(
        "$G_FROM_DEGREE_BITS_1",
        &g.to_basefield_array()[1].to_string(),
    );
    let log_n = log2_strict(common.fri_params.lde_size());
    contract = contract.replace("$LOG_SIZE_OF_LDE_DOMAIN", &*log_n.to_string());
    contract = contract.replace(
        "$MULTIPLICATIVE_GROUP_GENERATOR",
        &*F::MULTIPLICATIVE_GROUP_GENERATOR.to_string(),
    );
    contract = contract.replace(
        "$PRIMITIVE_ROOT_OF_UNITY_LDE",
        &*F::primitive_root_of_unity(log_n).to_string(),
    );
    // TODO: add test with config zero_knoledge = true
    contract = contract.replace(
        "$ZERO_KNOWLEDGE",
        &*common.config.zero_knowledge.to_string(),
    );
    let g = F::primitive_root_of_unity(1);
    contract = contract.replace("$G_ARITY_BITS_1", &g.to_string());
    let g = F::primitive_root_of_unity(2);
    contract = contract.replace("$G_ARITY_BITS_2", &g.to_string());
    let g = F::primitive_root_of_unity(3);
    contract = contract.replace("$G_ARITY_BITS_3", &g.to_string());
    let g = F::primitive_root_of_unity(4);
    contract = contract.replace("$G_ARITY_BITS_4", &g.to_string());

    // Load gate template
    let mut gates_lib = std::fs::read_to_string("./src/template_gates.sol")
        .expect("Something went wrong reading the file");

    let num_selectors = common.selectors_info.num_selectors();
    contract = contract.replace("$NUM_SELECTORS", &num_selectors.to_string());
    let mut evaluate_gate_constraints_str = "".to_owned();
    for (row, gate) in common.gates.iter().enumerate() {
        if gate.0.id().eq("NoopGate") {
            continue;
        }
        let selector_index = common.selectors_info.selector_indices[row];
        let group_range = common.selectors_info.groups[selector_index].clone();
        let mut c = 0;

        evaluate_gate_constraints_str = evaluate_gate_constraints_str + "        {\n";
        let mut filter_str = "ev.filter = ".to_owned();
        let filter_chain = group_range
            .filter(|&i| i != row)
            .chain((num_selectors > 1).then_some(u32::MAX as usize));
        for i in filter_chain {
            filter_str += &*("GatesUtilsLib.field_ext_from(".to_owned()
                + &i.to_string()
                + ", 0).sub("
                + "ev.constants["
                + &*selector_index.to_string()
                + "]).mul(");
            c = c + 1;
        }
        filter_str = filter_str[0..filter_str.len() - 5].parse()?;
        for _ in 0..c - 1 {
            filter_str = filter_str + ")";
        }
        filter_str = filter_str + ";";

        // vars:
        //   proof.openings_constants
        //   proof.openings_wires
        //   challenges.public_input_hash
        // local_constants = local_constants[num_selectors..];
        let mut eval_str = "            // ".to_owned() + &*gate.0.id() + "\n";
        let gate_name = gate.0.id();
        if gate_name.eq("PublicInputGate")
            || gate_name[0..11].eq("BaseSumGate")
            || gate_name[0..12].eq("ConstantGate")
            || gate_name[0..12].eq("ReducingGate")
            || gate_name[0..14].eq("ArithmeticGate")
            || gate_name[0..16].eq("MulExtensionGate")
            || gate_name[0..16].eq("RandomAccessGate")
            || gate_name[0..17].eq("U32ArithmeticGate")
            || gate_name[0..18].eq("ExponentiationGate")
            || gate_name[0..21].eq("ReducingExtensionGate")
            || gate_name[0..23].eq("ArithmeticExtensionGate")
            || gate_name[0..26].eq("LowDegreeInterpolationGate")
        {
            //TODO: use num_coeff as a param (same TODO for other gates)
            let mut code_str = gate.0.export_solidity_verification_code();
            code_str = code_str.replace("$SET_FILTER;", &*filter_str);
            let v: Vec<&str> = code_str.split(' ').collect();
            let lib_name = v[1];
            eval_str += &*("            ".to_owned() + lib_name + ".set_filter(ev); \n");
            eval_str +=
                &*("            ".to_owned() + lib_name + ".eval(ev, vm.constraint_terms); \n");
            gates_lib += &*(code_str + "\n");
            // eval_str += &*format!("            console.log(\"{}\");", gate_name);
            // eval_str += &*format!(
            //     "
            // for (uint32 i = 0; i < {}; i++) {{
            //     console.log(i);
            //     console.log(vm.constraint_terms[i][0]);
            //     console.log(vm.constraint_terms[i][1]);
            // }}
            // console.log(\"\");\n",
            //     &*common.num_gate_constraints.to_string(),
            // );
        } else if gate_name[0..12].eq("PoseidonGate") {
            todo!("{}", "gate not implemented: ".to_owned() + &gate_name)
        } else {
            todo!("{}", "gate not implemented: ".to_owned() + &gate_name)
        }
        evaluate_gate_constraints_str += &*eval_str;
        evaluate_gate_constraints_str += "        }\n";
    }
    contract = contract.replace(
        "        $EVALUATE_GATE_CONSTRAINTS;",
        &evaluate_gate_constraints_str[0..evaluate_gate_constraints_str.len() - 1],
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
    gates_lib = gates_lib.replace("$D", &*D.to_string());
    gates_lib = gates_lib.replace("$F_EXT_W", &*F::W.to_basefield_array()[0].to_string());

    // Load proof template
    let mut proof_lib = std::fs::read_to_string("./src/template_proof.sol")
        .expect("Something went wrong reading the file");

    let sigma_cap_count = 1 << common.config.fri_config.cap_height;
    proof_lib = proof_lib.replace("$SIGMA_CAP_COUNT", &*sigma_cap_count.to_string());

    let mut sigma_cap_str = "".to_owned();
    for i in 0..sigma_cap_count {
        let cap = verifier_only.constants_sigmas_cap.0[i];
        let hash = encode_hex(&cap.to_bytes());
        sigma_cap_str += &*("        sc[".to_owned() + &*i.to_string() + "] = 0x" + &*hash + ";\n");
    }
    proof_lib = proof_lib.replace("        $SET_SIGMA_CAP;\n", &*sigma_cap_str);

    proof_lib = proof_lib.replace(
        "$PLONK_ZS_PARTIAL_PRODUCTS_CAP_PTR",
        &*(conf.num_wires_cap * conf.hash_size).to_string(),
    );
    proof_lib = proof_lib.replace(
        "$QUOTIENT_POLYS_CAP_PTR",
        &*((conf.num_wires_cap + conf.num_plonk_zs_partial_products_cap) * conf.hash_size)
            .to_string(),
    );

    let mut proof_size: usize =
        (conf.num_wires_cap + conf.num_plonk_zs_partial_products_cap + conf.num_quotient_polys_cap)
            * conf.hash_size;
    proof_lib = proof_lib.replace("$OPENINGS_CONSTANTS_PTR", &*proof_size.to_string());

    proof_size += conf.num_openings_constants * conf.ext_field_size;
    proof_lib = proof_lib.replace("$OPENINGS_PLONK_SIGMAS_PTR", &*proof_size.to_string());

    proof_size += conf.num_openings_plonk_sigmas * conf.ext_field_size;
    proof_lib = proof_lib.replace("$OPENINGS_WIRES_PTR", &*proof_size.to_string());

    proof_size += conf.num_openings_wires * conf.ext_field_size;
    proof_lib = proof_lib.replace("$OPENINGS_PLONK_ZS_PTR", &*proof_size.to_string());

    proof_size += conf.num_openings_plonk_zs * conf.ext_field_size;
    proof_lib = proof_lib.replace("$OPENINGS_PLONK_ZS_NEXT_PTR", &*proof_size.to_string());

    proof_size += conf.num_openings_plonk_zs_next * conf.ext_field_size;
    proof_lib = proof_lib.replace("$OPENINGS_PARTIAL_PRODUCTS_PTR", &*proof_size.to_string());

    proof_size += conf.num_openings_partial_products * conf.ext_field_size;
    proof_lib = proof_lib.replace("$OPENINGS_QUOTIENT_POLYS_PTR", &*proof_size.to_string());

    proof_size += conf.num_openings_quotient_polys * conf.ext_field_size;

    proof_lib = proof_lib.replace(
        "$FRI_COMMIT_PHASE_MERKLE_CAPS_PTR",
        &*proof_size.to_string(),
    );
    proof_lib = proof_lib.replace(
        "$FRI_COMMIT_ROUND_SIZE",
        &*(conf.fri_commit_merkle_cap_height * conf.hash_size).to_string(),
    );
    proof_size += (conf.num_fri_commit_round * conf.fri_commit_merkle_cap_height) * conf.hash_size;

    let fri_query_round_ptr = proof_size;
    proof_lib = proof_lib.replace("$FRI_QUERY_ROUND_PTR", &*fri_query_round_ptr.to_string());

    let fri_query_round_size = (conf.num_fri_query_init_constants_sigmas_v
        + conf.num_fri_query_init_wires_v
        + conf.num_fri_query_init_zs_partial_v
        + conf.num_fri_query_init_quotient_v)
        * conf.field_size
        + (conf.num_fri_query_init_constants_sigmas_p
            + conf.num_fri_query_init_wires_p
            + conf.num_fri_query_init_zs_partial_p
            + conf.num_fri_query_init_quotient_p)
            * conf.hash_size
        + conf.merkle_height_size * 4
        + conf.num_fri_query_step0_v * conf.ext_field_size
        + conf.num_fri_query_step0_p * conf.hash_size
        + conf.merkle_height_size
        + conf.num_fri_query_step1_v * conf.ext_field_size
        + conf.num_fri_query_step1_p * conf.hash_size
        + conf.merkle_height_size;
    proof_lib = proof_lib.replace("$FRI_QUERY_ROUND_SIZE", &*fri_query_round_size.to_string());

    let mut round_ptr = conf.num_fri_query_init_constants_sigmas_v * conf.field_size + 1;
    proof_lib = proof_lib.replace("$INIT_CONSTANTS_SIGMAS_P_PTR", &*round_ptr.to_string());
    round_ptr += conf.num_fri_query_init_constants_sigmas_p * conf.hash_size;
    proof_lib = proof_lib.replace("$INIT_WIRES_V_PTR", &*round_ptr.to_string());

    round_ptr += conf.num_fri_query_init_wires_v * conf.field_size + 1;
    proof_lib = proof_lib.replace("$INIT_WIRES_P_PTR", &*round_ptr.to_string());
    round_ptr += conf.num_fri_query_init_wires_p * conf.hash_size;
    proof_lib = proof_lib.replace("$INIT_ZS_PARTIAL_V_PTR", &*round_ptr.to_string());

    round_ptr += conf.num_fri_query_init_zs_partial_v * conf.field_size + 1;
    proof_lib = proof_lib.replace("$INIT_ZS_PARTIAL_P_PTR", &*round_ptr.to_string());
    round_ptr += conf.num_fri_query_init_zs_partial_p * conf.hash_size;
    proof_lib = proof_lib.replace("$INIT_QUOTIENT_V_PTR", &*round_ptr.to_string());

    round_ptr += conf.num_fri_query_init_quotient_v * conf.field_size + 1;
    proof_lib = proof_lib.replace("$INIT_QUOTIENT_P_PTR", &*round_ptr.to_string());
    round_ptr += conf.num_fri_query_init_quotient_p * conf.hash_size;
    proof_lib = proof_lib.replace("$STEP0_V_PTR", &*round_ptr.to_string());

    round_ptr += conf.num_fri_query_step0_v * conf.ext_field_size + 1;
    proof_lib = proof_lib.replace("$STEP0_P_PTR", &*round_ptr.to_string());
    round_ptr += conf.num_fri_query_step0_p * conf.hash_size;
    proof_lib = proof_lib.replace("$STEP1_V_PTR", &*round_ptr.to_string());

    round_ptr += conf.num_fri_query_step1_v * conf.ext_field_size + 1;
    proof_lib = proof_lib.replace("$STEP1_P_PTR", &*round_ptr.to_string());
    round_ptr += conf.num_fri_query_step1_p * conf.hash_size;
    assert_eq!(round_ptr, fri_query_round_size);

    proof_size += fri_query_round_size * conf.num_fri_query_round;
    proof_lib = proof_lib.replace("$FRI_FINAL_POLY_EXT_V_PTR", &*proof_size.to_string());

    proof_size += conf.ext_field_size * conf.num_fri_final_poly_ext_v;
    proof_lib = proof_lib.replace("$FRI_POW_WITNESS_PTR", &*proof_size.to_string());

    proof_size += conf.field_size;
    proof_lib = proof_lib.replace("$PUBLIC_INPUTS_PTR", &*proof_size.to_string());

    proof_lib = proof_lib.replace(
        "$NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_P",
        &*conf.num_fri_query_init_constants_sigmas_p.to_string(),
    );
    proof_lib = proof_lib.replace(
        "$NUM_FRI_QUERY_INIT_WIRES_P",
        &*conf.num_fri_query_init_wires_p.to_string(),
    );
    proof_lib = proof_lib.replace(
        "$NUM_FRI_QUERY_INIT_ZS_PARTIAL_P",
        &*conf.num_fri_query_init_zs_partial_p.to_string(),
    );
    proof_lib = proof_lib.replace(
        "$NUM_FRI_QUERY_INIT_QUOTIENT_P",
        &*conf.num_fri_query_init_quotient_p.to_string(),
    );
    proof_lib = proof_lib.replace(
        "$NUM_FRI_QUERY_STEP0_P",
        &*conf.num_fri_query_step0_p.to_string(),
    );
    proof_lib = proof_lib.replace(
        "$NUM_FRI_QUERY_STEP1_P",
        &*conf.num_fri_query_step1_p.to_string(),
    );
    proof_lib = proof_lib.replace("$NUM_PUBLIC_INPUTS", &*conf.num_public_inputs.to_string());

    Ok((contract, gates_lib, proof_lib))
}

#[cfg(test)]
mod tests {
    use std::fs::File;
    use std::io::Write;
    use std::path::Path;

    use anyhow::Result;
    use plonky2::field::extension::Extendable;
    use plonky2::fri::reduction_strategies::FriReductionStrategy;
    use plonky2::fri::FriConfig;
    use plonky2::hash::hash_types::RichField;
    use plonky2::iop::witness::Witness;
    use plonky2::plonk::circuit_data::{CommonCircuitData, VerifierOnlyCircuitData};
    use plonky2::plonk::config::Hasher;
    use plonky2::plonk::proof::ProofWithPublicInputs;
    use plonky2::{
        gates::noop::NoopGate,
        iop::witness::PartialWitness,
        plonk::{
            circuit_builder::CircuitBuilder,
            circuit_data::CircuitConfig,
            config::{GenericConfig, PoseidonGoldilocksConfig},
        },
    };

    use crate::config::KeccakGoldilocksConfig2;
    use crate::verifier::{
        generate_proof_base64, generate_solidity_verifier, generate_verifier_config,
        recursive_proof,
    };

    /// Creates a dummy proof which should have roughly `num_dummy_gates` gates.
    fn dummy_proof<F: RichField + Extendable<D>, C: GenericConfig<D, F = F>, const D: usize>(
        config: &CircuitConfig,
        num_dummy_gates: u64,
        num_public_inputs: u64,
    ) -> Result<(
        ProofWithPublicInputs<F, C, D>,
        VerifierOnlyCircuitData<C, D>,
        CommonCircuitData<F, C, D>,
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
        type C = PoseidonGoldilocksConfig;
        type F = <KC2 as GenericConfig<D>>::F;
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

        let (proof, vd, cd) = dummy_proof::<F, KC2, D>(&final_config, 4_000, 0)?;

        let conf = generate_verifier_config(&proof)?;
        let (contract, gates_lib, proof_lib) = generate_solidity_verifier(&conf, &cd, &vd)?;

        let mut sol_file = File::create("./contract/contracts/Verifier.sol")?;
        sol_file.write_all(contract.as_bytes())?;
        sol_file = File::create("./contract/contracts/GatesLib.sol")?;
        sol_file.write_all(gates_lib.as_bytes())?;
        sol_file = File::create("./contract/contracts/ProofLib.sol")?;
        sol_file.write_all(proof_lib.as_bytes())?;

        let proof_base64 = generate_proof_base64(&proof, &conf)?;
        let proof_json = "[ \"".to_owned() + &proof_base64 + &"\" ]";

        if !Path::new("./contract/test/data").is_dir() {
            std::fs::create_dir("./contract/test/data")?;
        }

        let mut proof_file = File::create("./contract/test/data/proof.json")?;
        proof_file.write_all(proof_json.as_bytes())?;

        let mut conf_file = File::create("./contract/test/data/conf.json")?;
        conf_file.write_all(serde_json::to_string(&conf)?.as_ref())?;

        Ok(())
    }

    #[test]
    fn test_verifier_with_public_inputs() -> Result<()> {
        const D: usize = 2;
        type C = PoseidonGoldilocksConfig;
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
            num_routed_wires: 65,
            fri_config: FriConfig {
                rate_bits: 8,
                cap_height: 0,
                proof_of_work_bits: 20,
                reduction_strategy: FriReductionStrategy::MinSize(None),
                num_query_rounds: 10,
            },
            ..high_rate_config
        };

        let (proof, vd, cd) = dummy_proof::<F, KC2, D>(&final_config, 4_000, 4)?;

        let conf = generate_verifier_config(&proof)?;
        let (contract, gates_lib, proof_lib) = generate_solidity_verifier(&conf, &cd, &vd)?;

        let mut sol_file = File::create("./contract/contracts/Verifier.sol")?;
        sol_file.write_all(contract.as_bytes())?;
        sol_file = File::create("./contract/contracts/GatesLib.sol")?;
        sol_file.write_all(gates_lib.as_bytes())?;
        sol_file = File::create("./contract/contracts/ProofLib.sol")?;
        sol_file.write_all(proof_lib.as_bytes())?;

        let proof_base64 = generate_proof_base64(&proof, &conf)?;
        let proof_json = "[ \"".to_owned() + &proof_base64 + &"\" ]";

        if !Path::new("./contract/test/data").is_dir() {
            std::fs::create_dir("./contract/test/data")?;
        }

        let mut proof_file = File::create("./contract/test/data/proof.json")?;
        proof_file.write_all(proof_json.as_bytes())?;

        let mut conf_file = File::create("./contract/test/data/conf.json")?;
        conf_file.write_all(serde_json::to_string(&conf)?.as_ref())?;

        Ok(())
    }

    #[test]
    fn test_recursive_verifier_without_public_inputs() -> Result<()> {
        const D: usize = 2;
        type C = PoseidonGoldilocksConfig;
        type F = <C as GenericConfig<D>>::F;
        type KC2 = KeccakGoldilocksConfig2;
        let standard_config = CircuitConfig::standard_recursion_config();

        let (proof, vd, cd) = dummy_proof::<F, C, D>(&standard_config, 4_000, 0)?;

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

        let (proof, vd, cd) =
            recursive_proof::<F, C, C, D>(proof, vd, cd, &high_rate_config, None, true, true)?;

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
        let (proof, vd, cd) =
            recursive_proof::<F, KC2, C, D>(proof, vd, cd, &final_config, None, true, true)?;

        let conf = generate_verifier_config(&proof)?;
        let (contract, gates_lib, proof_lib) = generate_solidity_verifier(&conf, &cd, &vd)?;

        let mut sol_file = File::create("./contract/contracts/Verifier.sol")?;
        sol_file.write_all(contract.as_bytes())?;
        sol_file = File::create("./contract/contracts/GatesLib.sol")?;
        sol_file.write_all(gates_lib.as_bytes())?;
        sol_file = File::create("./contract/contracts/ProofLib.sol")?;
        sol_file.write_all(proof_lib.as_bytes())?;

        let proof_base64 = generate_proof_base64(&proof, &conf)?;
        let proof_json = "[ \"".to_owned() + &proof_base64 + &"\" ]";

        if !Path::new("./contract/test/data").is_dir() {
            std::fs::create_dir("./contract/test/data")?;
        }

        let mut proof_file = File::create("./contract/test/data/proof.json")?;
        proof_file.write_all(proof_json.as_bytes())?;

        let mut conf_file = File::create("./contract/test/data/conf.json")?;
        conf_file.write_all(serde_json::to_string(&conf)?.as_ref())?;

        Ok(())
    }
}
