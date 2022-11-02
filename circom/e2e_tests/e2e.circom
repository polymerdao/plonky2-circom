pragma circom 2.0.9;
include "../circuits/fri.circom";

component main {public [wires_cap]} = VerifyFriProof();
