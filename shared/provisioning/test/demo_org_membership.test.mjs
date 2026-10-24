import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { ensureDemoOrganizationsAndMemberships } from "../src/demo_org_membership.mjs";
import {
  DEMO_BARANGAY_ORG_ID,
  DEMO_HOSPITAL_ORG_ID,
} from "../src/constants.mjs";

function createFakeDb() {
  const store = new Map();
  return {
    collection(name) {
      return {
        doc(id) {
          const path = `${name}/${id}`;
          return {
            async get() {
              const data = store.get(path);
              return { exists: data !== undefined, data: () => data };
            },
            async set(data, opts = {}) {
              const prev = store.get(path);
              store.set(
                path,
                opts.merge && prev ? { ...prev, ...data } : { ...data },
              );
            },
          };
        },
      };
    },
    _store: store,
  };
}

describe("ensureDemoOrganizationsAndMemberships", () => {
  it("creates barangay and hospital orgs and memberships idempotently", async () => {
    const db = createFakeDb();
    const barangayUid = "barangayStaffUid123456789012";
    const mophUid = "mophStaffUid1234567890123456";
    await db.collection("users").doc(barangayUid).set({
      role: "barangay",
      active: true,
    });
    await db.collection("users").doc(mophUid).set({ role: "moph", active: true });

    await ensureDemoOrganizationsAndMemberships(
      db,
      [
        { uid: barangayUid, role: "barangay" },
        { uid: mophUid, role: "moph" },
      ],
      { log: () => {} },
    );

    const bMembership = db._store.get(
      `organizationMemberships/mbr_${DEMO_BARANGAY_ORG_ID}__${barangayUid}`,
    );
    assert.ok(bMembership.capabilities.includes("case.read"));
    assert.ok(bMembership.capabilities.includes("coordination.barangay"));
    assert.equal(
      db._store.get(`users/${barangayUid}`).primaryOrgId,
      DEMO_BARANGAY_ORG_ID,
    );

    const mMembership = db._store.get(
      `organizationMemberships/mbr_${DEMO_HOSPITAL_ORG_ID}__${mophUid}`,
    );
    assert.deepEqual(mMembership.capabilities, ["coordination.hospital"]);
    assert.equal(db._store.get(`users/${mophUid}`).primaryOrgId, DEMO_HOSPITAL_ORG_ID);

    const sizeBefore = db._store.size;
    await ensureDemoOrganizationsAndMemberships(
      db,
      [
        { uid: barangayUid, role: "barangay" },
        { uid: mophUid, role: "moph" },
      ],
      { log: () => {} },
    );
    assert.equal(db._store.size, sizeBefore);
  });
});
