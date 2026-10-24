import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runListBarangayDirectory } from "../lib/teen/exportHandlers.js";
import { runRegisterTeenAccount } from "../lib/teen/exportHandlers.js";

const projectId = "demo-sibol-coord-fn";
const activeOrgId = "barangay03";
const suspendedOrgId = "org0999999999999999999999";
const teenUid = "teenRegisterUid1234567890123";
const staffUid = "barangayStaffUid123456789012";

let db;

function expectDenied(fn, code) {
  return assert.rejects(fn, (err) => {
    assert.ok(err instanceof AuthzError);
    if (code) assert.equal(err.code, code);
    return true;
  });
}

before(async () => {
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
    name: "Barangay Alpha",
    status: "active",
    legacyBarangayLabel: "Barangay Alpha, Demo",
    createdAt: now,
    updatedAt: now,
  });
  await db.collection("organizations").doc(suspendedOrgId).set({
    orgId: suspendedOrgId,
    type: "barangay",
    name: "Barangay Suspended",
    status: "suspended",
    createdAt: now,
    updatedAt: now,
  });
  await db.collection("users").doc(staffUid).set({
    role: "barangay",
    displayName: "Staff",
    active: true,
    createdAt: now,
  });
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("REG-C teen registration", () => {
  it("lists active barangay organizations only", async () => {
    const { organizations } = await runListBarangayDirectory(db);
    assert.ok(organizations.some((o) => o.orgId === activeOrgId));
    assert.ok(!organizations.some((o) => o.orgId === suspendedOrgId));
  });

  it("creates teen profile for authenticated uid", async () => {
    const result = await runRegisterTeenAccount(db, teenUid, true, {
      selectedBarangayOrgId: activeOrgId,
      privacyConsentAcknowledged: true,
      displayName: "Teen Demo",
    });
    assert.equal(result.created, true);
    const snap = await db.collection("users").doc(teenUid).get();
    assert.equal(snap.data()?.role, "teen");
    assert.equal(snap.data()?.selectedBarangayOrgId, activeOrgId);
    assert.equal(snap.data()?.isCentralAdmin, undefined);
  });

  it("is idempotent on duplicate submission", async () => {
    const second = await runRegisterTeenAccount(db, teenUid, true, {
      selectedBarangayOrgId: activeOrgId,
      privacyConsentAcknowledged: true,
    });
    assert.equal(second.created, false);
    assert.equal(second.idempotent, true);
  });

  it("rejects invalid barangay org", async () => {
    const otherUid = "teenInvalidOrgUid1234567890123";
    await expectDenied(
      () =>
        runRegisterTeenAccount(db, otherUid, true, {
          selectedBarangayOrgId: "not/a/valid/org",
          privacyConsentAcknowledged: true,
        }),
      "invalid-argument",
    );
  });

  it("rejects inactive barangay", async () => {
    const otherUid = "teenSuspendedOrgUid12345678901";
    await expectDenied(
      () =>
        runRegisterTeenAccount(db, otherUid, true, {
          selectedBarangayOrgId: suspendedOrgId,
          privacyConsentAcknowledged: true,
        }),
      "failed-precondition",
    );
  });

  it("rejects missing consent", async () => {
    const otherUid = "teenNoConsentUid1234567890123";
    await expectDenied(
      () =>
        runRegisterTeenAccount(db, otherUid, true, {
          selectedBarangayOrgId: activeOrgId,
          privacyConsentAcknowledged: false,
        }),
      "invalid-argument",
    );
  });

  it("rejects existing staff account", async () => {
    await expectDenied(
      () =>
        runRegisterTeenAccount(db, staffUid, true, {
          selectedBarangayOrgId: activeOrgId,
          privacyConsentAcknowledged: true,
        }),
      "failed-precondition",
    );
  });

  it("rejects unauthenticated registration", async () => {
    await expectDenied(
      () =>
        runRegisterTeenAccount(db, undefined, false, {
          selectedBarangayOrgId: activeOrgId,
          privacyConsentAcknowledged: true,
        }),
      "unauthenticated",
    );
  });

  it("rejects suspended teen account re-register", async () => {
    const suspendedTeen = "teenSuspendedUid1234567890123";
    const now = Timestamp.now();
    await db.collection("users").doc(suspendedTeen).set({
      role: "teen",
      displayName: "Suspended",
      active: false,
      selectedBarangayOrgId: activeOrgId,
      createdAt: now,
    });
    await expectDenied(
      () =>
        runRegisterTeenAccount(db, suspendedTeen, true, {
          selectedBarangayOrgId: activeOrgId,
          privacyConsentAcknowledged: true,
        }),
      "permission-denied",
    );
  });

  it("writes audit event on first registration", async () => {
    const freshUid = "teenAuditUid1234567890123456";
    await runRegisterTeenAccount(db, freshUid, true, {
      selectedBarangayOrgId: activeOrgId,
      privacyConsentAcknowledged: true,
    });
    const snap = await db
      .collection("auditEvents")
      .where("operation", "==", "teen_registered")
      .where("targetAccountUid", "==", freshUid)
      .limit(1)
      .get();
    assert.ok(!snap.empty);
  });
});
