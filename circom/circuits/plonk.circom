pragma circom 2.1.0;
include "./goldilocks_ext.circom";
include "./utils.circom";

template EvalL1() {
  signal input n;
  signal input x[2];
  signal output out[2];

  signal x_sub_one[2];
  x_sub_one[0] <== x[0] - 1;
  x_sub_one[1] <== x[1];

  component cem = GlExtExp();
  cem.x[0] <== x[0];
  cem.x[1] <== x[1];
  cem.n <== n;

  component xn0 = GlReduce(64);
  xn0.x <== x_sub_one[0] * n;
  component xn1 = GlReduce(64);
  xn1.x <== x_sub_one[1] * n;
  component ced = GlExtDiv();
  ced.a[0] <== cem.out[0] - 1;
  ced.a[1] <== cem.out[1];
  ced.b[0] <== xn0.out;
  ced.b[1] <== xn1.out;

  out[0] <== ced.out[0];
  out[1] <== ced.out[1];
}

template EvalGateConstraints() {
}

template EvalVanishingPoly() {
  signal input plonk_zeta[2];
  signal output constraint_terms[NUM_GATE_CONSTRAINTS()][2];
  signal output vanishing_partial_products_terms[NUM_PARTIAL_PRODUCTS_TERMS() * NUM_CHALLENGES()][2];
  signal output vanishing_z_1_terms[NUM_CHALLENGES()][2];
  signal l1_x[2] <== EvalL1()((1 << DEGREE_BITS()), plonk_zeta);
  signal one[2];
  one[0] <== 1;
  one[1] <== 0;
  for (var i = 0; i < NUM_CHALLENGES(); i++) {
    vanishing_z_1_terms[i] <== GlExtMul()(l1_x, GlExtSub()(plonk_zeta, one));
  }
}

template CheckZeta() {
  signal input openings_quotient_polys[NUM_OPENINGS_QUOTIENT_POLYS()][2];
  signal input plonk_alphas[NUM_CHALLENGES()];
  signal input plonk_zeta[2];
  signal input constraint_terms[NUM_GATE_CONSTRAINTS()][2];
  signal input vanishing_partial_products_terms[NUM_PARTIAL_PRODUCTS_TERMS() * NUM_CHALLENGES()][2];
  signal input vanishing_z_1_terms[NUM_CHALLENGES()][2];

  component c_reduce[NUM_CHALLENGES()][3];
  for (var i = 0; i < NUM_CHALLENGES(); i++) {
    c_reduce[i][0] = Reduce(NUM_GATE_CONSTRAINTS());
    for (var j = 0; j < NUM_GATE_CONSTRAINTS(); j++) {
      c_reduce[i][0].in[j] <== constraint_terms[j];
    }
    c_reduce[i][0].alpha[0] <== plonk_alphas[i];
    c_reduce[i][0].alpha[1] <== 0;
    if (i == 0) {
      c_reduce[i][0].old_eval[0] <== 0;
      c_reduce[i][0].old_eval[1] <== 0;
    } else {
      c_reduce[i][0].old_eval <== c_reduce[i - 1][0].out;
    }

    c_reduce[i][1] = Reduce(NUM_PARTIAL_PRODUCTS_TERMS() * NUM_CHALLENGES());
    for (var j = 0; j < NUM_PARTIAL_PRODUCTS_TERMS() * NUM_CHALLENGES(); j++) {
      c_reduce[i][1].in[j] <== vanishing_partial_products_terms[j];
    }
    c_reduce[i][1].alpha[0] <== plonk_alphas[i];
    c_reduce[i][1].alpha[1] <== 0;
    c_reduce[i][1].old_eval <== c_reduce[i][0].out;

    c_reduce[i][2] = Reduce(NUM_CHALLENGES());
    for (var j = 0; j < NUM_CHALLENGES(); j++) {
      c_reduce[i][2].in[j] <== vanishing_z_1_terms[j];
    }
    c_reduce[i][2].alpha[0] <== plonk_alphas[i];
    c_reduce[i][2].alpha[1] <== 0;
    c_reduce[i][2].old_eval <== c_reduce[i][1].out;
  }

  signal zeta_pow_deg[2] <== GlExtExpPowerOf2(DEGREE_BITS())(plonk_zeta);
  signal one[2];
  one[0] <== 1;
  one[1] <== 0;
  signal z_h_zeta[2] <== GlExtSub()(zeta_pow_deg, one);
  signal zeta[NUM_CHALLENGES()][2];
  component c_reduce_with_powers[NUM_CHALLENGES()];
  for (var i = 0; i < NUM_CHALLENGES(); i++) {
    c_reduce_with_powers[i] = ReduceWithPowers(QUOTIENT_DEGREE_FACTOR());
    c_reduce_with_powers[i].alpha <== zeta_pow_deg;
    for (var j = 0; j < QUOTIENT_DEGREE_FACTOR(); j++) {
      c_reduce_with_powers[i].in[j] <== openings_quotient_polys[i * QUOTIENT_DEGREE_FACTOR() + j];
    }
    zeta[i] <== GlExtMul()(z_h_zeta, c_reduce_with_powers[i].out);
    c_reduce[i][2].out === zeta[i];
  }
}

// debug only
component main = EvalVanishingPoly();
