pragma circom 2.0.9;
include "./goldilocks.circom";

template EvalL1() {
  signal input n;
  signal input x[2];
  signal output out[2];

  signal x_sub_one[2];
  x_sub_one[0] <== x[0] - 1;
  x_sub_one[1] <== x[1];

  signal x_exp_n[2];
  component cem = GlExtExp();
  cem.x[0] <== x[0];
  cem.x[1] <== x[1];
  cem.n <== n;

  component ced = GlExtDiv();
  ced.a[0] <== cem.out[0] - 1;
  ced.a[1] <== cem.out[1];
  ced.b[0] <== x_sub_one[0] * n;
  ced.b[1] <== x_sub_one[1] * n;

  out[0] <== ced.out[0];
  out[1] <== ced.out[1];
}
