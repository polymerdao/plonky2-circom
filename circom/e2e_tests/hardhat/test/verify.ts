import {ethers} from "hardhat";
import "@nomiclabs/hardhat-etherscan";
import {expect} from "chai";

describe("Groth16", function () {
    it("Should return true when proof is correct", async function () {
        const verifierFactory = await ethers.getContractFactory("Verifier");
        const verifier = await verifierFactory.deploy();
        await verifier.deployed();

        const fs = require("fs");
        let text = fs.readFileSync("./test/public.txt").toString();
        text = text.replace(/\s+/g, '');
        text = text.replace(/\[+/g, '');
        text = text.replace(/]+/g, '');
        text = text.replace(/"+/g, '');
        const p = text.split(",");
        let public_inputs = [];
        for (let i = 0; i < p.length - 8; i++) {
            public_inputs.push(p[8 + i]);
        }
        expect(await verifier.verifyProof(
            [p[0], p[1]],
            [[p[2], p[3]], [p[4], p[5]]],
            [p[6], p[7]], public_inputs
        )).to.equal(true);
    });
});
