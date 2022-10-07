pragma circom 2.0.9;
include "../../circuits/plonk.circom";

template PlonkTest() {
  signal input in;
  signal output out;

  // Dummy input/output
  in === 1;
  out <== 1;

  component ceval = EvalL1();
  ceval.x[0] <== 9076502759914437505;
  ceval.x[1] <== 16396680756479675411;
  ceval.n <== 4096;
  ceval.out[0] === 15052319864161058789;
  ceval.out[1] === 16841416332519902625;
}

component main = PlonkTest();
