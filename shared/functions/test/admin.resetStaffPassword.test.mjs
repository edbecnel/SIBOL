import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runResetStaffMemberPassword } from "../lib/admin/resetStaffMemberPassword.js";
import { runCreateOrganization, runAcceptStaffInvitation } from "../lib/admin/exportHandlers.js";
import { CAPABILITIES } from "../lib/authz/capabilities.js";
import { membershipIdFor } from "../lib/authz/identifiers.js";

const projectId = "demo-sibol-coord-fn";
const centralUid = "centralResetAdminUid12345678901";
const barangayAdminUid = "barangayResetAdminUid12345678901";
const ordinaryStaffUid = "ordinaryResetStaffUid123456789";

const barangayAdminEmail = "barangay.reset.admin@sibol.local";

let db;
let auth;
let barangayOrgId;

function expectDenied(fn, code) {
  return assert.rejects(fn, (err) => {
    assert.ok(err instanceof AuthzError);
    if (code) assert.equal(err.code, code);
    return true;
  });
}

async function seedUser(uid, { role, isCentralAdmin = false }) {
  await db.collection("users").doc(uid).set({
    role,
    displayName: "Demo",
    active: true,
    createdAt: new Date(),
    ...(isCentralAdmin ? { isCentralAdmin: true } : {}),
  });
}

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST must be set");
  }
  if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error("FIREBASE_AUTH_EMULATOR_HOST must be set");
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  auth = getAuth();

  await seedUser(centralUid, { role: "barangay", isCentralAdmin: true });
  await seedUser(barangayAdminUid, { role: "barangay" });
  await seedUser(ordinaryStaffUid, { role: "barangay" });

  const barangayCreated = await runCreateOrganization(db, centralUid, {
    type: "barangay",
    name: "Reset Test Barangay",
    initialOrgAdminEmail: barangayAdminEmail,
    legacyBarangayLabel: "Barangay Reset",
  });
  barangayOrgId = barangayCreated.orgId;
  await runAcceptStaffInvitation(db, barangayAdminUid, barangayAdminEmail, {
    invitationId: barangayCreated.invitationId,
  });

  const ordinaryMembershipId = membershipIdFor(barangayOrgId, ordinaryStaffUid);
  const now = Timestamp.now();
  await db.collection("organizationMemberships").doc(ordinaryMembershipId).set({
    membershipId: ordinaryMembershipId,
    orgId: barangayOrgId,
    accountUid: ordinaryStaffUid,
    status: "active",
    capabilities: [CAPABILITIES.CASE_READ],
    createdAt: now,
    updatedAt: now,
  });

  await auth.createUser({
    uid: ordinaryStaffUid,
    email: "ordinary.reset.staff@sibol.local",
    password: "OldStaffPass123!",
  });
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("admin staff password reset", () => {
  it("PR-01 barangay org admin resets eligible staff", async () => {
    await runResetStaffMemberPassword(db, auth, barangayAdminUid, {
      orgId: barangayOrgId,
      targetAccountUid: ordinaryStaffUid,
      newPassword: "TempReset123!",
    });
    const userSnap = await db.collection("users").doc(ordinaryStaffUid).get();
    assert.equal(userSnap.data()?.mustChangePassword, true);
  });

  it("PR-03 ordinary staff cannot reset", async () => {
    await expectDenied(
      () =>
        runResetStaffMemberPassword(db, auth, ordinaryStaffUid, {
          orgId: barangayOrgId,
          targetAccountUid: barangayAdminUid,
          newPassword: "TempReset234!",
        }),
      "permission-denied",
    );
  });

  it("PR-05 org admin target protected", async () => {
    await expectDenied(
      () =>
        runResetStaffMemberPassword(db, auth, barangayAdminUid, {
          orgId: barangayOrgId,
          targetAccountUid: barangayAdminUid,
          newPassword: "TempReset345!",
        }),
      "permission-denied",
    );
  });
});
