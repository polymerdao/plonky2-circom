import {ethers} from "hardhat";
import "@nomiclabs/hardhat-etherscan";
import {assert, expect} from "chai";

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
        assert.equal(p.length, 12);
        expect(await verifier.verifyProof(
            [p[0], p[1]],
            [[p[2], p[3]], [p[4], p[5]]],
            [p[6], p[7]], [p[8], p[9], p[10], p[11]]
        )).to.equal(true);
    });
});
