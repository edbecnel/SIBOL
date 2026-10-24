import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import {
  indexNodes,
  listLguParentsUnderRegion,
  listChildren,
  validateBarangaySelection,
} from "../src/psgc_graph.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const bundle = JSON.parse(
  readFileSync(join(__dirname, "../fixtures/psgc-synthetic-demo-v1.json"), "utf8"),
);

describe("psgc synthetic demo graph", () => {
  const byCode = indexNodes(bundle);

  it("mixed region has province and HUC city parents", () => {
    const parents = listLguParentsUnderRegion(byCode, "SYNTH_R10");
    assert.equal(parents.some((p) => p.code === "SYNTH_P102"), true);
    assert.equal(parents.some((p) => p.code === "SYNTH_C201"), true);
  });

  it("validates province path barangay", () => {
    const result = validateBarangaySelection(bundle, {
      psgcVersion: "psgc-synthetic-demo-v1",
      psgcRegionCode: "SYNTH_R10",
      psgcProvinceCode: "SYNTH_P102",
      psgcCityMunCode: "SYNTH_M301",
      psgcBarangayCode: "SYNTH_B401",
    });
    assert.equal(result.ok, true);
  });

  it("validates HUC path without province", () => {
    const result = validateBarangaySelection(bundle, {
      psgcVersion: "psgc-synthetic-demo-v1",
      psgcRegionCode: "SYNTH_R10",
      psgcProvinceCode: null,
      psgcCityMunCode: "SYNTH_C201",
      psgcBarangayCode: "SYNTH_B402",
    });
    assert.equal(result.ok, true);
  });

  it("rejects invalid parent-child", () => {
    const result = validateBarangaySelection(bundle, {
      psgcVersion: "psgc-synthetic-demo-v1",
      psgcRegionCode: "SYNTH_R10",
      psgcProvinceCode: "SYNTH_P102",
      psgcCityMunCode: "SYNTH_C201",
      psgcBarangayCode: "SYNTH_B401",
    });
    assert.equal(result.ok, false);
  });

  it("lists barangays under municipality", () => {
    const bgys = listChildren(byCode, "SYNTH_M301", "barangay");
    assert.equal(bgys.length, 2);
  });
});
