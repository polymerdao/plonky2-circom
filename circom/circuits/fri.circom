pragma circom 2.0.9;
include "./constants.circom";
include "./poseidon.circom";
include "./utils.circom";
include "./goldilocks.circom";

template GetMerkleProofToCap(nLeaf, nProof) {
  signal input leaf[nLeaf];
  signal input proof[nProof][4];
  signal input leaf_index;
  signal output digest[4];
  signal output index;

  component c_digest = HashNoPad(nLeaf);
  for (var i = 0; i < nLeaf; i++) {
      c_digest.in[i] <== leaf[i];
  }

  component poseidon0[nProof];
  component poseidon1[nProof];
  component shift[nProof];
  signal cur_digest[nProof + 1][4];

  shift[0] = RShift1();
  shift[0].a <== leaf_index;
  cur_digest[0][0] <== c_digest.out[0];
  cur_digest[0][1] <== c_digest.out[1];
  cur_digest[0][2] <== c_digest.out[2];
  cur_digest[0][3] <== c_digest.out[3];

  signal tmp0[nProof];
  signal tmp1[nProof];
  signal tmp2[nProof];
  signal tmp3[nProof];
  for (var i = 0; i < nProof; i++) {
    poseidon0[i] = Poseidon(4);
    poseidon0[i].in[0] <== cur_digest[i][0];
    poseidon0[i].in[1] <== cur_digest[i][1];
    poseidon0[i].in[2] <== cur_digest[i][2];
    poseidon0[i].in[3] <== cur_digest[i][3];
    poseidon0[i].in[4] <== proof[i][0];
    poseidon0[i].in[5] <== proof[i][1];
    poseidon0[i].in[6] <== proof[i][2];
    poseidon0[i].in[7] <== proof[i][3];
    poseidon0[i].capacity[0] <== 0;
    poseidon0[i].capacity[1] <== 0;
    poseidon0[i].capacity[2] <== 0;
    poseidon0[i].capacity[3] <== 0;

    poseidon1[i] = Poseidon(4);
    poseidon1[i].in[0] <== proof[i][0];
    poseidon1[i].in[1] <== proof[i][1];
    poseidon1[i].in[2] <== proof[i][2];
    poseidon1[i].in[3] <== proof[i][3];
    poseidon1[i].in[4] <== cur_digest[i][0];
    poseidon1[i].in[5] <== cur_digest[i][1];
    poseidon1[i].in[6] <== cur_digest[i][2];
    poseidon1[i].in[7] <== cur_digest[i][3];
    poseidon1[i].capacity[0] <== 0;
    poseidon1[i].capacity[1] <== 0;
    poseidon1[i].capacity[2] <== 0;
    poseidon1[i].capacity[3] <== 0;

    tmp0[i] <== (1 - shift[i].bit) * poseidon0[i].out[0];
    tmp1[i] <== (1 - shift[i].bit) * poseidon0[i].out[1];
    tmp2[i] <== (1 - shift[i].bit) * poseidon0[i].out[2];
    tmp3[i] <== (1 - shift[i].bit) * poseidon0[i].out[3];
    cur_digest[i + 1][0] <== tmp0[i] + shift[i].bit * poseidon1[i].out[0];
    cur_digest[i + 1][1] <== tmp1[i] + shift[i].bit * poseidon1[i].out[1];
    cur_digest[i + 1][2] <== tmp2[i] + shift[i].bit * poseidon1[i].out[2];
    cur_digest[i + 1][3] <== tmp3[i] + shift[i].bit * poseidon1[i].out[3];

    if (i < nProof - 1) {
      shift[i + 1] = RShift1();
      shift[i + 1].a <== shift[i].out;
    }
  }

  digest[0] <== cur_digest[nProof][0];
  digest[1] <== cur_digest[nProof][1];
  digest[2] <== cur_digest[nProof][2];
  digest[3] <== cur_digest[nProof][3];
  index <== shift[nProof - 1].out;
}

template VerifyFriProof() {
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

  // Challenges
  signal input fri_alpha[2];
  signal input fri_betas[NUM_FRI_COMMIT_ROUND()][2];
  signal input fri_pow_response;
  signal input fri_query_indices[NUM_FRI_QUERY_ROUND()];

  // TODO: remove out
  signal output out;
  out <== 1;

  assert(NUM_REDUCTION_ARITY_BITS() == 2);
  var arity_bits[NUM_REDUCTION_ARITY_BITS()] = REDUCTION_ARITY_BITS();
  signal arity[NUM_REDUCTION_ARITY_BITS()];
  for (var i = 0; i < NUM_REDUCTION_ARITY_BITS(); i++) {
    arity[i] <== 1 << arity_bits[i];
  }
  component coset_index[NUM_FRI_QUERY_ROUND()][NUM_REDUCTION_ARITY_BITS()];

  component sigma_caps[NUM_FRI_QUERY_ROUND()];
  component merkle_caps[NUM_FRI_QUERY_ROUND()][6];
  component c_wires_cap[NUM_FRI_QUERY_ROUND()];
  component c_plonk_zs_partial_products_cap[NUM_FRI_QUERY_ROUND()];
  component c_quotient_polys_cap[NUM_FRI_QUERY_ROUND()];
  component c_commit_merkle_cap[NUM_FRI_QUERY_ROUND()][NUM_REDUCTION_ARITY_BITS()];

  for (var round = 0; round < NUM_FRI_QUERY_ROUND(); round++) {
  // for (var round = 0; round < 2; round++) {
    // constants_sigmas
    merkle_caps[round][0] = GetMerkleProofToCap(NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_V(),
                                                NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_P());
    merkle_caps[round][0].leaf_index <== fri_query_indices[round];
    for (var i = 0; i < NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_V(); i++) {
      merkle_caps[round][0].leaf[i] <== fri_query_init_constants_sigmas_v[round][i];
    }
    for (var i = 0; i < NUM_FRI_QUERY_INIT_CONSTANTS_SIGMAS_P(); i++) {
      merkle_caps[round][0].proof[i][0] <== fri_query_init_constants_sigmas_p[round][i][0];
      merkle_caps[round][0].proof[i][1] <== fri_query_init_constants_sigmas_p[round][i][1];
      merkle_caps[round][0].proof[i][2] <== fri_query_init_constants_sigmas_p[round][i][2];
      merkle_caps[round][0].proof[i][3] <== fri_query_init_constants_sigmas_p[round][i][3];
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
    sigma_caps[round].idx <== merkle_caps[round][0].index;
    merkle_caps[round][0].digest[0] === sigma_caps[round].out[0];
    merkle_caps[round][0].digest[1] === sigma_caps[round].out[1];
    merkle_caps[round][0].digest[2] === sigma_caps[round].out[2];
    merkle_caps[round][0].digest[3] === sigma_caps[round].out[3];

    // wires
    merkle_caps[round][1] = GetMerkleProofToCap(NUM_FRI_QUERY_INIT_WIRES_V(),
                                                NUM_FRI_QUERY_INIT_WIRES_P());
    merkle_caps[round][1].leaf_index <== fri_query_indices[round];
    for (var i = 0; i < NUM_FRI_QUERY_INIT_WIRES_V(); i++) {
      merkle_caps[round][1].leaf[i] <== fri_query_init_wires_v[round][i];
    }
    for (var i = 0; i < NUM_FRI_QUERY_INIT_WIRES_P(); i++) {
      merkle_caps[round][1].proof[i][0] <== fri_query_init_wires_p[round][i][0];
      merkle_caps[round][1].proof[i][1] <== fri_query_init_wires_p[round][i][1];
      merkle_caps[round][1].proof[i][2] <== fri_query_init_wires_p[round][i][2];
      merkle_caps[round][1].proof[i][3] <== fri_query_init_wires_p[round][i][3];
    }
    c_wires_cap[round] = RandomAccess2(NUM_WIRES_CAP(), 4);
    for (var i = 0; i < NUM_WIRES_CAP(); i++) {
      c_wires_cap[round].a[i][0] <== wires_cap[i][0];
      c_wires_cap[round].a[i][1] <== wires_cap[i][1];
      c_wires_cap[round].a[i][2] <== wires_cap[i][2];
      c_wires_cap[round].a[i][3] <== wires_cap[i][3];
    }
    c_wires_cap[round].idx <== merkle_caps[round][1].index;
    merkle_caps[round][1].digest[0] === c_wires_cap[round].out[0];
    merkle_caps[round][1].digest[1] === c_wires_cap[round].out[1];
    merkle_caps[round][1].digest[2] === c_wires_cap[round].out[2];
    merkle_caps[round][1].digest[3] === c_wires_cap[round].out[3];

    // plonk_zs_partial_products
    merkle_caps[round][2] = GetMerkleProofToCap(NUM_FRI_QUERY_INIT_ZS_PARTIAL_V(),
                                                NUM_FRI_QUERY_INIT_ZS_PARTIAL_P());
    merkle_caps[round][2].leaf_index <== fri_query_indices[round];
    for (var i = 0; i < NUM_FRI_QUERY_INIT_ZS_PARTIAL_V(); i++) {
      merkle_caps[round][2].leaf[i] <== fri_query_init_zs_partial_v[round][i];
    }
    for (var i = 0; i < NUM_FRI_QUERY_INIT_ZS_PARTIAL_P(); i++) {
      merkle_caps[round][2].proof[i][0] <== fri_query_init_zs_partial_p[round][i][0];
      merkle_caps[round][2].proof[i][1] <== fri_query_init_zs_partial_p[round][i][1];
      merkle_caps[round][2].proof[i][2] <== fri_query_init_zs_partial_p[round][i][2];
      merkle_caps[round][2].proof[i][3] <== fri_query_init_zs_partial_p[round][i][3];
    }
    c_plonk_zs_partial_products_cap[round] = RandomAccess2(NUM_PLONK_ZS_PARTIAL_PRODUCTS_CAP(), 4);
    for (var i = 0; i < NUM_PLONK_ZS_PARTIAL_PRODUCTS_CAP(); i++) {
      c_plonk_zs_partial_products_cap[round].a[i][0] <== plonk_zs_partial_products_cap[i][0];
      c_plonk_zs_partial_products_cap[round].a[i][1] <== plonk_zs_partial_products_cap[i][1];
      c_plonk_zs_partial_products_cap[round].a[i][2] <== plonk_zs_partial_products_cap[i][2];
      c_plonk_zs_partial_products_cap[round].a[i][3] <== plonk_zs_partial_products_cap[i][3];
    }
    c_plonk_zs_partial_products_cap[round].idx <== merkle_caps[round][2].index;
    merkle_caps[round][2].digest[0] === c_plonk_zs_partial_products_cap[round].out[0];
    merkle_caps[round][2].digest[1] === c_plonk_zs_partial_products_cap[round].out[1];
    merkle_caps[round][2].digest[2] === c_plonk_zs_partial_products_cap[round].out[2];
    merkle_caps[round][2].digest[3] === c_plonk_zs_partial_products_cap[round].out[3];

    // quotient
    merkle_caps[round][3] = GetMerkleProofToCap(NUM_FRI_QUERY_INIT_QUOTIENT_V(),
                                                NUM_FRI_QUERY_INIT_QUOTIENT_P());
    merkle_caps[round][3].leaf_index <== fri_query_indices[round];
    for (var i = 0; i < NUM_FRI_QUERY_INIT_QUOTIENT_V(); i++) {
      merkle_caps[round][3].leaf[i] <== fri_query_init_quotient_v[round][i];
    }
    for (var i = 0; i < NUM_FRI_QUERY_INIT_QUOTIENT_P(); i++) {
      merkle_caps[round][3].proof[i][0] <== fri_query_init_quotient_p[round][i][0];
      merkle_caps[round][3].proof[i][1] <== fri_query_init_quotient_p[round][i][1];
      merkle_caps[round][3].proof[i][2] <== fri_query_init_quotient_p[round][i][2];
      merkle_caps[round][3].proof[i][3] <== fri_query_init_quotient_p[round][i][3];
    }
    c_quotient_polys_cap[round] = RandomAccess2(NUM_QUOTIENT_POLYS_CAP(), 4);
    for (var i = 0; i < NUM_QUOTIENT_POLYS_CAP(); i++) {
      c_quotient_polys_cap[round].a[i][0] <== quotient_polys_cap[i][0];
      c_quotient_polys_cap[round].a[i][1] <== quotient_polys_cap[i][1];
      c_quotient_polys_cap[round].a[i][2] <== quotient_polys_cap[i][2];
      c_quotient_polys_cap[round].a[i][3] <== quotient_polys_cap[i][3];
    }
    c_quotient_polys_cap[round].idx <== merkle_caps[round][3].index;
    merkle_caps[round][3].digest[0] === c_quotient_polys_cap[round].out[0];
    merkle_caps[round][3].digest[1] === c_quotient_polys_cap[round].out[1];
    merkle_caps[round][3].digest[2] === c_quotient_polys_cap[round].out[2];
    merkle_caps[round][3].digest[3] === c_quotient_polys_cap[round].out[3];

    for (var i = 0; i < NUM_REDUCTION_ARITY_BITS(); i++) {
      coset_index[round][i] = RShift(arity_bits[i]);
      if (i == 0) {
        coset_index[round][i].x <== fri_query_indices[round];
      } else {
        coset_index[round][i].x <== coset_index[round][i - 1].out;
      }

      // step 0
      if (i == 0) {
        merkle_caps[round][4] = GetMerkleProofToCap(NUM_FRI_QUERY_STEP0_V() * 2,
                                                    NUM_FRI_QUERY_STEP0_P());
        merkle_caps[round][4].leaf_index <== coset_index[round][i].out;
        for (var j = 0; j < NUM_FRI_QUERY_STEP0_V(); j++) {
          merkle_caps[round][4].leaf[j * 2] <== fri_query_step0_v[round][j][0];
          merkle_caps[round][4].leaf[j * 2 + 1] <== fri_query_step0_v[round][j][1];
        }
        for (var j = 0; j < NUM_FRI_QUERY_STEP0_P(); j++) {
          merkle_caps[round][4].proof[j][0] <== fri_query_step0_p[round][j][0];
          merkle_caps[round][4].proof[j][1] <== fri_query_step0_p[round][j][1];
          merkle_caps[round][4].proof[j][2] <== fri_query_step0_p[round][j][2];
          merkle_caps[round][4].proof[j][3] <== fri_query_step0_p[round][j][3];
        }
        c_commit_merkle_cap[round][i] = RandomAccess2(FRI_COMMIT_MERKLE_CAP_HEIGHT(), 4);
        for (var j = 0; j < FRI_COMMIT_MERKLE_CAP_HEIGHT(); j++) {
          c_commit_merkle_cap[round][i].a[j][0] <== fri_commit_phase_merkle_caps[i][j][0];
          c_commit_merkle_cap[round][i].a[j][1] <== fri_commit_phase_merkle_caps[i][j][1];
          c_commit_merkle_cap[round][i].a[j][2] <== fri_commit_phase_merkle_caps[i][j][2];
          c_commit_merkle_cap[round][i].a[j][3] <== fri_commit_phase_merkle_caps[i][j][3];
        }
        c_commit_merkle_cap[round][i].idx <== merkle_caps[round][4].index;
        merkle_caps[round][4].digest[0] === c_commit_merkle_cap[round][i].out[0];
        merkle_caps[round][4].digest[1] === c_commit_merkle_cap[round][i].out[1];
        merkle_caps[round][4].digest[2] === c_commit_merkle_cap[round][i].out[2];
        merkle_caps[round][4].digest[3] === c_commit_merkle_cap[round][i].out[3];
      }

      // step 1
      if (i == 1) {
        merkle_caps[round][5] = GetMerkleProofToCap(NUM_FRI_QUERY_STEP1_V() * 2,
                                                    NUM_FRI_QUERY_STEP1_P());
        merkle_caps[round][5].leaf_index <== coset_index[round][i].out;
        for (var j = 0; j < NUM_FRI_QUERY_STEP1_V(); j++) {
          merkle_caps[round][5].leaf[j * 2] <== fri_query_step1_v[round][j][0];
          merkle_caps[round][5].leaf[j * 2 + 1] <== fri_query_step1_v[round][j][1];
        }
        for (var j = 0; j < NUM_FRI_QUERY_STEP1_P(); j++) {
          merkle_caps[round][5].proof[j][0] <== fri_query_step1_p[round][j][0];
          merkle_caps[round][5].proof[j][1] <== fri_query_step1_p[round][j][1];
          merkle_caps[round][5].proof[j][2] <== fri_query_step1_p[round][j][2];
          merkle_caps[round][5].proof[j][3] <== fri_query_step1_p[round][j][3];
        }
        c_commit_merkle_cap[round][i] = RandomAccess2(FRI_COMMIT_MERKLE_CAP_HEIGHT(), 4);
        for (var j = 0; j < FRI_COMMIT_MERKLE_CAP_HEIGHT(); j++) {
          c_commit_merkle_cap[round][i].a[j][0] <== fri_commit_phase_merkle_caps[i][j][0];
          c_commit_merkle_cap[round][i].a[j][1] <== fri_commit_phase_merkle_caps[i][j][1];
          c_commit_merkle_cap[round][i].a[j][2] <== fri_commit_phase_merkle_caps[i][j][2];
          c_commit_merkle_cap[round][i].a[j][3] <== fri_commit_phase_merkle_caps[i][j][3];
        }
        c_commit_merkle_cap[round][i].idx <== merkle_caps[round][5].index;
        merkle_caps[round][5].digest[0] === c_commit_merkle_cap[round][i].out[0];
        merkle_caps[round][5].digest[1] === c_commit_merkle_cap[round][i].out[1];
        merkle_caps[round][5].digest[2] === c_commit_merkle_cap[round][i].out[2];
        merkle_caps[round][5].digest[3] === c_commit_merkle_cap[round][i].out[3];
      }
    }
  }
}
