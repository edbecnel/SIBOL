import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  projectDirectoryFromOrg,
  DEMO_DIRECTORY_ORG_IDS,
} from "../src/sync_organization_directory.mjs";

describe("sync_organization_directory", () => {
  it("projects geographicSiteLabel from legacyBarangayLabel only when present", () => {
    const withSite = projectDirectoryFromOrg("barangay03", {
      name: "Barangay 3 (Poblacion)",
      type: "barangay",
      status: "active",
      legacyBarangayLabel: "Barangay 3, Balingasag",
    });
    assert.equal(withSite.name, "Barangay 3 (Poblacion)");
    assert.equal(withSite.geographicSiteLabel, "Barangay 3, Balingasag");

    const without = projectDirectoryFromOrg("hospital01", {
      name: "Misamis Oriental Provincial Hospital",
      type: "hospital",
      status: "active",
    });
    assert.equal(without.geographicSiteLabel, undefined);
  });

  it("includes demo org ids for backfill", () => {
    assert.deepEqual(DEMO_DIRECTORY_ORG_IDS, ["barangay03", "hospital01"]);
  });
});
