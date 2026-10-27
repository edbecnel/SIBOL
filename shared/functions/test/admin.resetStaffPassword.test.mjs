import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runResetStaffMemberPassword } from "../lib/admin/resetStaffMemberPassword.js";
import {
  runCreateOrganization,
  runAcceptStaffInvitation,
} from "../lib/admin/exportHandlers.js";
import { CAPABILITIES } from "../lib/authz/capabilities.js";
import { membershipIdFor } from "../lib/authz/identifiers.js";

const projectId = "demo-sibol-coord-fn";
const centralUid = "centralResetAdminUid12345678901";
const barangayAdminUid = "barangayResetAdminUid12345678901";
const backupBarangayAdminUid = "backupBarangayAdminUid1234567890";
const hospitalAdminUid = "hospitalResetAdminUid12345678901";
const ordinaryStaffUid = "ordinaryResetStaffUid123456789";
const otherOrgStaffUid = "otherOrgStaffUid1234567890123";
const centralTargetUid = "centralTargetUid123456789012345";

const barangayAdminEmail = "barangay.reset.admin@sibol.local";
const backupBarangayAdminEmail = "backup.barangay.reset.admin@sibol.local";
const hospitalAdminEmail = "hospital.reset.admin@sibol.local";

let db;
let auth;
let barangayOrgId;
let hospitalOrgId;
let otherBarangayOrgId;

function expectDenied(fn, code) {
  return assert.rejects(fn, (err) => {
    assert.ok(err instanceof AuthzError);
    if (code) assert.equal(err.code, code);
    return true;
  });
}

async function seedUser(uid, { role, isCentralAdmin = false, displayName = "Demo" }) {
  await db.collection("users").doc(uid).set({
    role,
    displayName,
    active: true,
    createdAt: new Date(),
    ...(isCentralAdmin ? { isCentralAdmin: true } : {}),
  });
}

async function seedStaffMembership(orgId, uid, capabilities) {
  const membershipId = membershipIdFor(orgId, uid);
  const now = Timestamp.now();
  await db.collection("organizationMemberships").doc(membershipId).set({
    membershipId,
    orgId,
    accountUid: uid,
    status: "active",
    capabilities,
    createdAt: now,
    updatedAt: now,
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
  await seedUser(centralTargetUid, {
    role: "barangay",
    isCentralAdmin: true,
    displayName: "Central Target",
  });
  await seedUser(barangayAdminUid, { role: "barangay" });
  await seedUser(backupBarangayAdminUid, { role: "barangay" });
  await seedUser(hospitalAdminUid, { role: "moph" });
  await seedUser(ordinaryStaffUid, { role: "barangay" });
  await seedUser(otherOrgStaffUid, { role: "barangay" });

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

  const backupInvite = await runCreateOrganization(db, centralUid, {
    type: "barangay",
    name: "Other Barangay",
    initialOrgAdminEmail: backupBarangayAdminEmail,
    legacyBarangayLabel: "Barangay Other",
  });
  otherBarangayOrgId = backupInvite.orgId;
  await runAcceptStaffInvitation(db, backupBarangayAdminUid, backupBarangayAdminEmail, {
    invitationId: backupInvite.invitationId,
  });

  const hospitalCreated = await runCreateOrganization(db, centralUid, {
    type: "hospital",
    name: "Reset Test Hospital",
    initialOrgAdminEmail: hospitalAdminEmail,
  });
  hospitalOrgId = hospitalCreated.orgId;
  await runAcceptStaffInvitation(db, hospitalAdminUid, hospitalAdminEmail, {
    invitationId: hospitalCreated.invitationId,
  });

  await seedStaffMembership(barangayOrgId, ordinaryStaffUid, [
    CAPABILITIES.CASE_READ,
  ]);
  await seedStaffMembership(barangayOrgId, backupBarangayAdminUid, [
    CAPABILITIES.ORG_MANAGE_MEMBERS,
    CAPABILITIES.ORG_MANAGE_ROLES,
  ]);
  await seedStaffMembership(otherBarangayOrgId, otherOrgStaffUid, [
    CAPABILITIES.CASE_READ,
  ]);

  for (const [uid, email] of [
    [ordinaryStaffUid, "ordinary.reset.staff@sibol.local"],
    [barangayAdminUid, barangayAdminEmail],
    [backupBarangayAdminUid, backupBarangayAdminEmail],
    [hospitalAdminUid, hospitalAdminEmail],
    [otherOrgStaffUid, "other.org.staff@sibol.local"],
    [centralTargetUid, "central.target@sibol.local"],
  ]) {
    try {
      await auth.getUser(uid);
    } catch {
      await auth.createUser({ uid, email, password: "OldStaffPass123!" });
    }
  }
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("admin staff password reset", () => {
  it("PR-01 org admin resets ordinary staff in own org", async () => {
    const beforeUid = ordinaryStaffUid;
    await runResetStaffMemberPassword(db, auth, barangayAdminUid, {
      orgId: barangayOrgId,
      targetAccountUid: ordinaryStaffUid,
      newPassword: "TempReset123!",
    });
    const userSnap = await db.collection("users").doc(ordinaryStaffUid).get();
    assert.equal(userSnap.data()?.mustChangePassword, true);
    assert.equal(userSnap.id, beforeUid);
  });

  it("PR-02 central admin resets barangay org administrator", async () => {
    const membershipId = membershipIdFor(barangayOrgId, barangayAdminUid);
    const beforeMembership = (
      await db.collection("organizationMemberships").doc(membershipId).get()
    ).data();
    await runResetStaffMemberPassword(db, auth, centralUid, {
      orgId: barangayOrgId,
      targetAccountUid: barangayAdminUid,
      newPassword: "TempReset234!",
    });
    const snap = await db.collection("users").doc(barangayAdminUid).get();
    assert.equal(snap.data()?.mustChangePassword, true);
    assert.equal(snap.data()?.role, "barangay");
    const authUser = await auth.getUser(barangayAdminUid);
    assert.equal(authUser.uid, barangayAdminUid);
    const afterMembership = (
      await db.collection("organizationMemberships").doc(membershipId).get()
    ).data();
    assert.deepEqual(afterMembership?.capabilities, beforeMembership?.capabilities);
    assert.equal(afterMembership?.status, "active");
  });

  it("PR-03 central admin resets backup barangay org administrator", async () => {
    await runResetStaffMemberPassword(db, auth, centralUid, {
      orgId: barangayOrgId,
      targetAccountUid: backupBarangayAdminUid,
      newPassword: "TempReset235!",
    });
    const snap = await db.collection("users").doc(backupBarangayAdminUid).get();
    assert.equal(snap.data()?.mustChangePassword, true);
  });

  it("PR-04 central admin resets hospital org administrator", async () => {
    await runResetStaffMemberPassword(db, auth, centralUid, {
      orgId: hospitalOrgId,
      targetAccountUid: hospitalAdminUid,
      newPassword: "TempReset236!",
    });
    const snap = await db.collection("users").doc(hospitalAdminUid).get();
    assert.equal(snap.data()?.mustChangePassword, true);
    assert.equal(snap.data()?.role, "moph");
  });

  it("PR-05 central admin resets ordinary staff", async () => {
    await runResetStaffMemberPassword(db, auth, centralUid, {
      orgId: barangayOrgId,
      targetAccountUid: ordinaryStaffUid,
      newPassword: "TempReset237!",
    });
    const snap = await db.collection("users").doc(ordinaryStaffUid).get();
    assert.equal(snap.data()?.mustChangePassword, true);
  });

  it("PR-06 org admin cannot reset another org administrator", async () => {
    await expectDenied(
      () =>
        runResetStaffMemberPassword(db, auth, barangayAdminUid, {
          orgId: barangayOrgId,
          targetAccountUid: backupBarangayAdminUid,
          newPassword: "TempReset345!",
        }),
      "permission-denied",
    );
  });

  it("PR-07 org admin cannot reset staff in another organization", async () => {
    await expectDenied(
      () =>
        runResetStaffMemberPassword(db, auth, barangayAdminUid, {
          orgId: otherBarangayOrgId,
          targetAccountUid: otherOrgStaffUid,
          newPassword: "TempReset456!",
        }),
      "permission-denied",
    );
  });

  it("PR-08 cannot reset central administrator target", async () => {
    await expectDenied(
      () =>
        runResetStaffMemberPassword(db, auth, centralUid, {
          orgId: barangayOrgId,
          targetAccountUid: centralTargetUid,
          newPassword: "TempReset567!",
        }),
      "permission-denied",
    );
  });

  it("PR-09 self-reset denied", async () => {
    await expectDenied(
      () =>
        runResetStaffMemberPassword(db, auth, barangayAdminUid, {
          orgId: barangayOrgId,
          targetAccountUid: barangayAdminUid,
          newPassword: "TempReset678!",
        }),
      "permission-denied",
    );
  });

  it("PR-10 ordinary staff cannot reset others", async () => {
    await expectDenied(
      () =>
        runResetStaffMemberPassword(db, auth, ordinaryStaffUid, {
          orgId: barangayOrgId,
          targetAccountUid: barangayAdminUid,
          newPassword: "TempReset789!",
        }),
      "permission-denied",
    );
  });
});
