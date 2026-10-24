import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { validateHospitalFacility } from "../src/nhfr_snapshot.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const bundle = JSON.parse(
  readFileSync(join(__dirname, "../fixtures/nhfr-synthetic-demo-v1.json"), "utf8"),
);

describe("nhfr synthetic snapshot", () => {
  it("finds hospital facility", () => {
    const r = validateHospitalFacility(bundle, "SYNTHNHFR000000000001");
    assert.equal(r.ok, true);
  });
});
