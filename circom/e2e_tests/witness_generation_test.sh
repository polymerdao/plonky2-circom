CIRCUIT_NAME=plonky2
CIRCUIT_PATH=../circuits/plonky2.circom
INPUT_PATH=../test/data/proof.json
POT_PATH=~/Downloads/powersOfTau28_hez_final_25.ptau
RAPIDSNARK_PATH=../../../rapidsnark/build/prover
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
