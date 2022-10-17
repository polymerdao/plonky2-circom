pragma circom 2.0.9;
include "./constants.circom";

// Verifies x < 1 << N
template LessNBits(N) {
  signal input x;
  var e2 = 1;
  signal tmp1[64];
  signal tmp2[65];
  tmp2[0] <== 0;
  for (var i = 0; i < 64; i++) {
    tmp1[i] <-- (x >> i) & 1;
    tmp1[i] * (tmp1[i] - 1) === 0;
    tmp2[i + 1] <== tmp1[i] * e2 + tmp2[i];
    e2 = e2 + e2;
  }
  x === tmp2[64];
}

// Gl: Goldilocks
template GlReduce() {
  signal input x;
  signal output out;

  var r = x % Order();
  var d = (x - r) / Order();
  out <-- r;
  signal tmp0 <-- d;
  tmp0 * Order() + out === x;

  // TODO: The circuits should be safe without the following verification
  // verify 'out' < 2^64
  // component c = LessNBits(64);
  // c.x <== out;
}

template GlAdd() {
  signal input a;
  signal input b;
  signal output out;

  component cr = GlReduce();
  cr.x <== a + b;
  out <== cr.out;
}

template GlSub() {
  signal input a;
  signal input b;
  signal output out;

  component cr = GlReduce();
  cr.x <== a + Order() - b;
  out <== cr.out;
}

template GlMul() {
  signal input a;
  signal input b;
  signal output out;

  component cr = GlReduce();
  cr.x <== a * b;
  out <== cr.out;
}

function gl_inverse(x) {
  var m = Order() - 2;
  var e2 = x;
  var res = 1;
  for (var i = 0; i < 64; i++) {
    if ((m >> i) & 1 == 1) {
      res *= e2;
      res %= Order();
    }
    e2 *= e2;
    e2 %= Order();
  }
  return res;
}

template GlInv() {
  signal input x;
  signal output out;

  component cr = GlReduce();
  cr.x <-- gl_inverse(x);
  out <== cr.out;
  signal tmp1 <== out * x - 1;
  signal tmp2 <== tmp1 / Order();
  tmp1 === tmp2 * Order();
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
  signal mul[65];
  component rshift1[64];
  component cmul[64][2];
  e2[0] <== x;
  mul[0] <== 1;
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

// out = x >> n
// where n < N
template RShift(N) {
  signal input x;
  signal output out;
  assert(N < 255);

  out <-- x >> N;
  signal y <-- out << N;
  signal r <== x - y;
  out * 2 ** N === y;

  component c = LessNBits(N);
  c.x <== r;
}
