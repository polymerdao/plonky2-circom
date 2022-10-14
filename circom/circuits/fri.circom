pragma circom 2.0.9;
include "./constants.circom";
include "./poseidon.circom";
include "./utils.circom";

// bit = a & 1
// out = a >> 1
template RShift1() {
  signal input a;
  signal output out;
  signal output bit;

  var o = a >> 1;
  out <-- o;
  bit <== a - out * 2;
  bit * (1 - bit) === 0;
}

template GetMerkleProofToCap(N) {
  signal input leaf[N][4];
  signal input leaf_index;
  signal output digest[4];
  signal output index;

  component cDigest = HashNoPad(N * 4);
  for (var i = 0; i < N; i++) {
    for (var j = 0; j < 4; j++) {
      cDigest.in[i * 4 + j] <== leaf[i][j];
    }
  }

  component poseidon0[N];
  component poseidon1[N];
  component shift[N + 1];
  signal digest_cur[N + 1][4];
  shift[0] = RShift1();
  shift[0].a <== leaf_index;
  digest_cur[0][0] <== cDigest.out[0];
  digest_cur[0][1] <== cDigest.out[1];
  digest_cur[0][2] <== cDigest.out[2];
  digest_cur[0][3] <== cDigest.out[3];
  signal tmp0[N];
  signal tmp1[N];
  signal tmp2[N];
  signal tmp3[N];
  for (var i = 0; i < N; i++) {
    poseidon0[i] = Poseidon(4);
    poseidon0[i].in[0] <== digest_cur[i][0];
    poseidon0[i].in[1] <== digest_cur[i][1];
    poseidon0[i].in[2] <== digest_cur[i][2];
    poseidon0[i].in[3] <== digest_cur[i][3];
    poseidon0[i].in[4] <== leaf[i][0];
    poseidon0[i].in[5] <== leaf[i][1];
    poseidon0[i].in[6] <== leaf[i][2];
    poseidon0[i].in[7] <== leaf[i][3];
    poseidon0[i].capacity[0] <== 0;
    poseidon0[i].capacity[1] <== 0;
    poseidon0[i].capacity[2] <== 0;
    poseidon0[i].capacity[3] <== 0;

    poseidon1[i] = Poseidon(4);
    poseidon1[i].in[0] <== leaf[i][0];
    poseidon1[i].in[1] <== leaf[i][1];
    poseidon1[i].in[2] <== leaf[i][2];
    poseidon1[i].in[3] <== leaf[i][3];
    poseidon1[i].in[4] <== digest_cur[i][0];
    poseidon1[i].in[5] <== digest_cur[i][1];
    poseidon1[i].in[6] <== digest_cur[i][2];
    poseidon1[i].in[7] <== digest_cur[i][3];
    poseidon1[i].capacity[0] <== 0;
    poseidon1[i].capacity[1] <== 0;
    poseidon1[i].capacity[2] <== 0;
    poseidon1[i].capacity[3] <== 0;

    tmp0[i] <== (1 - shift[i].bit) * poseidon0[i].out[0];
    tmp1[i] <== (1 - shift[i].bit) * poseidon0[i].out[1];
    tmp2[i] <== (1 - shift[i].bit) * poseidon0[i].out[2];
    tmp3[i] <== (1 - shift[i].bit) * poseidon0[i].out[3];
    digest_cur[i + 1][0] <== tmp0[i] + shift[i].bit * poseidon1[i].out[0];
    digest_cur[i + 1][1] <== tmp1[i] + shift[i].bit * poseidon1[i].out[1];
    digest_cur[i + 1][2] <== tmp2[i] + shift[i].bit * poseidon1[i].out[2];
    digest_cur[i + 1][3] <== tmp3[i] + shift[i].bit * poseidon1[i].out[3];

    shift[i + 1] = RShift1();
    shift[i + 1].a <== shift[i].out;
  }

  digest[0] <== digest_cur[N][0];
  digest[1] <== digest_cur[N][1];
  digest[2] <== digest_cur[N][2];
  digest[3] <== digest_cur[N][3];
  index <== shift[N].out;
}

template VerifyFriProof() {
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

  // Challenges
  signal input fri_alpha[2];
  signal input fri_betas[NUM_FRI_COMMIT_ROUND()][2];
  signal input fri_pow_response;
  signal input fri_query_indices[NUM_FRI_QUERY_ROUND()];

  signal output out;
  out <== 1;

  component sigma_caps[NUM_FRI_QUERY_ROUND()];
  component merklecaps[NUM_FRI_QUERY_ROUND()][4];

  for (var round = 0; round < NUM_FRI_QUERY_ROUND(); round++) {
    merklecaps[round][0] = GetMerkleProofToCap(NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_P());
    merklecaps[round][0].leaf_index <== fri_query_indices[round];
    for (var i = 0; i < NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_P(); i++) {
      merklecaps[round][0].leaf[i][0] <== fri_query_init_constants_sigmas_p[round][i][0];
      merklecaps[round][0].leaf[i][1] <== fri_query_init_constants_sigmas_p[round][i][1];
      merklecaps[round][0].leaf[i][2] <== fri_query_init_constants_sigmas_p[round][i][2];
      merklecaps[round][0].leaf[i][3] <== fri_query_init_constants_sigmas_p[round][i][3];
    }
    sigma_caps[round] = RandomAccess2(NUM_SIGMA_CAPS(), 4);
    for (var i = 0; i < NUM_SIGMA_CAPS(); i++) {
      var cap[4];
      cap = GET_SIGMA_CAP(i);
      sigma_caps[round].a[i][0] <== cap[0];
      sigma_caps[round].a[i][1] <== cap[1];
      sigma_caps[round].a[i][2] <== cap[2];
      sigma_caps[round].a[i][3] <== cap[3];
    }
    sigma_caps[round].idx <== merklecaps[round][0].index;
    merklecaps[round][0].digest[0] === sigma_caps[round].out[0];
    merklecaps[round][0].digest[1] === sigma_caps[round].out[1];
    merklecaps[round][0].digest[2] === sigma_caps[round].out[2];
    merklecaps[round][0].digest[3] === sigma_caps[round].out[3];
  }
}
