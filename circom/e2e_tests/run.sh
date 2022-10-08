CIRCUIT_NAME=e2e
POT_PATH=./powersOfTau28_hez_final_12.ptau
circom ./${CIRCUIT_NAME}.circom --r1cs --wasm --sym
snarkjs groth16 setup $CIRCUIT_NAME.r1cs ${POT_PATH} circuit_0000.zkey
node ./${CIRCUIT_NAME}_js/generate_witness.js ./${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm ./input.json ./witness.wtns
snarkjs groth16 prove circuit_0000.zkey ./witness.wtns proof.json public.json
snarkjs zkey export solidityverifier circuit_0000.zkey verifier.sol
snarkjs zkey export verificationkey circuit_0000.zkey verification_key.json
snarkjs groth16 verify verification_key.json public.json proof.json
