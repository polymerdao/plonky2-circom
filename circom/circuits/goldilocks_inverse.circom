pragma circom 2.0.9;
include "./constants.circom";

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

  out <-- gl_inverse(x);
  signal tmp1 <== out * x - 1;
  signal tmp2 <== tmp1 / Order();
  tmp1 === tmp2 * Order();
}
