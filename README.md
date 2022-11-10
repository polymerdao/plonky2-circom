# Plonky2 verifier in Circom

Updates
-----

- **11/10/2022** Implemented Circom circuits to support verification of a Plonky2 proof with public inputs and custom
  gates (constant, public inputs and Poseidon). Test results are in the last section.
- **11/03/2022** Switched to use BN128 field:
    - Added range checks for Goldilocks arithmetic operations.
    - Added generation of BN128 Poseidon based Plonky2 proof (30x slower than Goldilocks based Poseidon).
    - Finished end-to-end tests for verify_fri_proof + get_challenges.
    - Total non-linear constraints of the above Groth16 circuits is 8.4M. More results in the last section.
- **10/22/2022** Finished get_challenges.
- **10/20/2022** Finished circuits of verify_fri_proof with 1.2M non-linear constraints (native Goldilocks field).

Milestones
-----
This project reached its first milestone that is to verify a plonky2 proof with public inputs using the following
settings:

- High rate config
- GoldilocksField
- QuadraticExtension
- Poseidon hasher

The next milestone is to verify any recursive proof with the above settings.

Things to do for this milestone:

Implement all required gate constraints evaluation:

+ [x] NoopGate
+ [x] ConstantGate
+ [x] PublicInputGate
+ [ ] BaseSumGate
+ [ ] LowDegreeInterpolationGate
+ [ ] ReducingExtensionGate
+ [ ] ReducingGate
+ [ ] ArithmeticGate
+ [ ] ArithmeticExtensionGate
+ [ ] MulExtensionGate
+ [ ] ExponentiationGate
+ [ ] RandomAccessGate
+ [x] PoseidonGate

Optional:

+ [ ] Zero knowledge support

Results
-----

Test machine: 32GB RAM, 24 core PC.

Proof without any custom gates (Proof size: 58660)

```shell
****COMPILING CIRCUIT****
template instances: 142
non-linear constraints: 8771891
linear constraints: 0
public inputs: 4
public outputs: 0
private inputs: 7321
private outputs: 0
wires: 8718375
labels: 19049523
Written successfully: ./plonky2.r1cs
Written successfully: ./plonky2.sym
Written successfully: ./plonky2_cpp/plonky2.cpp and ./plonky2_cpp/plonky2.dat
Written successfully: ./plonky2_cpp/main.cpp, circom.hpp, calcwit.hpp, calcwit.cpp, fr.hpp, fr.cpp, fr.asm and Makefile
Everything went okay, circom safe
DONE (261s)
****COMPILING WITNESS GENERATOR****
g++ -c main.cpp -std=c++11 -O3 -I.
g++ -c calcwit.cpp -std=c++11 -O3 -I.
g++ -c fr.cpp -std=c++11 -O3 -I.
nasm -felf64 fr.asm -o fr_asm.o
g++ -c plonky2.cpp -std=c++11 -O3 -I.
g++ -o plonky2 *.o -lgmp 
DONE (24s)
****GENERATING ZKEY 0****
DONE (3091s)
****CONTRIBUTE TO PHASE 2 CEREMONY****
DONE (400s)
****VERIFYING FINAL ZKEY (SKIP FOR TESTING)****
DONE (0s)
****EXPORTING VKEY****
DONE (0s)
****WITNESS GENERATION****
DONE (2s)
****GENERATING PROOF****
DONE (22s)
****VERIFYING PROOF****
[INFO]  snarkJS: OK!
DONE (1s)
****SOLIDITY VERIFIER TEST****
Compiled 1 Solidity file successfully
  Groth16
    ✔ Should return true when proof is correct (1410ms)
  1 passing (1s)

```

Proof with public inputs and custom gates (constant, public inputs and Poseidon) (Proof size: 62244)

```shell
****COMPILING CIRCUIT****
template instances: 842
non-linear constraints: 12067519
linear constraints: 0
public inputs: 4
public outputs: 0
private inputs: 7769
private outputs: 0
wires: 11982955
labels: 26019560
Written successfully: ./plonky2.r1cs
Written successfully: ./plonky2.sym
Written successfully: ./plonky2_cpp/plonky2.cpp and ./plonky2_cpp/plonky2.dat
Written successfully: ./plonky2_cpp/main.cpp, circom.hpp, calcwit.hpp, calcwit.cpp, fr.hpp, fr.cpp, fr.asm and Makefile
Everything went okay, circom safe
DONE (359s)
****COMPILING WITNESS GENERATOR****
g++ -c main.cpp -std=c++11 -O3 -I.
g++ -c calcwit.cpp -std=c++11 -O3 -I.
g++ -c fr.cpp -std=c++11 -O3 -I.
nasm -felf64 fr.asm -o fr_asm.o
g++ -c plonky2.cpp -std=c++11 -O3 -I.
g++ -o plonky2 *.o -lgmp 
DONE (86s)
****GENERATING ZKEY 0****
DONE (8524s)
****CONTRIBUTE TO PHASE 2 CEREMONY****
DONE (457s)
****VERIFYING FINAL ZKEY (SKIP FOR TESTING)****
DONE (0s)
****EXPORTING VKEY****
DONE (1s)
****WITNESS GENERATION****
DONE (2s)
****GENERATING PROOF****
DONE (25s)
****VERIFYING PROOF****
[INFO]  snarkJS: OK!
DONE (1s)
****SOLIDITY VERIFIER TEST****
Compiled 1 Solidity file successfully
  Groth16
    ✔ Should return true when proof is correct (1501ms)
  1 passing (2s)
```