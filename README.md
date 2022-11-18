# Plonky2 verifier in Circom

Updates
-----

- **11/17/2022** Added support for standard recursive config in Plonky2. Test results are in the last section.
- **11/13/2022** Finished verification circuits for BN128 Poseidon based recursive Plonky2 proof. Test results are in the last section.
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
This project reached the milestone to verify any recursive plonky2 proof with public inputs using the following
settings:

- GoldilocksField
- QuadraticExtension
- Poseidon hasher

Supported custom gates:

+ [x] NoopGate
+ [x] ConstantGate
+ [x] PublicInputGate
+ [x] BaseSumGate
+ [x] LowDegreeInterpolationGate
+ [x] ReducingExtensionGate
+ [x] ReducingGate
+ [x] ArithmeticGate
+ [x] ArithmeticExtensionGate
+ [x] MulExtensionGate
+ [x] ExponentiationGate
+ [x] RandomAccessGate
+ [x] PoseidonGate

Optional:

+ [ ] Zero knowledge support

Results using standard recursive config
-----

Test machine: 256GB RAM, 32 core GCP VM

```shell
****GENERATING RECURSIVE PLONKY2 PROOF****
   Compiling plonky2 v0.1.0 (/home/sai/Project/polymer/plonky2/plonky2)
   Compiling plonky2_circom_verifier v0.1.0 (/home/sai/Project/polymer/plonky2-circom)
    Finished release [optimized] target(s) in 11.74s
     Running unittests src/lib.rs (target/release/deps/plonky2_circom_verifier-447e0c9d88a5d800)
running 1 test
test verifier::tests::test_recursive_verifier ... ok
successes:
---- verifier::tests::test_recursive_verifier stdout ----
######################### recursive verify #########################
######################### recursive verify #########################
Generating Circom files ...
proof size: 127728
successes:
    verifier::tests::test_recursive_verifier
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 3 filtered out; finished in 8.41s
DONE (0s)
****COMPILING CIRCUIT****
template instances: 1000
non-linear constraints: 29442894
linear constraints: 0
public inputs: 68
public outputs: 0
private inputs: 15877
private outputs: 0
wires: 29217264
labels: 63028962
Written successfully: ./plonky2.r1cs
Written successfully: ./plonky2.sym
Written successfully: ./plonky2_cpp/plonky2.cpp and ./plonky2_cpp/plonky2.dat
Written successfully: ./plonky2_cpp/main.cpp, circom.hpp, calcwit.hpp, calcwit.cpp, fr.hpp, fr.cpp, fr.asm and Makefile
Everything went okay, circom safe
DONE (1178s)
****COMPILING WITNESS GENERATOR****
g++ -c main.cpp -std=c++11 -O3 -I.
g++ -c calcwit.cpp -std=c++11 -O3 -I.
g++ -c fr.cpp -std=c++11 -O3 -I.
nasm -felf64 fr.asm -o fr_asm.o
g++ -c plonky2.cpp -std=c++11 -O3 -I.
g++ -o plonky2 *.o -lgmp 
DONE (144s)
****GENERATING ZKEY 0****
DONE (12690s)
****CONTRIBUTE TO PHASE 2 CEREMONY****
DONE (1099s)
****VERIFYING FINAL ZKEY (SKIP FOR TESTING)****
DONE (0s)
****EXPORTING VKEY****
DONE (0s)
****WITNESS GENERATION****
DONE (7s)
****GENERATING PROOF****
DONE (38s)
****VERIFYING PROOF****
[INFO]  snarkJS: OK!
DONE (1s)
****SOLIDITY VERIFIER TEST****
  Groth16
    ✔ Should return true when proof is correct (2059ms)
  1 passing (2s)

****GENERATING A NEW RECURSIVE PLONKY2 PROOF****
****WITNESS GENERATION****
DONE (10s)
****GENERATING PROOF****
DONE (37s)
****VERIFYING PROOF****
[INFO]  snarkJS: OK!
DONE (1s)
****SOLIDITY VERIFIER TEST****
  Groth16
    ✔ Should return true when proof is correct (2079ms)
  1 passing (2s)
```

Results using high rate recursive config
-----


Test machine: 32GB RAM, 24 core PC.

Recursive proof (proof size: 58916)

```shell
****GENERATING RECURSIVE PLONKY2 PROOF****
   Compiling plonky2_circom_verifier v0.1.0 (/home/sai/Project/polymer/plonky2-circom)
    Finished release [optimized] target(s) in 4.63s
     Running unittests src/lib.rs (target/release/deps/plonky2_circom_verifier-4dfa06387e9d7dae)
running 1 test
test verifier::tests::test_recursive_verifier has been running for over 60 seconds
test verifier::tests::test_recursive_verifier ... ok
successes:
---- verifier::tests::test_recursive_verifier stdout ----
Generating Circom files ...
proof size: 58916
successes:
    verifier::tests::test_recursive_verifier
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 3 filtered out; finished in 171.39s
DONE (0s)
****COMPILING CIRCUIT****
template instances: 958
non-linear constraints: 12892923
linear constraints: 0
public inputs: 4
public outputs: 0
private inputs: 7353
private outputs: 0
wires: 12799230
labels: 27782784
Written successfully: ./plonky2.r1cs
Written successfully: ./plonky2.sym
Written successfully: ./plonky2_cpp/plonky2.cpp and ./plonky2_cpp/plonky2.dat
Written successfully: ./plonky2_cpp/main.cpp, circom.hpp, calcwit.hpp, calcwit.cpp, fr.hpp, fr.cpp, fr.asm and Makefile
Everything went okay, circom safe
DONE (483s)
****COMPILING WITNESS GENERATOR****
g++ -c main.cpp -std=c++11 -O3 -I.
g++ -c calcwit.cpp -std=c++11 -O3 -I.
g++ -c fr.cpp -std=c++11 -O3 -I.
nasm -felf64 fr.asm -o fr_asm.o
g++ -c plonky2.cpp -std=c++11 -O3 -I.
g++ -o plonky2 *.o -lgmp 
DONE (89s)
****GENERATING ZKEY 0****
DONE (13174s)
****CONTRIBUTE TO PHASE 2 CEREMONY****
DONE (484s)
****VERIFYING FINAL ZKEY (SKIP FOR TESTING)****
DONE (0s)
****EXPORTING VKEY****
DONE (0s)
****WITNESS GENERATION****
DONE (3s)
****GENERATING PROOF****
DONE (25s)
****VERIFYING PROOF****
[INFO]  snarkJS: OK!
DONE (1s)
****SOLIDITY VERIFIER TEST****
Compiled 1 Solidity file successfully
  Groth16
    ✔ Should return true when proof is correct (1408ms)
  1 passing (1s)
```
Verify a new Plonky2 proof using the same circuits
```shell
****GENERATING RECURSIVE PLONKY2 PROOF****
   Compiling plonky2_circom_verifier v0.1.0 (/home/sai/Project/polymer/plonky2-circom)
    Finished release [optimized] target(s) in 4.52s
     Running unittests src/lib.rs (target/release/deps/plonky2_circom_verifier-4dfa06387e9d7dae)
running 1 test
test verifier::tests::test_recursive_verifier has been running for over 60 seconds
test verifier::tests::test_recursive_verifier ... ok
successes:
---- verifier::tests::test_recursive_verifier stdout ----
Generating Circom files ...
proof size: 58916
successes:
    verifier::tests::test_recursive_verifier
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 3 filtered out; finished in 177.80s
DONE (0s)
****WITNESS GENERATION****
DONE (3s)
****GENERATING PROOF****
DONE (26s)
****VERIFYING PROOF****
[INFO]  snarkJS: OK!
DONE (0s)
****SOLIDITY VERIFIER TEST****
  Groth16
    ✔ Should return true when proof is correct (1388ms)
  1 passing (1s)
```

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