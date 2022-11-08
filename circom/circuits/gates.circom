pragma circom 2.1.0;
include "./goldilocks_ext.circom";
include "./utils.circom";
include "./poseidon.circom";

template ConstraintPush() {
  signal input constraint[2];
  signal input filter[2];
  signal input value[2];

  signal output out[2];
  out <== GlExtAdd()(constraint, GlExtMul()(value, filter));
}

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
  component c_PublicInputGateLib = PublicInputGateLib();
  c_PublicInputGateLib.constants <== constants;
  c_PublicInputGateLib.wires <== wires;
  c_PublicInputGateLib.public_input_hash <== public_input_hash;
  c_PublicInputGateLib.constraints <== c_Constant2.out;
  for (var i = 0; i < NUM_GATE_CONSTRAINTS(); i++) {
    log(i, c_PublicInputGateLib.out[i][0], c_PublicInputGateLib.out[i][1]);
  }

  // PoseidonGate { _phantom: PhantomData }<WIDTH=12>
  component c_Constant$NUM_CONSTANTS = Constant$NUM_CONSTANTS();
  c_Constant$NUM_CONSTANTS.constants <== constants;
  c_Constant$NUM_CONSTANTS.wires <== wires;
  c_Constant$NUM_CONSTANTS.public_input_hash <== public_input_hash;
  c_Constant$NUM_CONSTANTS.constraints <== c_PublicInputGateLib.out;
  for (var i = 0; i < NUM_GATE_CONSTRAINTS(); i++) {
    log(i, c_Constant$NUM_CONSTANTS.out[i][0], c_Constant$NUM_CONSTANTS.out[i][1]);
  }
  out <== c_Constant$NUM_CONSTANTS.out;
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
    out[i] <== ConstraintPush()(constraints[i], filter, GlExtSub()(constants[2 + i], wires[i]));
  }
  for (var i = 2; i < NUM_GATE_CONSTRAINTS(); i++) {
    out[i] <== constraints[i];
  }
}
template PublicInputGateLib() {
  signal input constants[NUM_OPENINGS_CONSTANTS()][2];
  signal input wires[NUM_OPENINGS_WIRES()][2];
  signal input public_input_hash[4];
  signal input constraints[NUM_GATE_CONSTRAINTS()][2];
  signal output out[NUM_GATE_CONSTRAINTS()][2];

  signal filter[2];
  filter <== GlExtMul()(GlExtSub()(GlExt(0, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(1, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(4294967295, 0)(), constants[0]), GlExt(1, 0)())));

  signal hashes[4][2];
  for (var i = 0; i < 4; i++) {
    hashes[i][0] <== public_input_hash[i];
    hashes[i][1] <== 0;
    out[i] <== ConstraintPush()(constraints[i], filter, GlExtSub()(wires[i], hashes[i]));
  }
  for (var i = 4; i < NUM_GATE_CONSTRAINTS(); i++) {
    out[i] <== constraints[i];
  }
}
template Constant$NUM_CONSTANTS() {
  signal input constants[NUM_OPENINGS_CONSTANTS()][2];
  signal input wires[NUM_OPENINGS_WIRES()][2];
  signal input public_input_hash[4];
  signal input constraints[NUM_GATE_CONSTRAINTS()][2];
  signal output out[NUM_GATE_CONSTRAINTS()][2];

  signal filter[2];
  filter <== GlExtMul()(GlExtSub()(GlExt(4294967295, 0)(), constants[1]), GlExt(1, 0)());

  var index = 0;
  out[index] <== ConstraintPush()(constraints[index], filter, GlExtMul()(wires[24], GlExtSub()(wires[24], GlExt(1, 0)())));
  index++;

  for (var i = 0; i < 4; i++) {
    out[index] <== ConstraintPush()(constraints[index], filter, GlExtSub()(GlExtMul()(wires[24], GlExtSub()(wires[i + 4], wires[i])), wires[25 + i]));
    index++;
  }

  // SPONGE_RATE = 8
  // SPONGE_CAPACITY = 4
  // SPONGE_WIDTH = 12
  signal state[12][4 * 4][2];
  var state_round = 0;
  for (var i = 0; i < 4; i++) {
    state[i][state_round] <== GlExtAdd()(wires[i], wires[25 + i]);
    state[i + 4][state_round] <== GlExtSub()(wires[i + 4], wires[25 + i]);
  }

  for (var i = 8; i < 12; i++) {
    state[i][state_round] <== wires[i];
  }
  state_round++;

  var round_ctr = 0;
  signal mds_row_shf_field[4][12][13][2];
  for (var r = 0; r < 4; r ++) {
    for (var i = 0; i < 12; i++) {
      state[i][state_round] <== GlExtAdd()(state[i][state_round - 1], GlExt(GL_CONST(i + 12 * round_ctr), 0)());
    }
    state_round++;
    if (r != 0 ) {
      for (var i = 0; i < 12; i++) {
        state[i][state_round] <== wires[25 + 4 + 12 * (r - 1) + i];
        out[index] <== ConstraintPush()(constraints[index], filter, GlExtSub()(state[i][state_round - 1], state[i][state_round]));
        index++;
      }
      state_round++;
    }
    for (var i = 0; i < 12; i++) {
      state[i][state_round] <== GlExtExpN(3)(state[i][state_round - 1], 7);
    }
    state_round++;
    for (var i = 0; i < 12; i++) { // for r
      mds_row_shf_field[r][i][0][0] <== 0;
      mds_row_shf_field[r][i][0][1] <== 0;
      for (var j = 0; j < 12; j++) { // for i,
        mds_row_shf_field[r][i][j + 1] <== GlExtAdd()(mds_row_shf_field[r][i][j], GlExtMul()(state[(i + j) % 12][state_round - 1], GlExt(MDS_MATRIX_CIRC(j), 0)()));
      }
      state[i][state_round] <== GlExtAdd()(mds_row_shf_field[r][i][12], GlExtMul()(state[i][state_round - 1], GlExt(MDS_MATRIX_DIAG(i), 0)()));
    }
    state_round++;
    round_ctr++;
  }

  for (var i = 0; i < 12; i++) {
    log(state[i][state_round - 1][0], state[i][state_round - 1][1]);
  }

  for (var i = index + 1; i < NUM_GATE_CONSTRAINTS(); i++) {
    out[i] <== constraints[i];
  }
}
function MDS_MATRIX_CIRC(i) {
  var mds[12];
  mds[0] = 17;
  mds[1] = 15;
  mds[2] = 41;
  mds[3] = 16;
  mds[4] = 2;
  mds[5] = 28;
  mds[6] = 13;
  mds[7] = 13;
  mds[8] = 39;
  mds[9] = 18;
  mds[10] = 34;
  mds[11] = 20;
  return mds[i];
}
function MDS_MATRIX_DIAG(i) {
  var mds[12];
  // TODO: All zeros?
  mds[0] = 8;
  mds[1] = 0;
  mds[2] = 0;
  mds[3] = 0;
  mds[4] = 0;
  mds[5] = 0;
  mds[6] = 0;
  mds[7] = 0;
  mds[8] = 0;
  mds[9] = 0;
  mds[10] = 0;
  mds[11] = 0;
  return mds[i];
}
