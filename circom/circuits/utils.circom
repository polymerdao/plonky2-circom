pragma circom 2.0.6;
include "../node_modules/circomlib/circuits/comparators.circom";

// A working but slow implementation
template RandomAccess(N) {
  signal input a[N];
  signal input idx;
  signal output out;

  component cIsEqual[N];
  signal sum[N + 1];
  sum[0] <== 0;
  for (var i = 0; i < N; i++) {
    cIsEqual[i] = IsEqual();
    cIsEqual[i].in[0] <== idx;
    cIsEqual[i].in[1] <== i;
    sum[i + 1] <== cIsEqual[i].out * a[i] + sum[i];
  }

  out <== sum[N];
}

template RandomAccess2(N, M) {
  signal input a[N][M];
  signal input idx;
  signal output out[M];

  component ra[M];
  for (var i = 0; i < M; i++) {
    ra[i] = RandomAccess(N);
    ra[i].idx <== idx;
    for (var j = 0; j < N; j++) {
      ra[i].a[j] <== a[j][i];
    }
    out[i] <== ra[i].out;
  }
}
