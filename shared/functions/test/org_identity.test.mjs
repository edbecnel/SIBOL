import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runCreateBarangayOrganization } from "../lib/admin/exportHandlers.js";
import { runRegisterTeenAccount } from "../lib/teen/exportHandlers.js";
import { barangayIdentityKey } from "../lib/geo/psgc.js";

const projectId = "demo-sibol-org-identity";
const centralUid = "centralOrgIdentityUid1234567890";

process.env.SIBOL_ALLOW_LEGACY_TEEN_ORG_BINDING = "true";

let db;

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST must be set");
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  await db.collection("users").doc(centralUid).set({
    role: "barangay",
    displayName: "Central",
    active: true,
    isCentralAdmin: true,
    createdAt: new Date(),
  });
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("organization identity", () => {
  it("creates barangay org with identity key", async () => {
    const key = `idem-${Date.now()}`;
    const created = await runCreateBarangayOrganization(db, centralUid, {
      idempotencyKey: key,
      psgcVersion: "psgc-synthetic-demo-v1",
      psgcRegionCode: "SYNTH_R10",
      psgcProvinceCode: "SYNTH_P102",
      psgcCityMunCode: "SYNTH_M301",
      psgcBarangayCode: "SYNTH_B401",
      initialOrgAdminEmail: "org.admin.b401@sibol.local",
    });
    assert.ok(created.orgId);
    const identitySnap = await db
      .collection("organizationIdentityKeys")
      .doc(barangayIdentityKey("SYNTH_B401"))
      .get();
    assert.equal(identitySnap.exists, true);
    const orgSnap = await db.collection("organizations").doc(created.orgId).get();
    assert.equal(orgSnap.data()?.orgId, created.orgId);
  });

  it("rejects duplicate PSGC identity", async () => {
    await assert.rejects(
      () =>
        runCreateBarangayOrganization(db, centralUid, {
          idempotencyKey: `idem-dup-${Date.now()}`,
          psgcVersion: "psgc-synthetic-demo-v1",
          psgcRegionCode: "SYNTH_R10",
          psgcProvinceCode: "SYNTH_P102",
          psgcCityMunCode: "SYNTH_M301",
          psgcBarangayCode: "SYNTH_B401",
          initialOrgAdminEmail: "dup@sibol.local",
        }),
      (err) => err instanceof AuthzError && err.code === "already-exists",
    );
  });

  it("teen resolves PSGC to org", async () => {
    const teenUid = "teenPsgcResolveUid12345678901";
    const result = await runRegisterTeenAccount(db, teenUid, true, {
      selectedBarangayPsgcCode: "SYNTH_B401",
      psgcVersion: "psgc-synthetic-demo-v1",
      psgcRegionCode: "SYNTH_R10",
      psgcProvinceCode: "SYNTH_P102",
      psgcCityMunCode: "SYNTH_M301",
      privacyConsentAcknowledged: true,
    });
    assert.equal(result.created, true);
    const user = await db.collection("users").doc(teenUid).get();
    assert.ok(user.data()?.selectedBarangayOrgId);
  });
});
