pragma circom 2.0.9;
include "../../circuits/goldilocks.circom";

template GlTest() {
  signal input in;
  signal output out;

  // add        require(GoldilocksFieldLib.add(14992246389055333107, 13533945482899040792) == 10079447802539789578);
  var a = 14992246389055333107;
  var b = 13533945482899040792;
  var expected = 10079447802539789578;

  signal sum <== a + b;
  sum === expected;

  // mul         require(GoldilocksFieldLib.mul(16424245004931000714, 2251799813160960) == 5496890231018735829);
  a = 16424245004931000714;
  b = 2251799813160960;
  expected = 5496890231018735829;
  signal mul <== a * b;
  mul === expected;

  // exp        require(GoldilocksFieldLib.exp(3511170319078647661, 602096) == 8162053712235223550);
  var x = 3511170319078647661;
  var n = 602096;
  expected = 8162053712235223550;

  component cexp = GlExp();
  cexp.x <== x;
  cexp.n <== n;
  cexp.out === expected;

  // inv        require(GoldilocksFieldLib.inverse(6784275835416866020) == 7154952498519749264);
  x = 6784275835416866020;
  expected = 7154952498519749264;
  signal inv <== 1 / x;
  expected === inv;

  // Ext mul
  var x1[2];
  var x2[2];
  x1[0] = 4994088319481652598;
  x1[1] = 16489566008211790727;
  x2[0] = 3797605683985595697;
  x2[1] = 13424401189265534004;
  var expected_ext[2];
  expected_ext[0] = 15052319864161058789;
  expected_ext[1] = 16841416332519902625;
  component cextmul = GlExtMul();
  cextmul.a[0] <== x1[0];
  cextmul.b[0] <== x2[0];
  cextmul.a[1] <== x1[1];
  cextmul.b[1] <== x2[1];
  cextmul.out[0] === expected_ext[0];
  cextmul.out[1] === expected_ext[1];

  // Dummy input/output
  in === 1;
  out <== 1;
}

component main = GlTest();