CIRCUIT_NAME=plonky2
CIRCUIT_PATH=../circuits/plonky2.circom
INPUT_PATH=../test/data/proof.json
POT_PATH=~/Downloads/powersOfTau28_hez_final_24.ptau
RAPIDSNARK_PATH=../../../rapidsnark/build/prover
NODE_PATH=~/node/out/Release/node
SNARKJS_PATH=../../../../snarkjs/cli.js
NODE_PARAMS="--trace-gc --trace-gc-ignore-scavenger --max-old-space-size=2048000 --initial-old-space-size=2048000 --no-global-gc-scheduling --no-incremental-marking --max-semi-space-size=1024 --initial-heap-size=2048000 --expose-gc"

echo "****COMPILING CIRCUIT****"
start=$(date +%s)
circom ${CIRCUIT_PATH} --r1cs --sym --c
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****COMPILING WITNESS GENERATOR****"
start=$(date +%s)
cd ${CIRCUIT_NAME}_cpp
make -j
cd ..
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****GENERATING ZKEY 0****"
# If failed: https://hackmd.io/@yisun/BkT0RS87q
start=$(date +%s)
${NODE_PATH} ${NODE_PARAMS} ${SNARKJS_PATH} groth16 setup $CIRCUIT_NAME.r1cs ${POT_PATH} circuit_0000.zkey
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****EXPORTING VKEY****"
start=$(date +%s)
${NODE_PATH} ${SNARKJS_PATH} zkey export verificationkey circuit_0000.zkey verification_key.json
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****WITNESS GENERATION****"
start=$(date +%s)
#${NODE_PATH} ./${CIRCUIT_NAME}_js/generate_witness.js ./${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm ${INPUT_PATH} ./witness.wtns
./${CIRCUIT_NAME}_cpp/${CIRCUIT_NAME} ${INPUT_PATH} ./witness.wtns
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****GENERATING PROOF****"
start=$(date +%s)
${RAPIDSNARK_PATH} circuit_0000.zkey ./witness.wtns proof.json public.json
#${NODE_PATH} ${SNARKJS_PATH} groth16 prove circuit_0000.zkey ./witness.wtns proof.json public.json
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****VERIFYING PROOF****"
# If failed: double check the i/o of the circuits
start=$(date +%s)
${NODE_PATH} ${SNARKJS_PATH} groth16 verify verification_key.json public.json proof.json
end=$(date +%s)
echo "DONE ($((end - start))s)"

${NODE_PATH} ${SNARKJS_PATH} zkey export solidityverifier circuit_0000.zkey verifier.sol
${NODE_PATH} ${SNARKJS_PATH} generatecall public.json
cp verifier.sol ./hardhat/contracts
