pragma circom 2.1.0;
include "./goldilocks_ext.circom";
include "./utils.circom";

template EvalGateConstraints() {
  signal input constants[NUM_OPENINGS_CONSTANTS()][2];
  signal input wires[NUM_OPENINGS_WIRES()][2];
  signal input public_input_hash[4];

  signal filter[2];
}
