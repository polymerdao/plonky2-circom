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
TODO
```