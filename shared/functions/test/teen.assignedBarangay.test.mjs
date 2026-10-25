import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { AuthzError } from "../lib/authz/assert.js";
import { resolveTeenAssignedBarangayLabel } from "../lib/teen/teenAssignedBarangay.js";

describe("teen assignedBarangay resolution", () => {
  it("derives label from verified PSGC selection", () => {
    const label = resolveTeenAssignedBarangayLabel(
      { type: "barangay", name: "Ignored Org Name" },
      {
        selectedBarangayPsgcCode: "SYNTH_B401",
        psgcVersion: "psgc-synthetic-demo-v1",
        psgcRegionCode: "SYNTH_R10",
        psgcProvinceCode: "SYNTH_P102",
        psgcCityMunCode: "SYNTH_M301",
      },
    );
    assert.equal(label, "San Jose, Synthetic Municipality Alpha");
  });

  it("uses organization legacyBarangayLabel for legacy binding path", () => {
    const label = resolveTeenAssignedBarangayLabel(
      { legacyBarangayLabel: "Barangay Alpha, Demo" },
      { selectedBarangayOrgId: "barangay03" },
    );
    assert.equal(label, "Barangay Alpha, Demo");
  });

  it("rejects legacy path when organization has no routing label", () => {
    assert.throws(
      () =>
        resolveTeenAssignedBarangayLabel(
          { type: "barangay", name: "Barangay Without Label" },
          { selectedBarangayOrgId: "barangay03" },
        ),
      (err) => err instanceof AuthzError && err.code === "failed-precondition",
    );
  });
});
