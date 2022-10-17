pragma circom 2.0.9;
include "./constants.circom";
include "./goldilocks_inverse.circom";

// Gl: Goldilocks
template GlAdd() {
  signal input a;
  signal input b;
  signal output out;

  var res = (a + b) % Order();
  var over = a + b >= Order() ? 1 : 0;

  out <-- res;
  signal tmp1 <-- over;
  signal tmp2 <== a + b;
  signal tmp3 <== (1 - tmp1) * tmp2;
  out === tmp1 * (tmp2 - Order()) + tmp3;
}

template GlSub() {
  signal input a;
  signal input b;
  signal output out;

  component cadd = GlAdd();
  cadd.a <== a;
  cadd.b <== Order() - b;
  out <== cadd.out;
}

template GlReduce() {
  signal input x;
  signal output out;

  var r = x % Order();
  var d = (x - r) / Order();
  out <-- r;
  signal tmp <-- d;
  tmp * Order() + out === x;
}

template GlMul() {
  signal input a;
  signal input b;
  signal output out;

  component cr = GlReduce();
  cr.x <== a * b;
  out <== cr.out;
}

template GlDiv() {
  signal input a;
  signal input b;
  signal output out;

  component inv_b = GlInv();
  inv_b.x <== b;
  component a_mul_inv_b = GlMul();
  a_mul_inv_b.a <== a;
  a_mul_inv_b.b <== inv_b.out;
  out <== a_mul_inv_b.out;
}

// bit = a & 1
// out = a >> 1
template RShift1() {
  signal input a;
  signal output out;
  signal output bit;

  var o = a >> 1;
  out <-- o;
  bit <== a - out * 2;
  bit * (1 - bit) === 0;
}

template GlExp() {
  signal input x;
  signal input n;
  signal output out;

  signal e2[65];
  component rshift1[64];
  signal mul[65];
  component cmul[64][2];
  mul[0] <== 1;
  e2[0] <== x;
  rshift1[0] = RShift1();
  rshift1[0].a <== n;
  for (var i = 0; i < 64; i++) {
    if (i > 0) {
      rshift1[i] = RShift1();
      rshift1[i].a <== rshift1[i - 1].out;
    }

    cmul[i][0] = GlMul();
    cmul[i][1] = GlMul();
    cmul[i][0].a <== mul[i];
    cmul[i][0].b <== e2[i] * rshift1[i].bit + 1 - rshift1[i].bit;
    cmul[i][1].a <== e2[i];
    cmul[i][1].b <== e2[i];

    mul[i + 1] <== cmul[i][0].out;
    e2[i + 1] <== cmul[i][1].out;
  }

  out <== mul[64];
}
