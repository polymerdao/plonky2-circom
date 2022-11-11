// This file was generated by verifier.rs

pragma circom 2.1.0;
include "./goldilocks_ext.circom";
include "./utils.circom";
include "./poseidon.circom";

template WiresAlgebreMul(l, r) {
  signal input wires[NUM_OPENINGS_WIRES()][2];
  signal output out[2][2];
  out[0] <== GlExtAdd()(GlExtMul()(wires[l], wires[r]), GlExtMul()(GlExtMul()(GlExt(7, 0)(), wires[l + 1]), wires[r + 1]));
  out[1] <== GlExtAdd()(GlExtMul()(wires[l], wires[r + 1]), GlExtMul()(wires[l + 1], wires[r]));
}

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

  // BaseSumGate { num_limbs: 36 } + Base: 2
  component c_BaseSum36 = BaseSum36();
  c_BaseSum36.constants <== constants;
  c_BaseSum36.wires <== wires;
  c_BaseSum36.public_input_hash <== public_input_hash;
  c_BaseSum36.constraints <== c_PublicInputGateLib.out;
  for (var i = 0; i < NUM_GATE_CONSTRAINTS(); i++) {
    log(i, c_BaseSum36.out[i][0], c_BaseSum36.out[i][1]);
  }

  // LowDegreeInterpolationGate { subgroup_bits: 4, _phantom: PhantomData }<D=2>
  component c_LowDegreeInterpolation4 = LowDegreeInterpolation4();
  c_LowDegreeInterpolation4.constants <== constants;
  c_LowDegreeInterpolation4.wires <== wires;
  c_LowDegreeInterpolation4.public_input_hash <== public_input_hash;
  c_LowDegreeInterpolation4.constraints <== c_BaseSum36.out;
  for (var i = 0; i < NUM_GATE_CONSTRAINTS(); i++) {
    log(i, c_LowDegreeInterpolation4.out[i][0], c_LowDegreeInterpolation4.out[i][1]);
  }

  // ReducingExtensionGate { num_coeffs: 15 }

  // ReducingGate { num_coeffs: 31 }

  // ArithmeticExtensionGate { num_ops: 4 }

  // ArithmeticGate { num_ops: 9 }

  // MulExtensionGate { num_ops: 6 }

  // ExponentiationGate { num_power_bits: 35, _phantom: PhantomData }<D=2>

  // RandomAccessGate { bits: 4, num_copies: 2, num_extra_constants: 1, _phantom: PhantomData }<D=2>

  // PoseidonGate { _phantom: PhantomData }<WIDTH=12>
  out <== c_LowDegreeInterpolation4.out;
}
template Constant2() {
  signal input constants[NUM_OPENINGS_CONSTANTS()][2];
  signal input wires[NUM_OPENINGS_WIRES()][2];
  signal input public_input_hash[4];
  signal input constraints[NUM_GATE_CONSTRAINTS()][2];
  signal output out[NUM_GATE_CONSTRAINTS()][2];

  signal filter[2];
  filter <== GlExtMul()(GlExtSub()(GlExt(0, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(2, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(3, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(4, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(5, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(6, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(4294967295, 0)(), constants[0]), GlExt(1, 0)())))))));

  for (var i = 0; i < 2; i++) {
    out[i] <== ConstraintPush()(constraints[i], filter, GlExtSub()(constants[3 + i], wires[i]));
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
  filter <== GlExtMul()(GlExtSub()(GlExt(0, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(1, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(3, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(4, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(5, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(6, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(4294967295, 0)(), constants[0]), GlExt(1, 0)())))))));

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
template BaseSum36() {
  signal input constants[NUM_OPENINGS_CONSTANTS()][2];
  signal input wires[NUM_OPENINGS_WIRES()][2];
  signal input public_input_hash[4];
  signal input constraints[NUM_GATE_CONSTRAINTS()][2];
  signal output out[NUM_GATE_CONSTRAINTS()][2];

  signal filter[2];
  filter <== GlExtMul()(GlExtSub()(GlExt(0, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(1, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(2, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(4, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(5, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(6, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(4294967295, 0)(), constants[0]), GlExt(1, 0)())))))));

  component reduce = Reduce(36);
  reduce.alpha <== GlExt(2, 0)();
  reduce.old_eval <== GlExt(0, 0)();
  for (var i = 1; i < 36 + 1; i++) {
    reduce.in[i - 1] <== wires[i];
  }
  out[0] <== ConstraintPush()(constraints[0], filter, GlExtSub()(reduce.out, wires[0]));
  component product[36][2 - 1];
  for (var i = 0; i < 36; i++) {
    for (var j = 0; j < 2 - 1; j++) {
      product[i][j] = GlExtMul();
      if (j == 0) product[i][j].a <== wires[i + 1];
      else product[i][j].a <== product[i][j - 1].out;
      product[i][j].b <== GlExtSub()(wires[i + 1], GlExt(j + 1, 0)());
    }
    out[i + 1] <== ConstraintPush()(constraints[i + 1], filter, product[i][2 - 2].out);
  }
  for (var i = 36 + 1; i < NUM_GATE_CONSTRAINTS(); i++) {
    out[i] <== constraints[i];
  }
}
template LowDegreeInterpolation4() {
  signal input constants[NUM_OPENINGS_CONSTANTS()][2];
  signal input wires[NUM_OPENINGS_WIRES()][2];
  signal input public_input_hash[4];
  signal input constraints[NUM_GATE_CONSTRAINTS()][2];
  signal output out[NUM_GATE_CONSTRAINTS()][2];

  signal filter[2];
  filter <== GlExtMul()(GlExtSub()(GlExt(0, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(1, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(2, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(3, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(5, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(6, 0)(), constants[0]), GlExtMul()(GlExtSub()(GlExt(4294967295, 0)(), constants[0]), GlExt(1, 0)())))))));

  var index = 0;
  signal altered_coeffs[16][2][2];
  signal powers_shift[16][2];
  powers_shift[0][0] <== 1;
  powers_shift[0][1] <== 0;
  powers_shift[1] <== wires[0];
  for (var i = 2; i < 16; i++) {
    powers_shift[i] <== wires[1 + 2 * 16 * 2 + 2 + 2 + i - 2];
  }
  for (var i = 2; i < 16; i++) {
    out[index] <== ConstraintPush()(constraints[index], filter, GlExtSub()(GlExtMul()(powers_shift[i - 1], powers_shift[1]), powers_shift[i]));
    index++;
  }
  for (var i = 0; i < 16; i++) {
    for (var j = 0; j < 2; j++) {
      altered_coeffs[i][j] <== GlExtMul()(wires[wires_coeff_start(i) + j], powers_shift[i]);
    }
  }
  signal value[16][2][2];
  signal acc[16][16][2][2];
  for (var i = 0; i < 16; i++) {
    for (var j = 0; j < 2; j++) {
      value[i][j] <== wires[1 + i * 2 + j];
    }
    for (var j = 16; j > 0; j--) {
      for (var k = 0; k < 2; k++) {
        if (j == 16) acc[i][j - 1][k] <== altered_coeffs[j - 1][k];
        else acc[i][j - 1][k] <== GlExtAdd()(GlExtMul()(acc[i][j][k], GlExt(two_adic_subgroup(i), 0)()), altered_coeffs[j - 1][k]);
      }
    }
    for (var j = 0; j < 2; j++) {
      out[index] <== ConstraintPush()(constraints[index], filter, GlExtSub()(value[i][j], acc[i][0][j]));
      index++;
    }
  }
  signal m[16 - 2][2][2];
  for (var i = 1; i < 16 - 1; i++) {
    m[i - 1] <== WiresAlgebreMul(powers_evaluation_start(i), powers_evaluation_start(1))(wires);
    for (var j = 0; j < 2; j++) {
      out[index] <== ConstraintPush()(constraints[index], filter, GlExtSub()(m[i - 1][j], wires[powers_evaluation_start(i + 1) + j]));
      index++;
    }
  }

  signal acc2[2][16][2];
  for (var i = 0; i < 2; i++) {
    acc2[i][0] <== wires[wires_coeff_start(0) + i];
  }
  signal m2[16 - 1][2][2];
  for (var i = 1; i < 16; i++) {
    m2[i - 1] <== WiresAlgebreMul(powers_evaluation_start(i), wires_coeff_start(i))(wires);
    for (var j = 0; j < 2; j++) {
      acc2[j][i] <== GlExtAdd()(acc2[j][i - 1], m2[i - 1][j]);
    }
  }
  for (var i = 0; i < 2; i++) {
    out[index] <== ConstraintPush()(constraints[index], filter, GlExtSub()(wires[1 + 16 * 2 + 2 + i], acc2[i][16 - 1]));
    index++;
  }

  for (var i = index; i < NUM_GATE_CONSTRAINTS(); i++) {
    out[i] <== constraints[i];
  }
}
function powers_evaluation_start(i) {
  if (i == 1) return 1 + 16 * 2;
  else return 1 + 2 + 2 + 2 * 16 * 2 + 16 - 2 + (i - 2) * 2;
}
function wires_coeff_start(i) {
  return 1 + (16 + i + 2) * 2;
}
function two_adic_subgroup(i) {
  var subgroup[16];
  subgroup[0] = 1;
  subgroup[1] = 17293822564807737345;
  subgroup[2] = 18446744069397807105;
  subgroup[3] = 4503599626321920;
  subgroup[4] = 281474976710656;
  subgroup[5] = 18446744069414588417;
  subgroup[6] = 18446742969902956801;
  subgroup[7] = 18446744000695107585;
  subgroup[8] = 18446744069414584320;
  subgroup[9] = 1152921504606846976;
  subgroup[10] = 18446744069431361537;
  subgroup[11] = 18442240469788262401;
  subgroup[12] = 18446462594437873665;
  subgroup[13] = 18446744069414580225;
  subgroup[14] = 1099511627520;
  subgroup[15] = 68719476736;
  return subgroup[i];
}
