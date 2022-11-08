pragma circom 2.1.0;
include "./goldilocks_ext.circom";
include "./utils.circom";

template EvalGateConstraints() {
  signal input constants[NUM_OPENINGS_CONSTANTS()][2];
  signal input wires[NUM_OPENINGS_WIRES()][2];
  signal input public_input_hash[4];
  signal input constraints[NUM_GATE_CONSTRAINTS()][2];
  signal output out[NUM_GATE_CONSTRAINTS()][2];

  // ConstantGate { num_consts: 2 }
  component c_Constant2 = Constant2();
  c_Constant2.constants <== constants;
  c_Constant2.wires <== wires;
  c_Constant2.public_input_hash <== public_input_hash;
  c_Constant2.constraints <== constraints;
  for (var i = 0; i < NUM_GATE_CONSTRAINTS(); i++) {
    log(i, c_Constant2.out[i][0], c_Constant2.out[i][1]);
  }

  // PublicInputGate

  // PoseidonGate { _phantom: PhantomData }<WIDTH=12>
  out <== c_Constant2.out;
}
template Constant2() {
  signal input constants[NUM_OPENINGS_CONSTANTS()][2];
  signal input wires[NUM_OPENINGS_WIRES()][2];
  signal input public_input_hash[4];
  signal input constraints[NUM_GATE_CONSTRAINTS()][2];
  signal output out[NUM_GATE_CONSTRAINTS()][2];

  signal filter[2];
  filter <== GlExtMul()(GlExtSub()(GlExt(0, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(2, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(4294967295, 0)(), constants[0]), GlExt(1, 0)())));

  for (var i = 0; i < 2; i++) {
    out[i] <== GlExtAdd()(constraints[i], GlExtMul()(GlExtSub()(constants[2 + i], wires[i]), filter));
  }
  for (var i = 2; i < NUM_GATE_CONSTRAINTS(); i++) {
    out[i] <== constraints[i];
  }
}
