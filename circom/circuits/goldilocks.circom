pragma circom 2.0.9;

template GlExp() {
  signal input x;
  signal input n;
  signal output out;

  signal e2[65];
  signal temp1[64];
  signal temp2[64];
  signal mul[65];
  mul[0] <== 1;
  e2[0] <== x;
  for (var i = 0; i < 64; i++) {
    temp1[i] <-- (n >> i) & 1;
    temp2[i] <== e2[i] * temp1[i] + 1 - temp1[i];
    mul[i + 1] <== mul[i] * temp2[i];
    e2[i + 1] <== e2[i] * e2[i];
  }

  out <== mul[64];
}

template GlExtMul() {
  signal input a[2];
  signal input b[2];
  signal output out[2];

  var W = 7;
  signal tmp1 <== W * a[1] * b[1];
  signal tmp2 <== a[1] * b[0];

  out[0] <== a[0] * b[0] + tmp1;
  out[1] <== a[0] * b[1] + tmp2;
}
