pragma circom 2.0.9;
include "./constants.circom";

template VerifyFriProof() {
  signal input openings_constants[NUM_OPENINGS_CONSTANTS()];
  signal input openings_plonk_sigmas[NUM_OPENINGS_PLONK_SIGMAS()];
  signal input openings_wires[NUM_OPENINGS_WIRES()];
  signal input openings_plonk_zs[NUM_OPENINGS_PLONK_ZS()];
  signal input openings_plonk_zs_next[NUM_OPENINGS_PLONK_ZS_NEXT()];
  signal input openings_partial_products[NUM_OPENINGS_PARTIAL_PRODUCTS()];
  signal input openings_quotient_polys[NUM_OPENINGS_QUOTIENT_POLYS()];

  signal input fri_commit_phase_merkle_caps[NUM_FRI_COMMIT_ROUND()][FRI_COMMIT_MERKLE_CAP_HEIGHT()][4];
  signal input fri_query_init_constants_sigmas_v[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_V()];
  signal input fri_query_init_constants_sigmas_p[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_P()][4];
  signal input fri_query_init_wires_v[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_INIT_WIRES_V()];
  signal input fri_query_init_wires_p[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_INIT_WIRES_P()][4];
  signal input fri_query_init_zs_partial_v[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_INIT_ZS_PARTIAL_V()];
  signal input fri_query_init_zs_partial_p[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_INIT_ZS_PARTIAL_P()][4];
  signal input fri_query_init_quotient_v[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_INIT_QUOTIENT_V()];
  signal input fri_query_init_quotient_p[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_INIT_QUOTIENT_P()][4];
  signal input fri_query_step0_v[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_STEP0_V()][2];
  signal input fri_query_step0_p[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_STEP0_P()][4];
  signal input fri_query_step1_v[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_STEP1_V()][2];
  signal input fri_query_step1_p[NUM_FRI_QUERY_ROUND()][NUM_FRI_QUERY_STEP1_P()][4];
  signal input fri_final_poly_ext_v[NUM_FRI_FINAL_POLY_EXT_V()][2];
  signal input fri_pow_witness;

  signal input fri_alpha[2];
  signal input fri_betas[NUM_FRI_COMMIT_ROUND()][2];
  signal input fri_pow_response;
  signal input fri_query_indices[NUM_FRI_QUERY_ROUND()];

  signal output res;

  res <== 1;
}
