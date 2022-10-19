pragma circom 2.0.9;
include "../../circuits/goldilocks.circom";

template GlTest() {
  signal input in;
  signal output out;

  // add
  component cadd = GlAdd();
  cadd.a <== 14992246389055333107;
  cadd.b <== 13533945482899040792;
  var expected = 10079447802539789578;
  cadd.out === expected;

  // mul
  component cmul = GlMul();
  var a = 16424245004931000714;
  var b = 2251799813160960;
  expected = 5496890231018735829;

  cmul.a <== a;
  cmul.b <== b;
  cmul.out === expected;

  // exp
  var x = 3511170319078647661;
  var n = 602096;
  expected = 8162053712235223550;

  component cexp = GlExp();
  cexp.x <== x;
  cexp.n <== n;
  cexp.out === expected;

  component cgi = GlInv();
  cgi.x <== 6784275835416866020;
  cgi.out === 7154952498519749264;

  component crs = RShift(2);
  crs.x <== 4;
  crs.out === 1;

  component crs1 = RShift(2);
  crs1.x <== 7;
  crs1.out === 1;

  component crb = ReverseBits(5);
  crb.x <== 19;
  crb.out === 25;

  component clb = LastNBits(3);
  clb.x <== 19;
  clb.out === 3;

  // Dummy input/output
  in === 1;
  out <== 1;
}

component main = GlTest();
