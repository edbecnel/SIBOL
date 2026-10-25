import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { validateBarangaySelection } from "../src/psgc_graph.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const bundle = JSON.parse(
  readFileSync(join(__dirname, "../artifacts/psgc-psa-2025-2q.json"), "utf8"),
);

describe("psgc-psa-2025-2q acceptance", () => {
  it("validates Barangay 3, Balingasag, Misamis Oriental, Region X", () => {
    const result = validateBarangaySelection(bundle, {
      psgcVersion: "psgc-psa-2025-2q",
      psgcRegionCode: "1000000000",
      psgcProvinceCode: "1004300000",
      psgcCityMunCode: "1004302000",
      psgcBarangayCode: "1004302022",
    });
    assert.equal(result.ok, true);
  });

  it("is not synthetic", () => {
    assert.equal(bundle.synthetic, false);
    assert.equal(bundle.nodes.length > 40000, true);
  });
});
