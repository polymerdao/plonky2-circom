# Plonky2 verifier in Circom

Updates
-----

- **10/22/2022** Switched to use native Goldilocks field. Finished get_challenges.
- **10/20/2022** Finished circuits of verify_fri_proof with 1.2M non-linear constraints. 


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

```shell
****COMPILING CIRCUIT****
template instances: 128
non-linear constraints: 8318231
linear constraints: 1
public inputs: 4
public outputs: 1
private inputs: 7340
private outputs: 0
wires: 8268041
labels: 18117374
Written successfully: ./e2e.r1cs
Written successfully: ./e2e.sym
Written successfully: ./e2e_js/e2e.wasm
Everything went okay, circom safe
DONE (244s)
****WITNESS GENERATION****
DONE (9s)
****GENERATING ZKEY 0****
[INFO]  snarkJS: Reading r1cs
[INFO]  snarkJS: Reading tauG1
[INFO]  snarkJS: Reading tauG2
[INFO]  snarkJS: Reading alphatauG1
[INFO]  snarkJS: Reading betatauG1
[INFO]  snarkJS: Circuit hash: 
                1032eb14 24d61338 e396f327 8e0961f7
                1ec26164 98642ad1 d2d5838f 85279346
                edf2b02c 96c2ad9e c1bfdd04 ee5eb910
                1b428374 00ae91b2 1a101b98 235ffc92
DONE (2510s)
****GENERATING PROOF****
DONE (17s)
****EXPORTING VKEY****
DONE (0s)
****VERIFYING PROOF FOR SAMPLE INPUT****
[ERROR] snarkJS: Invalid proof
DONE (1s)

```