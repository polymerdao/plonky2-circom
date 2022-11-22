CIRCUIT_NAME=plonky2
CIRCUIT_PATH=../circuits/plonky2.circom
INPUT_PATH=../test/data/proof.json
POT_PATH=~/Downloads/powersOfTau28_hez_final_25.ptau
RAPIDSNARK_PATH=../../../../rapidsnark/build/prover
# node version > 18
NODE_PATH=node
SNARKJS_PATH=../../../../snarkjs/cli.js
NODE_PARAMS="--trace-gc --trace-gc-ignore-scavenger --max-old-space-size=2048000 --initial-old-space-size=2048000 --no-global-gc-scheduling --no-incremental-marking --max-semi-space-size=1024 --initial-heap-size=2048000 --expose-gc"

echo "****COMPILING CIRCUIT****"
start=$(date +%s)
circom ${CIRCUIT_PATH} --r1cs --sym --c
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****COMPILING WITNESS GENERATOR****"
start=$(date +%s)
cd ${CIRCUIT_NAME}_cpp && make -j && cd ..
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****WITNESS GENERATION****"
start=$(date +%s)
./${CIRCUIT_NAME}_cpp/${CIRCUIT_NAME} ${INPUT_PATH} ./witness.wtns
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****GENERATING ZKEY 0****"
# If failed: https://hackmd.io/@yisun/BkT0RS87q
start=$(date +%s)
#${NODE_PATH} ${NODE_PARAMS} ${SNARKJS_PATH} groth16 setup $CIRCUIT_NAME.r1cs ${POT_PATH} "$CIRCUIT_NAME"_0.zkey
${NODE_PATH} ${NODE_PARAMS} ${SNARKJS_PATH} zkey new $CIRCUIT_NAME.r1cs ${POT_PATH} "$CIRCUIT_NAME"_0.zkey -v > zkey0.out
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****CONTRIBUTE TO PHASE 2 CEREMONY****"
start=$(date +%s)
${NODE_PATH} ${NODE_PARAMS} ${SNARKJS_PATH} zkey contribute -verbose "$CIRCUIT_NAME"_0.zkey "$CIRCUIT_NAME".zkey -n="First phase2 contribution" -e="some random text" > contribute.out
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****VERIFYING FINAL ZKEY (SKIP FOR TESTING)****"
start=$(date +%s)
#${NODE_PATH} ${NODE_PARAMS} ${SNARKJS_PATH} zkey verify -verbose "$CIRCUIT_NAME".r1cs ${POT_PATH} "$CIRCUIT_NAME".zkey > verify.out
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****EXPORTING VKEY****"
start=$(date +%s)
${NODE_PATH} ${SNARKJS_PATH} zkey export verificationkey "$CIRCUIT_NAME".zkey verification_key.json -v
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****GENERATING PROOF****"
start=$(date +%s)
${RAPIDSNARK_PATH} "$CIRCUIT_NAME".zkey ./witness.wtns proof.json public.json
#${NODE_PATH} ${SNARKJS_PATH} groth16 prove "$CIRCUIT_NAME".zkey ./witness.wtns proof.json public.json
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****VERIFYING PROOF****"
start=$(date +%s)
${NODE_PATH} ${SNARKJS_PATH} groth16 verify verification_key.json public.json proof.json -v
end=$(date +%s)
echo "DONE ($((end - start))s)"

echo "****SOLIDITY VERIFIER TEST****"
${NODE_PATH} ${SNARKJS_PATH} zkey export solidityverifier "$CIRCUIT_NAME".zkey verifier.sol
${NODE_PATH} ${SNARKJS_PATH} generatecall public.json > ./hardhat/test/public.txt
cp verifier.sol ./hardhat/contracts
cd hardhat && npx hardhat test && cd ..
