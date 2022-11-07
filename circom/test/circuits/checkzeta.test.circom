// TODO: check all inputs are 64 bits

pragma circom 2.1.0;
include "../../circuits/challenges.circom";
include "../../circuits/plonk.circom";

template VerifyCheckZeta() {
  signal input wires_cap[NUM_WIRES_CAP()][4];
  signal input plonk_zs_partial_products_cap[NUM_PLONK_ZS_PARTIAL_PRODUCTS_CAP()][4];
  signal input quotient_polys_cap[NUM_QUOTIENT_POLYS_CAP()][4];

  signal input openings_constants[NUM_OPENINGS_CONSTANTS()][2];
  signal input openings_plonk_sigmas[NUM_OPENINGS_PLONK_SIGMAS()][2];
  signal input openings_wires[NUM_OPENINGS_WIRES()][2];
  signal input openings_plonk_zs[NUM_OPENINGS_PLONK_ZS()][2];
  signal input openings_plonk_zs_next[NUM_OPENINGS_PLONK_ZS_NEXT()][2];
  signal input openings_partial_products[NUM_OPENINGS_PARTIAL_PRODUCTS()][2];
  signal input openings_quotient_polys[NUM_OPENINGS_QUOTIENT_POLYS()][2];

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

  component get_challenges = GetChallenges();

  get_challenges.wires_cap <== wires_cap;
  get_challenges.plonk_zs_partial_products_cap <== plonk_zs_partial_products_cap;
  get_challenges.quotient_polys_cap <== quotient_polys_cap;

  get_challenges.openings_constants <== openings_constants;
  get_challenges.openings_plonk_sigmas <== openings_plonk_sigmas;
  get_challenges.openings_wires <== openings_wires;
  get_challenges.openings_plonk_zs <== openings_plonk_zs;
  get_challenges.openings_plonk_zs_next <== openings_plonk_zs_next;
  get_challenges.openings_partial_products <== openings_partial_products;
  get_challenges.openings_quotient_polys <== openings_quotient_polys;

  get_challenges.fri_commit_phase_merkle_caps <== fri_commit_phase_merkle_caps;
  get_challenges.fri_final_poly_ext_v <== fri_final_poly_ext_v;
  get_challenges.fri_pow_witness <== fri_pow_witness;

  component eval_vanishing_poly = EvalVanishingPoly();

  eval_vanishing_poly.plonk_betas <== get_challenges.plonk_betas;
  eval_vanishing_poly.plonk_zeta <== get_challenges.plonk_zeta;
  eval_vanishing_poly.plonk_gammas <== get_challenges.plonk_gammas;
  eval_vanishing_poly.openings_wires <== openings_wires;
  eval_vanishing_poly.openings_plonk_zs <== openings_plonk_zs;
  eval_vanishing_poly.openings_plonk_sigmas <== openings_plonk_sigmas;
  eval_vanishing_poly.openings_plonk_zs_next <== openings_plonk_zs_next;
  eval_vanishing_poly.openings_partial_products <== openings_partial_products;

  component check_zeta = CheckZeta();

  check_zeta.openings_quotient_polys <== openings_quotient_polys;
  check_zeta.plonk_alphas <== get_challenges.plonk_alphas;
  check_zeta.plonk_zeta <== get_challenges.plonk_zeta;
  check_zeta.constraint_terms <== eval_vanishing_poly.constraint_terms;
  check_zeta.vanishing_partial_products_terms <== eval_vanishing_poly.vanishing_partial_products_terms;
  check_zeta.vanishing_z_1_terms <== eval_vanishing_poly.vanishing_z_1_terms;
}

component main {public [wires_cap]} = VerifyCheckZeta();
