import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runRegisterTeenAccount } from "../lib/teen/exportHandlers.js";
import { barangayIdentityKey } from "../lib/geo/psgc.js";

const projectId = "demo-sibol-barangay03-psgc-fn";
const activeOrgId = "barangay03";
const teenUid = "teenB3PsgcUid123456789012345";
const unregisteredBarangayCode = "1004302023";

const barangay3Selection = {
  selectedBarangayPsgcCode: "1004302022",
  psgcVersion: "psgc-psa-2025-2q",
  psgcRegionCode: "1000000000",
  psgcProvinceCode: "1004300000",
  psgcCityMunCode: "1004302000",
};

const teenIdentity = {
  displayName: "Barangay 3 Teen",
  dateOfBirth: "2010-06-15",
  contactEmail: "teen.b3.psgc@sibol.local",
};

let db;

function expectDenied(fn, code) {
  return assert.rejects(fn, (err) => {
    assert.ok(err instanceof AuthzError);
    if (code) assert.equal(err.code, code);
    return true;
  });
}

before(async () => {
  delete process.env.SIBOL_ALLOW_DEMO_IDENTITY;
  delete process.env.SIBOL_ALLOW_LEGACY_TEEN_ORG_BINDING;
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST must be set");
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  const now = Timestamp.now();
  await db.collection("organizations").doc(activeOrgId).set({
    orgId: activeOrgId,
    type: "barangay",
    name: "Barangay 3 (Poblacion)",
    legacyBarangayLabel: "Barangay 3, Balingasag",
    status: "active",
    createdAt: now,
    updatedAt: now,
  });
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("Barangay 3 PSGC registration (production path)", () => {
  it("resolves 1004302022 to barangay03 without identity key (pinned prototype)", async () => {
    const uid = "teenPinnedB3Uid12345678901234";
    const result = await runRegisterTeenAccount(db, uid, true, {
      ...barangay3Selection,
      privacyConsentAcknowledged: true,
      ...teenIdentity,
    });
    assert.equal(result.created, true);
    assert.equal(result.selectedBarangayOrgId, activeOrgId);
    const snap = await db.collection("users").doc(uid).get();
    assert.equal(snap.data()?.selectedBarangayOrgId, activeOrgId);
    assert.equal(snap.data()?.assignedBarangay, "Barangay 3, Balingasag");
  });

  it("accepts registered barangay via organizationIdentityKeys", async () => {
    const uid = "teenIdentityKeyUid1234567890123";
    const otherOrg = "org0888888888888888888888";
    const now = Timestamp.now();
    await db.collection("organizations").doc(otherOrg).set({
      orgId: otherOrg,
      type: "barangay",
      name: "Keyed Barangay",
      status: "active",
      psgcBarangayCode: unregisteredBarangayCode,
      createdAt: now,
      updatedAt: now,
    });
    await db
      .collection("organizationIdentityKeys")
      .doc(barangayIdentityKey(unregisteredBarangayCode))
      .set({
        orgId: otherOrg,
        identityKind: "psgc",
        psgcBarangayCode: unregisteredBarangayCode,
      });
    const result = await runRegisterTeenAccount(db, uid, true, {
      selectedBarangayPsgcCode: unregisteredBarangayCode,
      psgcVersion: "psgc-psa-2025-2q",
      psgcRegionCode: "1000000000",
      psgcProvinceCode: "1004300000",
      psgcCityMunCode: "1004302000",
      privacyConsentAcknowledged: true,
      displayName: "Keyed Teen",
      dateOfBirth: "2010-06-15",
      contactPhone: "+639171234567",
    });
    assert.equal(result.selectedBarangayOrgId, otherOrg);
  });

  it("rejects unregistered barangay PSGC", async () => {
    await expectDenied(
      () =>
        runRegisterTeenAccount(db, teenUid, true, {
          selectedBarangayPsgcCode: "1004302024",
          psgcVersion: "psgc-psa-2025-2q",
          psgcRegionCode: "1000000000",
          psgcProvinceCode: "1004300000",
          psgcCityMunCode: "1004302000",
          privacyConsentAcknowledged: true,
          ...teenIdentity,
        }),
      "not-found",
    );
  });

  it("rejects inactive pinned org when suspended", async () => {
    await db.collection("organizations").doc(activeOrgId).update({ status: "suspended" });
    await expectDenied(
      () =>
        runRegisterTeenAccount(db, "teenSuspendedB3Uid123456789012", true, {
          ...barangay3Selection,
          privacyConsentAcknowledged: true,
          ...teenIdentity,
        }),
      "failed-precondition",
    );
    await db.collection("organizations").doc(activeOrgId).update({ status: "active" });
  });

  it("rejects geographic mismatch on identity key org", async () => {
    const mismatchOrg = "org0777777777777777777777";
    const now = Timestamp.now();
    await db.collection("organizations").doc(mismatchOrg).set({
      orgId: mismatchOrg,
      type: "barangay",
      name: "Mismatch",
      status: "active",
      psgcBarangayCode: "1004302024",
      createdAt: now,
      updatedAt: now,
    });
    await db.collection("organizationIdentityKeys").doc(barangayIdentityKey("1004302023")).set({
      orgId: mismatchOrg,
      identityKind: "psgc",
    });
    await expectDenied(
      () =>
        runRegisterTeenAccount(db, "teenMismatchUid12345678901234", true, {
          selectedBarangayPsgcCode: "1004302023",
          psgcVersion: "psgc-psa-2025-2q",
          psgcRegionCode: "1000000000",
          psgcProvinceCode: "1004300000",
          psgcCityMunCode: "1004302000",
          privacyConsentAcknowledged: true,
          displayName: "Mismatch Teen",
          dateOfBirth: "2010-06-15",
          contactPhone: "+639171234567",
        }),
      "failed-precondition",
    );
  });
});
