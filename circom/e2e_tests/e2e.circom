pragma circom 2.0.9;
include "../circuits/poseidon.circom";

template PoseidonTest() {
  signal input in;
  signal output out;

  // Dummy input/output
  in === 1;
  out <== 1;

  component p = Poseidon(4);
  p.in[0] <== 168952236939078983;
  p.in[1] <== 18444491095334285830;
  p.in[2] <== 17812083740232784622;
  p.in[3] <== 1301667294099464849;

  p.in[4] <== 8197835875512527937;
  p.in[5] <== 7109417654116018994;
  p.in[6] <== 18237163116575285904;
  p.in[7] <== 17017896878738047012;

  p.capacity[0] <== 0;
  p.capacity[1] <== 0;
  p.capacity[2] <== 0;
  p.capacity[3] <== 0;

  p.out[0] === 7211848465497282123;
  p.out[1] === 8334407123774112207;
  p.out[2] === 4858661444170722461;
  p.out[3] === 8419634888969461752;
}

component main {public [in]} = PoseidonTest();
