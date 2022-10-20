# Plonky2 verifier in Circom

Updates
-----

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
e2e_tests % ./run.sh
template instances: 49
non-linear constraints: 1221101
linear constraints: 1
public inputs: 0
public outputs: 1
private inputs: 7344
private outputs: 0
wires: 3018116
labels: 8611204
Written successfully: ./e2e.r1cs
Written successfully: ./e2e.sym
Written successfully: ./e2e_js/e2e.wasm
Everything went okay, circom safe
[INFO]  snarkJS: Reading r1cs
[INFO]  snarkJS: Reading tauG1
[INFO]  snarkJS: Reading tauG2
[INFO]  snarkJS: Reading alphatauG1
[INFO]  snarkJS: Reading betatauG1
[INFO]  snarkJS: Circuit hash: 
                5dbad9bc 1a2d88c5 4710ab7c 13d5c643
                90aaf8a7 ee138fe6 6397751e 4e001f9b
                a568937f 8e4973ae 8b9ed1f0 41014265
                19e9240e 9648e9ea 90986526 64b6c4de
[INFO]  snarkJS: OK!
```