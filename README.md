# Plonky2 verifier in Circom

Updates
-----

- **11/03/2022** Switched to use BN128 field:
  - Added range checks for Goldilocks arithmetic operations.
  - Added generation of BN128 Poseidon based Plonky2 proof (30x slower than Goldilocks based Poseidon).
  - Finished end-to-end tests for verify_fri_proof + get_challenges.
  - Total non-linear constraints of the above Groth16 circuits is 8.4M. More results in the last section.
- **10/22/2022** Finished get_challenges.
- **10/20/2022** Finished circuits of verify_fri_proof with 1.2M non-linear constraints (native Goldilocks field). 


Milestones
-----
The first milestone is to verify a dummy plonky2 proof with public inputs using the following
settings:

- High rate config
- GoldilocksField
- QuadraticExtension
- Poseidon hasher

The next milestone is to verify any recursive proof with the above settings.

Things to do for this milestone:

Implement all required gate constraints evaluation:

+ [ ] NoopGate
+ [ ] ConstantGate
+ [ ] PublicInputGate
+ [ ] BaseSumGate
+ [ ] LowDegreeInterpolationGate
+ [ ] ReducingExtensionGate
+ [ ] ReducingGate
+ [ ] ArithmeticGate
+ [ ] U32ArithmeticGate
+ [ ] ArithmeticExtensionGate
+ [ ] MulExtensionGate
+ [ ] ExponentiationGate
+ [ ] RandomAccessGate
+ [ ] PoseidonGate

Optional:

+ [ ] Zero knowledge support

Results
-----

Test machine: 32GB RAM, 24 core PC.

```shell

****COMPILING CIRCUIT****
template instances: 136
non-linear constraints: 8416603
linear constraints: 0
public inputs: 4
public outputs: 0
private inputs: 7321
private outputs: 0
wires: 8366434
labels: 18302856
Written successfully: ./plonky2.r1cs
Written successfully: ./plonky2.sym
Written successfully: ./plonky2_cpp/plonky2.cpp and ./plonky2_cpp/plonky2.dat
Written successfully: ./plonky2_cpp/main.cpp, circom.hpp, calcwit.hpp, calcwit.cpp, fr.hpp, fr.cpp, fr.asm and Makefile
Everything went okay, circom safe
DONE (252s)
****COMPILING WITNESS GENERATOR****
g++ -c main.cpp -std=c++11 -O3 -I.
g++ -c calcwit.cpp -std=c++11 -O3 -I.
g++ -c fr.cpp -std=c++11 -O3 -I.
nasm -felf64 fr.asm -o fr_asm.o
g++ -c plonky2.cpp -std=c++11 -O3 -I.
g++ -o plonky2 *.o -lgmp 
DONE (23s)
****GENERATING ZKEY 0****
DONE (3011s)
****CONTRIBUTE TO PHASE 2 CEREMONY****
DONE (421s)
****VERIFYING FINAL ZKEY (SKIP FOR TESTING)****
DONE (0s)
****EXPORTING VKEY****
DONE (0s)
****WITNESS GENERATION****
DONE (2s)
****GENERATING PROOF****
DONE (23s)
****VERIFYING PROOF****
[INFO]  snarkJS: OK!
DONE (0s)
****SOLIDITY VERIFIER TEST****
  Groth16
    ✔ Should return true when proof is correct (1310ms)
  1 passing (1s)

```