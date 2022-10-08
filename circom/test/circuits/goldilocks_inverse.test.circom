pragma circom 2.0.9;
include "../../circuits/goldilocks_inverse.circom";

template GlInvTest() {
  signal input in;
  signal output out;

  component cgi = GlInv();
  cgi.x <== 6784275835416866020;
  cgi.out === 7154952498519749264;

  // Dummy input/output
  in === 1;
  out <== 1;
}

component main = GlInvTest();
