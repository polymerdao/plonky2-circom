const path = require("path");

const wasm_tester = require("circom_tester").wasm;

describe("GlExp Circuit Test", function () {
    let circuit;

    this.timeout(10000000);

    before(async () => {
        circuit = await wasm_tester(path.join(__dirname, "circuits", "goldilocks.test.circom"), {
            prime: "goldilocks"
        });
    });

    it("Should calculate exp", async () => {

        const input = {
            in: 1
        };

        const w = await circuit.calculateWitness(input, true);

        await circuit.assertOut(w, {out: 1});
    });
});
