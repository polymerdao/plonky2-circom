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

template GlMul() {
  signal input a;
  signal input b;
  signal output out;

  var r = (a * b) % Order();
  var d = (a * b - r) / Order();

  out <-- r;
  signal tmp1 <== a * b - out;
  signal tmp2 <-- d;
  tmp1 === Order() * tmp2;
}

template GlDiv() {
  signal input a;
  signal input b;
  signal output out;

  component cgi = GlInv();
  cgi.x <== b;
  component cgm = GlMul();
  cgm.a <== a;
  cgm.b <== cgi.out;
  out <== cgm.out;
}


template GlExp() {
  signal input x;
  signal input n;
  signal output out;

  signal e2[65];
  signal temp1[64];
  signal temp2[64];
  signal mul[65];
  component cmul[64][2];
  mul[0] <== 1;
  e2[0] <== x;
  for (var i = 0; i < 64; i++) {
    temp1[i] <-- (n >> i) & 1;
    temp1[i] * (temp1[i] - 1) === 0;
    temp2[i] <== e2[i] * temp1[i] + 1 - temp1[i];

    cmul[i][0] = GlMul();
    cmul[i][1] = GlMul();
    cmul[i][0].a <== mul[i];
    cmul[i][0].b <== temp2[i];
    cmul[i][1].a <== e2[i];
    cmul[i][1].b <== e2[i];

    mul[i + 1] <== cmul[i][0].out;
    e2[i + 1] <== cmul[i][1].out;
  }

  out <== mul[64];
}
