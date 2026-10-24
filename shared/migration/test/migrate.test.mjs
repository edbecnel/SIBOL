import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { buildMigrationPlan, planSummary } from "../src/plan.mjs";
import { loadOrgMapping, resolveBarangayOrgId } from "../src/load_mapping.mjs";
import {
  DEMO_BARANGAY_LABEL,
  DEMO_BARANGAY_ORG_ID,
} from "../src/demo_orgs.mjs";

describe("REG-001 M1 migration plan", () => {
  it("resolves only explicit barangay labels", () => {
    const mapping = loadOrgMapping();
    const ok = resolveBarangayOrgId(DEMO_BARANGAY_LABEL, mapping);
    assert.equal(ok.orgId, DEMO_BARANGAY_ORG_ID);
    const bad = resolveBarangayOrgId("Unknown Barangay", mapping);
    assert.equal(bad.orgId, null);
    assert.match(bad.error, /unmapped/);
  });

  it("builds idempotent plan for demo snapshot", () => {
    const mapping = loadOrgMapping();
    const snapshot = {
      users: [
        {
          uid: "barangayStaffUid123456789012",
          data: {
            active: true,
            role: "barangay",
            assignedBarangay: DEMO_BARANGAY_LABEL,
          },
        },
        {
          uid: "teenUserUid123456789012345",
          data: {
            active: true,
            role: "teen",
            assignedBarangay: DEMO_BARANGAY_LABEL,
          },
        },
      ],
      cases: [
        {
          id: "c1",
          data: { barangay: DEMO_BARANGAY_LABEL },
        },
      ],
    };
    const plan1 = buildMigrationPlan({ dbSnapshot: snapshot, mapping });
    const plan2 = buildMigrationPlan({
      dbSnapshot: {
        ...snapshot,
        cases: [{ id: "c1", data: { barangay: DEMO_BARANGAY_LABEL, orgId: DEMO_BARANGAY_ORG_ID } }],
      },
      mapping,
    });
    assert.equal(planSummary(plan1).documentUpdates, 1);
    assert.equal(planSummary(plan2).documentUpdates, 0);
    assert.equal(plan1.memberships.length, 1);
    assert.equal(
      plan1.userUpdates.find((u) => u.uid === "teenUserUid123456789012345")?.set
        .selectedBarangayOrgId,
      DEMO_BARANGAY_ORG_ID,
    );
  });

  it("records errors for ambiguous labels without inferring org", () => {
    const mapping = loadOrgMapping();
    const plan = buildMigrationPlan({
      dbSnapshot: {
        cases: [{ id: "x", data: { barangay: "Barangay Demo" } }],
      },
      mapping,
    });
    assert.ok(plan.errors.length >= 1);
  });
});
