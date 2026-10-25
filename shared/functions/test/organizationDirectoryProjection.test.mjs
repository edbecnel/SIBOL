import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { projectOrganizationDirectoryFromOrgData } from "../lib/admin/organizationDirectoryProjection.js";

describe("organizationDirectoryProjection", () => {
  it("maps legacyBarangayLabel to geographicSiteLabel", () => {
    const doc = projectOrganizationDirectoryFromOrgData("barangay03", {
      name: "Barangay 3 (Poblacion)",
      type: "barangay",
      status: "active",
      legacyBarangayLabel: "Barangay 3, Balingasag",
    });
    assert.equal(doc.name, "Barangay 3 (Poblacion)");
    assert.equal(doc.geographicSiteLabel, "Barangay 3, Balingasag");
    assert.equal(doc.orgId, "barangay03");
  });
});
