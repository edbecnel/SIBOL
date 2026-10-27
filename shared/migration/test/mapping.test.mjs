import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { writeFileSync, mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { loadOrgMapping } from "../src/load_mapping.mjs";

describe("M1 mapping validation", () => {
  it("rejects invalid orgId in mapping file", () => {
    const dir = mkdtempSync(join(tmpdir(), "sibol-map-"));
    const path = join(dir, "bad.json");
    writeFileSync(
      path,
      JSON.stringify({ barangayLabels: { "X": "bad/org/id" } }),
    );
    assert.throws(() => loadOrgMapping(path), /invalid orgId/);
  });

  it("allows multiple legacy labels to map to the same orgId", () => {
    const dir = mkdtempSync(join(tmpdir(), "sibol-map-"));
    const path = join(dir, "alias.json");
    const org = "barangay03";
    writeFileSync(
      path,
      JSON.stringify({
        barangayLabels: {
          "Barangay 3, Balingasag": org,
          "Barangay Tres, Balingasag": org,
        },
      }),
    );
    const mapping = loadOrgMapping(path);
    assert.equal(mapping.barangayByLabel.get("Barangay Tres, Balingasag"), org);
  });
});
