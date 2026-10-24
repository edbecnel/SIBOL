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
      JSON.stringify({ barangayLabels: { "X": "not-an-org-id" } }),
    );
    assert.throws(() => loadOrgMapping(path), /invalid orgId/);
  });

  it("rejects duplicate orgId across barangay labels", () => {
    const dir = mkdtempSync(join(tmpdir(), "sibol-map-"));
    const path = join(dir, "dup.json");
    const org = "org0123456789012345678901";
    writeFileSync(
      path,
      JSON.stringify({
        barangayLabels: {
          "A": org,
          "B": org,
        },
      }),
    );
    assert.throws(() => loadOrgMapping(path), /duplicate orgId/);
  });
});
