pragma circom 2.0.9;
include "../../circuits/goldilocks_ext.circom";

template GlTest() {
  signal input in;
  signal output out;

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

  // Ext div
  component cextdiv = GlExtDiv();
  cextdiv.a[0] <== 4994088319481652598;
  cextdiv.a[1] <== 16489566008211790727;
  cextdiv.b[0] <== 7166004739148609569;
  cextdiv.b[1] <== 14655965871663555016;

  cextdiv.out[0] === 15052319864161058789;
  cextdiv.out[1] === 16841416332519902625;

  // Ext exp
  component cextexp = GlExtExp();
  cextexp.x <== GlExt(9076502759914437505, 16396680756479675411)();
  cextexp.n <== 4096;

  cextexp.out[0] === 4994088319481652599;
  cextexp.out[1] === 16489566008211790727;

  // Dummy input/output
  in === 1;
  out <== 1;
}

component main = GlTest();
