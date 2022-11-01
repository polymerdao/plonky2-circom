CIRCUIT_NAME=e2e
POT_PATH=~/Downloads/powersOfTau28_hez_final_24.ptau
RAPIDSNARK_PATH=../../../rapidsnark/build/prover

echo "****COMPILING CIRCUIT****"
start=$(date +%s)
#circom ./${CIRCUIT_NAME}.circom --r1cs --wasm --sym
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****WITNESS GENERATION****"
start=$(date +%s)
#node ./${CIRCUIT_NAME}_js/generate_witness.js ./${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm ./input.json ./witness.wtns
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****GENERATING ZKEY 0****"
echo "(make sure you have enough memory + swap)"
start=$(date +%s)
NODE_OPTIONS="--max-old-space-size=56000" npx snarkjs groth16 setup $CIRCUIT_NAME.r1cs ${POT_PATH} circuit_0000.zkey
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****GENERATING PROOF****"
start=`date +%s`
${RAPIDSNARK_PATH} prove circuit_0000.zkey ./witness.wtns proof.json public.json
#snarkjs groth16 prove circuit_0000.zkey ./witness.wtns proof.json public.json
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****EXPORTING VKEY****"
start=`date +%s`
snarkjs zkey export verificationkey circuit_0000.zkey verification_key.json
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****VERIFYING PROOF FOR SAMPLE INPUT****"
start=`date +%s`
snarkjs groth16 verify verification_key.json public.json proof.json
end=$(date +%s)
echo "DONE ($((end - start))s)"

#snarkjs zkey export solidityverifier circuit_0000.zkey verifier.sol