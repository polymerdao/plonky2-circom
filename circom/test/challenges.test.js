const path = require("path");
const proof = require("./data/pwoi_proof.json");
const challenges = require("./data/pwoi_challenges.json");
const fs = require("fs");

const wasm_tester = require("circom_tester").wasm;

describe("Verify Challenges Circuit Test", function () {
    let circuit;

    this.timeout(10000000);

    before(async () => {
        // circuit = await wasm_tester(path.join(__dirname, "circuits", "challenges.test.circom"), {});
    });

    it("Should pass", async () => {
        const input = {
            wires_cap: proof.wires_cap,
            plonk_zs_partial_products_cap: proof.plonk_zs_partial_products_cap,
            quotient_polys_cap: proof.quotient_polys_cap,

            openings_constants: proof.openings_constants,
            openings_plonk_sigmas: proof.openings_plonk_sigmas,
            openings_wires: proof.openings_wires,
            openings_plonk_zs: proof.openings_plonk_zs,
            openings_plonk_zs_next: proof.openings_plonk_zs_next,
            openings_partial_products: proof.openings_partial_products,
            openings_quotient_polys: proof.openings_quotient_polys,

            fri_commit_phase_merkle_caps: proof.fri_commit_phase_merkle_caps,
            fri_final_poly_ext_v: proof.fri_final_poly_ext_v,
            fri_pow_witness: proof.fri_pow_witness,
        };

        fs.writeFileSync('challenges_input.json', JSON.stringify(input));

        // const w = await circuit.calculateWitness(input, true);
        //
        // await circuit.assertOut(w, {
        //     plonk_betas: challenges.plonk_betas,
        //     plonk_gammas: challenges.plonk_gammas,
        //     plonk_alphas: challenges.plonk_alphas,
        //     plonk_zeta: challenges.plonk_zeta,
        //     fri_alpha: challenges.fri_alpha,
        //     fri_betas: challenges.fri_betas,
        //     fri_pow_response: challenges.fri_pow_response[0],
        //     fri_query_indices: challenges.fri_query_indices,
        // });
    });
});
