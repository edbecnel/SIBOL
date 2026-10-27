import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runResetStaffMemberPassword } from "../lib/admin/resetStaffMemberPassword.js";
import {
  runListTeensForBarangayOrgAdminRecovery,
  sanitizeTeenListEntry,
} from "../lib/admin/listTeensForBarangayOrgAdminRecovery.js";
import { runResetTeenPasswordByBarangayOrgAdmin } from "../lib/admin/resetTeenPasswordByBarangayOrgAdmin.js";
import {
  runCreateOrganization,
  runAcceptStaffInvitation,
} from "../lib/admin/exportHandlers.js";
import { CAPABILITIES } from "../lib/authz/capabilities.js";
import { membershipIdFor } from "../lib/authz/identifiers.js";

const projectId = "demo-sibol-teen-recovery-fn";
const centralUid = "centralTeenRecoveryUid123456789";
const barangayAdminUid = "barangayTeenRecoveryAdminUid123456";
const ordinaryStaffUid = "ordinaryTeenRecoveryStaffUid1234";
const hospitalAdminUid = "hospitalTeenRecoveryAdminUid12345";
const multiAdminUid = "multiBarangayAdminUid12345678901";

const teenAUid = "teenRecoveryAUid123456789012345";
const teenBUid = "teenRecoveryBUid123456789012345";
const teenInactiveUid = "teenRecoveryInactiveUid1234567890";

const teenAEmail = "teen.recovery.a@sibol.local";
const teenBEmail = "teen.recovery.b@sibol.local";

let db;
let auth;
let barangayOrgId;
let otherBarangayOrgId;
let hospitalOrgId;

function expectDenied(fn, code) {
  return assert.rejects(fn, (err) => {
    assert.ok(err instanceof AuthzError);
    if (code) assert.equal(err.code, code);
    return true;
  });
}

async function seedUser(uid, fields) {
  await db.collection("users").doc(uid).set({
    createdAt: Timestamp.now(),
    ...fields,
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

async function ensureAuthUser(uid, email, password = "OldTeenPass123!") {
  try {
    await auth.getUser(uid);
  } catch {
    await auth.createUser({ uid, email, password });
  }
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

  await seedUser(centralUid, {
    role: "barangay",
    displayName: "Central",
    active: true,
    isCentralAdmin: true,
  });
  await seedUser(barangayAdminUid, { role: "barangay", displayName: "B Admin", active: true });
  await seedUser(ordinaryStaffUid, { role: "barangay", displayName: "Staff", active: true });
  await seedUser(hospitalAdminUid, { role: "moph", displayName: "H Admin", active: true });
  await seedUser(multiAdminUid, { role: "barangay", displayName: "Multi", active: true });

  const barangayCreated = await runCreateOrganization(db, centralUid, {
    type: "barangay",
    name: "Barangay 3 (Poblacion)",
    initialOrgAdminEmail: "barangay.teen.recovery.admin@sibol.local",
    legacyBarangayLabel: "Barangay 3, Balingasag",
  });
  barangayOrgId = barangayCreated.orgId;
  await runAcceptStaffInvitation(db, barangayAdminUid, "barangay.teen.recovery.admin@sibol.local", {
    invitationId: barangayCreated.invitationId,
  });

  const otherCreated = await runCreateOrganization(db, centralUid, {
    type: "barangay",
    name: "Other Barangay",
    initialOrgAdminEmail: "other.teen.recovery.admin@sibol.local",
    legacyBarangayLabel: "Barangay 3, Balingasag",
  });
  otherBarangayOrgId = otherCreated.orgId;

  const hospitalCreated = await runCreateOrganization(db, centralUid, {
    type: "hospital",
    name: "Misamis Oriental Provincial Hospital",
    initialOrgAdminEmail: "hospital.teen.recovery.admin@sibol.local",
  });
  hospitalOrgId = hospitalCreated.orgId;
  await runAcceptStaffInvitation(db, hospitalAdminUid, "hospital.teen.recovery.admin@sibol.local", {
    invitationId: hospitalCreated.invitationId,
  });

  await seedStaffMembership(barangayOrgId, ordinaryStaffUid, [CAPABILITIES.CASE_READ]);
  await seedStaffMembership(otherBarangayOrgId, multiAdminUid, [
    CAPABILITIES.ORG_MANAGE_MEMBERS,
    CAPABILITIES.ORG_MANAGE_ROLES,
  ]);
  await seedStaffMembership(barangayOrgId, multiAdminUid, [
    CAPABILITIES.ORG_MANAGE_MEMBERS,
    CAPABILITIES.ORG_MANAGE_ROLES,
  ]);

  await seedUser(teenAUid, {
    role: "teen",
    displayName: "Teen A",
    active: true,
    selectedBarangayOrgId: barangayOrgId,
    assignedBarangay: "Barangay 3, Balingasag",
    contactEmail: "secret.contact@sibol.local",
    contactPhone: "09170000000",
  });
  await seedUser(teenBUid, {
    role: "teen",
    displayName: "Teen B",
    active: true,
    selectedBarangayOrgId: otherBarangayOrgId,
    assignedBarangay: "Barangay 3, Balingasag",
  });
  await seedUser(teenInactiveUid, {
    role: "teen",
    displayName: "Inactive Teen",
    active: false,
    selectedBarangayOrgId: barangayOrgId,
  });

  await ensureAuthUser(teenAUid, teenAEmail);
  await ensureAuthUser(teenBUid, teenBEmail);
  await ensureAuthUser(ordinaryStaffUid, "ordinary.teen.recovery.staff@sibol.local");
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("teen password recovery", () => {
  it("TR-LIST-01 org admin lists teens in own barangay only", async () => {
    const result = await runListTeensForBarangayOrgAdminRecovery(db, auth, barangayAdminUid, {});
    assert.equal(result.managedBarangayOrgId, barangayOrgId);
    const uids = result.teens.map((t) => t.teenUid);
    assert.ok(uids.includes(teenAUid));
    assert.ok(!uids.includes(teenBUid));
    assert.ok(!uids.includes(teenInactiveUid));
    const teenA = result.teens.find((t) => t.teenUid === teenAUid);
    assert.equal(teenA.displayName, "Teen A");
    assert.equal(teenA.signInEmail, teenAEmail);
    const sanitized = sanitizeTeenListEntry(teenA);
    assert.deepEqual(Object.keys(sanitized).sort(), [
      "displayName",
      "signInEmail",
      "teenUid",
    ]);
  });

  it("TR-LIST-02 central requires explicit barangay org", async () => {
    await expectDenied(
      () => runListTeensForBarangayOrgAdminRecovery(db, auth, centralUid, {}),
      "invalid-argument",
    );
    const result = await runListTeensForBarangayOrgAdminRecovery(db, auth, centralUid, {
      managedBarangayOrgId: barangayOrgId,
    });
    assert.ok(result.teens.some((t) => t.teenUid === teenAUid));
  });

  it("TR-LIST-03 ordinary staff denied", async () => {
    await expectDenied(
      () =>
        runListTeensForBarangayOrgAdminRecovery(db, auth, ordinaryStaffUid, {
          managedBarangayOrgId: barangayOrgId,
        }),
      "permission-denied",
    );
  });

  it("TR-LIST-04 hospital org admin denied", async () => {
    await expectDenied(
      () =>
        runListTeensForBarangayOrgAdminRecovery(db, auth, hospitalAdminUid, {
          managedBarangayOrgId: barangayOrgId,
        }),
      "permission-denied",
    );
  });

  it("TR-LIST-05 central invalid hospital org selection denied", async () => {
    await expectDenied(
      () =>
        runListTeensForBarangayOrgAdminRecovery(db, auth, centralUid, {
          managedBarangayOrgId: hospitalOrgId,
        }),
      "permission-denied",
    );
  });

  it("TR-LIST-06 multi-barangay admin requires selection", async () => {
    await expectDenied(
      () => runListTeensForBarangayOrgAdminRecovery(db, auth, multiAdminUid, {}),
      "invalid-argument",
    );
    const result = await runListTeensForBarangayOrgAdminRecovery(db, auth, multiAdminUid, {
      managedBarangayOrgId: barangayOrgId,
    });
    assert.ok(result.teens.some((t) => t.teenUid === teenAUid));
  });

  it("TR-RESET-01 org admin resets teen in same barangay", async () => {
    const before = (await db.collection("users").doc(teenAUid).get()).data();
    await runResetTeenPasswordByBarangayOrgAdmin(db, auth, barangayAdminUid, {
      targetTeenUid: teenAUid,
      newPassword: "TempTeenReset1!",
    });
    const after = (await db.collection("users").doc(teenAUid).get()).data();
    assert.equal(after.mustChangePassword, true);
    assert.ok(after.passwordResetAt);
    assert.equal(after.selectedBarangayOrgId, before.selectedBarangayOrgId);
    assert.equal(after.role, "teen");
    assert.equal(after.contactEmail, "secret.contact@sibol.local");
    const audit = await db
      .collection("auditEvents")
      .where("operation", "==", "teen_password_reset_by_org_admin")
      .where("targetAccountUid", "==", teenAUid)
      .get();
    assert.ok(audit.size >= 1);
    const event = audit.docs[0].data();
    assert.equal(event.outcome, "success");
    assert.equal(event.targetOrgId, barangayOrgId);
    assert.equal(event.after?.mustChangePassword, true);
    assert.equal(event.password, undefined);
  });

  it("TR-RESET-02 cross-barangay denied", async () => {
    await expectDenied(
      () =>
        runResetTeenPasswordByBarangayOrgAdmin(db, auth, barangayAdminUid, {
          targetTeenUid: teenBUid,
          newPassword: "TempTeenReset2!",
        }),
      "permission-denied",
    );
  });

  it("TR-RESET-03 central with valid barangay selection", async () => {
    await runResetTeenPasswordByBarangayOrgAdmin(db, auth, centralUid, {
      managedBarangayOrgId: barangayOrgId,
      targetTeenUid: teenAUid,
      newPassword: "TempTeenReset3!",
    });
    const after = (await db.collection("users").doc(teenAUid).get()).data();
    assert.equal(after.mustChangePassword, true);
  });

  it("TR-RESET-04 inactive teen denied", async () => {
    await expectDenied(
      () =>
        runResetTeenPasswordByBarangayOrgAdmin(db, auth, barangayAdminUid, {
          targetTeenUid: teenInactiveUid,
          newPassword: "TempTeenReset4!",
        }),
      "permission-denied",
    );
  });

  it("TR-RESET-05 self-reset denied", async () => {
    await seedUser(teenAUid, {
      role: "teen",
      displayName: "Teen A",
      active: true,
      selectedBarangayOrgId: barangayOrgId,
    });
    await expectDenied(
      () =>
        runResetTeenPasswordByBarangayOrgAdmin(db, auth, teenAUid, {
          targetTeenUid: teenAUid,
          newPassword: "TempTeenReset5!",
        }),
      "permission-denied",
    );
  });

  it("TR-REG-01 staff password reset unchanged", async () => {
    await runResetStaffMemberPassword(db, auth, barangayAdminUid, {
      orgId: barangayOrgId,
      targetAccountUid: ordinaryStaffUid,
      newPassword: "TempStaffStill1!",
    });
    const snap = await db.collection("users").doc(ordinaryStaffUid).get();
    assert.equal(snap.data()?.mustChangePassword, true);
  });
});
