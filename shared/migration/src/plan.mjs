import { membershipIdFor } from "../../reg/src/membership_id.mjs";
import { CAPABILITIES } from "../../reg/src/capabilities.mjs";
import {
  DEMO_BARANGAY_LABEL,
  DEMO_BARANGAY_ORG_ID,
  DEMO_HOSPITAL_ORG_ID,
  DEMO_HOSPITAL_NAME,
} from "./demo_orgs.mjs";
import { resolveBarangayOrgId, loadOrgMapping } from "./load_mapping.mjs";

const CASES = "cases";
const USERS = "users";
const ASSISTANCE = "teenAssistanceRequests";
const REPORTS = "reports";
const THREADS = "caseCoordinationThreads";
const REGISTRY = "barangayCoordinationRegistry";

/**
 * Build migration plan from Firestore snapshot (plain objects).
 * @param {{ dbSnapshot: object, mapping?: ReturnType<loadOrgMapping> }} input
 */
export function buildMigrationPlan({ dbSnapshot, mapping }) {
  const map = mapping ?? loadOrgMapping();
  const plan = {
    organizations: [],
    memberships: [],
    userUpdates: [],
    documentUpdates: [],
    errors: [],
    inventory: {
      barangayLabels: new Set(),
      unmappedLabels: new Set(),
    },
  };

  const now = new Date().toISOString();

  plan.organizations.push({
    orgId: DEMO_BARANGAY_ORG_ID,
    type: "barangay",
    name: DEMO_BARANGAY_LABEL,
    status: "active",
    legacyBarangayLabel: DEMO_BARANGAY_LABEL,
    createdAt: now,
    updatedAt: now,
  });
  plan.organizations.push({
    orgId: DEMO_HOSPITAL_ORG_ID,
    type: "hospital",
    name: DEMO_HOSPITAL_NAME,
    status: "active",
    createdAt: now,
    updatedAt: now,
  });

  for (const user of dbSnapshot.users ?? []) {
    const { uid, data } = user;
    if (!data?.active) continue;
    if (data.role === "barangay") {
      const label = data.assignedBarangay;
      plan.inventory.barangayLabels.add(label);
      const { orgId, error } = resolveBarangayOrgId(label, map);
      if (error) {
        plan.errors.push({ type: "user", uid, error });
        plan.inventory.unmappedLabels.add(label);
        continue;
      }
      const caps = [
        CAPABILITIES.CASE_READ,
        CAPABILITIES.CASE_WRITE,
        CAPABILITIES.REPORT_SUBMIT,
        CAPABILITIES.COORDINATION_BARANGAY,
      ];
      plan.memberships.push(membershipRecord(uid, orgId, caps, now));
      plan.userUpdates.push({
        uid,
        set: { primaryOrgId: orgId },
      });
    } else if (data.role === "moph") {
      plan.memberships.push(
        membershipRecord(uid, DEMO_HOSPITAL_ORG_ID, [
          CAPABILITIES.COORDINATION_HOSPITAL,
        ], now),
      );
      plan.userUpdates.push({
        uid,
        set: { primaryOrgId: DEMO_HOSPITAL_ORG_ID },
      });
    } else if (data.role === "teen") {
      const label = data.assignedBarangay;
      const { orgId, error } = resolveBarangayOrgId(label, map);
      if (error) {
        plan.errors.push({ type: "teen", uid, error });
        continue;
      }
      plan.userUpdates.push({
        uid,
        set: { selectedBarangayOrgId: orgId },
      });
    }
  }

  for (const doc of dbSnapshot.cases ?? []) {
    const label = doc.data?.barangay;
    plan.inventory.barangayLabels.add(label);
    const { orgId, error } = resolveBarangayOrgId(label, map);
    if (error) {
      plan.errors.push({ type: "case", id: doc.id, error });
      plan.inventory.unmappedLabels.add(label);
      continue;
    }
    if (doc.data?.orgId === orgId) continue;
    plan.documentUpdates.push({
      collection: CASES,
      id: doc.id,
      set: { orgId },
    });
  }

  for (const collection of [ASSISTANCE, REPORTS, THREADS, REGISTRY]) {
    for (const doc of dbSnapshot[collection] ?? []) {
      const label = doc.data?.barangay;
      if (!label) continue;
      const { orgId, error } = resolveBarangayOrgId(label, map);
      if (error) {
        plan.errors.push({ type: collection, id: doc.id, error });
        continue;
      }
      if (doc.data?.orgId === orgId) continue;
      plan.documentUpdates.push({
        collection,
        id: doc.id,
        set: { orgId },
      });
    }
  }

  plan.inventory.barangayLabels = [...plan.inventory.barangayLabels];
  plan.inventory.unmappedLabels = [...plan.inventory.unmappedLabels];
  return plan;
}

function membershipRecord(accountUid, orgId, capabilities, now) {
  const membershipId = membershipIdFor(orgId, accountUid);
  return {
    membershipId,
    orgId,
    accountUid,
    status: "active",
    capabilities,
    createdAt: now,
    updatedAt: now,
  };
}

export function planSummary(plan) {
  return {
    organizations: plan.organizations.length,
    memberships: plan.memberships.length,
    userUpdates: plan.userUpdates.length,
    documentUpdates: plan.documentUpdates.length,
    errors: plan.errors.length,
  };
}
