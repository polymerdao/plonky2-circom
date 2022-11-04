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
["0x24e18437119abd227422e0365a10b9e418175339142831fbec31c12743d132e0", "0x2a274db3624e4347b7c33a9af8338dbbbdadcb394a0aa0d01b73c7c0f6ef9357"],[["0x2ad7af70a223e2e506a3fdc6c9ec18ea1fffa7cb541c85f46d9ba0d600fc6ce9", "0x28f2303de7b35560181a3449c102b1519cd3319f0437f922bebb79c856842818"],["0x104db91fc9a5a2e8d069e99c03e6f134ceca5f8f964e7633857faf1165329b2b", "0x190ac039445ea05ac01bd8df248963fe6659537695595869de441da41076ae92"]],["0x144c1acdd0f4393799257035862cabc2bb81c1ad6cbf583cb691b2552ed8dc54", "0x01a4d11491066fe7dc1248c39b157adda7dd5ada9b6ad61e38913e9e028c6264"],["0x000000000000000000000000000000000000000000000000e49d11b2ccf7d016","0x000000000000000000000000000000000000000000000000be88b5d005d28773","0x00000000000000000000000000000000000000000000000010cb59ae6275ae55","0x0000000000000000000000000000000000000000000000006c146bb84faf6553"]

```