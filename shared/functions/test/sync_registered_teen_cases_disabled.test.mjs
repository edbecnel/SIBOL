import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { membershipIdFor } from "../lib/authz/identifiers.js";
import {
  runResolveRegisteredTeenForCase,
  runSyncRegisteredTeenCasesFromProfile,
} from "../lib/cases/exportHandlers.js";

const projectId = "demo-sibol-sync-disabled";
const teenUid = "teenSyncDisabledUid12345678901";
const staffUid = "staffSyncDisabledUid1234567890";
const orgId = "barangay03";
const caseId = "caseSyncDisabledTest001";

let db;

function expectFailedPrecondition(fn) {
  return assert.rejects(fn, (err) => {
    assert.ok(err instanceof AuthzError);
    assert.equal(err.code, "failed-precondition");
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
  await db.collection("organizations").doc(orgId).set({
    orgId,
    type: "barangay",
    name: "Barangay 3",
    status: "active",
    createdAt: now,
    updatedAt: now,
  });
  await db.collection("users").doc(teenUid).set({
    role: "teen",
    displayName: "Sync Test Teen",
    active: true,
    selectedBarangayOrgId: orgId,
    assignedBarangay: "Barangay 3, Balingasag",
    dateOfBirth: "2010-06-15",
    contactEmail: "sync.test.teen@sibol.local",
    createdAt: now,
  });
  await db.collection("users").doc(staffUid).set({
    role: "barangay",
    displayName: "Staff",
    active: true,
    primaryOrgId: orgId,
    createdAt: now,
  });
  const membershipId = membershipIdFor(orgId, staffUid);
  await db.collection("organizationMemberships").doc(membershipId).set({
    membershipId,
    orgId,
    accountUid: staffUid,
    status: "active",
    capabilities: ["case.read", "case.write"],
    createdAt: now,
    updatedAt: now,
  });
  await db.collection("cases").doc(caseId).set({
    orgId,
    demoName: "Case Before Sync",
    fullName: "Case Before Sync",
    age: 16,
    barangay: "Barangay 3, Balingasag",
    caseStatus: "active",
    subjectKind: "registered",
    teenUid,
    linkedAccountEmail: "sync.test.teen@sibol.local",
    dateOfBirth: "2009-09-01",
    contactEmail: "case.corrected@sibol.local",
    registeredAt: now,
    createdAt: now,
    updatedAt: now,
    reportStatus: "notSubmitted",
  });
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("regSyncRegisteredTeenCasesFromProfile (disabled)", () => {
  it("rejects teen caller with failed-precondition and does not modify case", async () => {
    await expectFailedPrecondition(() =>
      runSyncRegisteredTeenCasesFromProfile(db, teenUid, {}),
    );
    const snap = await db.collection("cases").doc(caseId).get();
    assert.equal(snap.data()?.dateOfBirth, "2009-09-01");
    assert.equal(snap.data()?.contactEmail, "case.corrected@sibol.local");
  });

  it("rejects barangay caller with failed-precondition and does not modify case", async () => {
    await expectFailedPrecondition(() =>
      runSyncRegisteredTeenCasesFromProfile(db, staffUid, { caseId }),
    );
    const snap = await db.collection("cases").doc(caseId).get();
    assert.equal(snap.data()?.dateOfBirth, "2009-09-01");
    assert.equal(snap.get("teenProfileSyncedAt"), undefined);
  });
});

describe("regResolveRegisteredTeenForCase (unchanged snapshot)", () => {
  it("still returns teen profile snapshot for linkage", async () => {
    const result = await runResolveRegisteredTeenForCase(db, staffUid, {
      orgId,
      teenUid,
    });
    assert.equal(result.teenUid, teenUid);
    assert.equal(result.fullName, "Sync Test Teen");
    assert.equal(result.dateOfBirth, "2010-06-15");
    assert.equal(result.contactEmail, "sync.test.teen@sibol.local");
    const snap = await db.collection("cases").doc(caseId).get();
    assert.equal(snap.data()?.dateOfBirth, "2009-09-01");
  });
});
