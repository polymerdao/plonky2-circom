const path = require("path");
const proof = require("./data/proof.json");
const public_inputs = require("./data/public_inputs.json");
const fs = require("fs");

const wasm_tester = require("circom_tester").wasm;

describe("Verify Gates Circuit Test", function () {
    let circuit;

    this.timeout(10000000);

    before(async () => {
        // circuit = await wasm_tester(path.join(__dirname, "circuits", "gates.test.circom"), {});
    });

    it("Should pass", async () => {
        const input = {
            constants: proof.openings_constants,
            wires: proof.openings_wires,
            constraints: new Array(123).fill([0,0]),
            public_input_hash: public_inputs.public_input_hash,
        };

        fs.writeFileSync('gates_input.json', JSON.stringify(input));

        // const w = await circuit.calculateWitness(input, true);
        //
        // await circuit.assertOut(w, {});
    });
});
