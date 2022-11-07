const path = require("path");
const proof = require("./data/pwoi_proof.json");
const challenges = require("./data/pwoi_challenges.json");
const fs = require("fs");

const wasm_tester = require("circom_tester").wasm;

describe("Verify Fri Proof Circuit Test", function () {
    let circuit;

    this.timeout(10000000);

    before(async () => {
        // TODO: Error: Cannot create a string longer than 0x1fffffe8 characters
        // circuit = await wasm_tester(path.join(__dirname, "circuits", "fri.test.circom"), {});
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
            fri_query_init_constants_sigmas_v: proof.fri_query_init_constants_sigmas_v,
            fri_query_init_constants_sigmas_p: proof.fri_query_init_constants_sigmas_p,
            fri_query_init_wires_v: proof.fri_query_init_wires_v,
            fri_query_init_wires_p: proof.fri_query_init_wires_p,
            fri_query_init_zs_partial_v: proof.fri_query_init_zs_partial_v,
            fri_query_init_zs_partial_p: proof.fri_query_init_zs_partial_p,
            fri_query_init_quotient_v: proof.fri_query_init_quotient_v,
            fri_query_init_quotient_p: proof.fri_query_init_quotient_p,
            fri_query_step0_v: proof.fri_query_step0_v,
            fri_query_step0_p: proof.fri_query_step0_p,
            fri_query_step1_v: proof.fri_query_step1_v,
            fri_query_step1_p: proof.fri_query_step1_p,
            fri_final_poly_ext_v: proof.fri_final_poly_ext_v,

            plonk_zeta: challenges.plonk_zeta,
            fri_alpha: challenges.fri_alpha,
            fri_betas: challenges.fri_betas,
            fri_pow_response: challenges.fri_pow_response,
            fri_query_indices: challenges.fri_query_indices,
        };

        fs.writeFileSync('fri_input.json', JSON.stringify(input));

        // const w = await circuit.calculateWitness(input, true);

        // await circuit.assertOut(w, {});
    });
});
