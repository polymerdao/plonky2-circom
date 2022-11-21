const path = require("path");
const proof = require("./data/pwoi_proof.json");

const wasm_tester = require("circom_tester").wasm;

describe("Plonk eval_l1 Circuit Test", function () {
    let circuit;

    this.timeout(10000000);

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "plonk.test.circom"), {});
    });

    it("Should pass", async () => {
        const input = {
            in: 1
        };

        const w = await circuit.calculateWitness(input, true);

        await circuit.assertOut(w, {out: 1});
    });
});

// describe("Plonk Check Zeta Circuit Test", function () {
//     let circuit;
//
//     this.timeout(10000000);
//
//     before(async () => {
//         circuit = await wasm_tester(path.join(__dirname, "circuits", "checkzeta.test.circom"), {});
//     });
//
//     it("Should pass", async () => {
//         const w = await circuit.calculateWitness(proof, true);
//
//         await circuit.assertOut(w, {});
//     });
// });
