import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runProvisionStaffMember } from "../lib/admin/provisionStaffMember.js";
import { runCreateOrganization, runAcceptStaffInvitation } from "../lib/admin/exportHandlers.js";
import { CAPABILITIES } from "../lib/authz/capabilities.js";
import { membershipIdFor } from "../lib/authz/identifiers.js";

const projectId = "demo-sibol-coord-fn";
const centralUid = "centralProvAdminUid12345678901";
const barangayAdminUid = "barangayOrgAdminUid12345678901";
const outsiderUid = "outsiderProvUid1234567890123";
const ordinaryStaffUid = "ordinaryStaffUid123456789012";

const centralEmail = "central.prov@sibol.local";
const barangayAdminEmail = "barangay.org.prov@sibol.local";

let db;
let auth;
let barangayOrgId;
let hospitalOrgId;

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

async function seedOrgAdmin(uid, orgId) {
  const membershipId = membershipIdFor(orgId, uid);
  const now = Timestamp.now();
  await db.collection("organizationMemberships").doc(membershipId).set({
    membershipId,
    orgId,
    accountUid: uid,
    status: "active",
    capabilities: [
      CAPABILITIES.ORG_MANAGE_MEMBERS,
      CAPABILITIES.ORG_MANAGE_ROLES,
    ],
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
  await seedUser(barangayAdminUid, { role: "barangay" });
  await seedUser(outsiderUid, { role: "barangay" });
  await seedUser(ordinaryStaffUid, { role: "barangay" });

  const barangayCreated = await runCreateOrganization(db, centralUid, {
    type: "barangay",
    name: "Provision Test Barangay",
    initialOrgAdminEmail: barangayAdminEmail,
    legacyBarangayLabel: "Barangay 3, Balingasag",
  });
  barangayOrgId = barangayCreated.orgId;
  await runAcceptStaffInvitation(db, barangayAdminUid, barangayAdminEmail, {
    invitationId: barangayCreated.invitationId,
  });

  const hospitalCreated = await runCreateOrganization(db, centralUid, {
    type: "hospital",
    name: "Provision Test Hospital",
    initialOrgAdminEmail: "hospital.admin.prov@sibol.local",
  });
  hospitalOrgId = hospitalCreated.orgId;
  const hospitalAdminUid = "hospitalOrgAdminUid12345678901";
  await seedUser(hospitalAdminUid, { role: "moph" });
  await runAcceptStaffInvitation(
    db,
    hospitalAdminUid,
    "hospital.admin.prov@sibol.local",
    { invitationId: hospitalCreated.invitationId },
  );

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
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("direct staff provisioning", () => {
  it("SP-01 barangay org admin creates staff with sign-in", async () => {
    const email = "new.barangay.staff@sibol.local";
    const password = "StaffPass123!";
    const result = await runProvisionStaffMember(db, auth, barangayAdminUid, {
      orgId: barangayOrgId,
      email,
      displayName: "New Barangay Staff",
      password,
      capabilities: [CAPABILITIES.CASE_READ, CAPABILITIES.CASE_WRITE],
    });
    assert.equal(result.idempotentReplay, false);
    const userSnap = await db.collection("users").doc(result.accountUid).get();
    assert.equal(userSnap.data()?.role, "barangay");
    assert.equal(userSnap.data()?.active, true);
    const mSnap = await db
      .collection("organizationMemberships")
      .doc(result.membershipId)
      .get();
    assert.equal(mSnap.data()?.status, "active");
    assert.ok(mSnap.data()?.capabilities.includes(CAPABILITIES.CASE_READ));

    const authUser = await auth.getUserByEmail(email);
    assert.ok(authUser.uid);
  });

  it("SP-02 moph org admin creates hospital staff", async () => {
    const hospitalAdminUid = "hospitalOrgAdminUid12345678901";
    const email = "new.moph.staff@sibol.local";
    const result = await runProvisionStaffMember(db, auth, hospitalAdminUid, {
      orgId: hospitalOrgId,
      email,
      displayName: "New MOPH Staff",
      password: "MophPass123!",
      capabilities: [CAPABILITIES.COORDINATION_HOSPITAL],
    });
    const userSnap = await db.collection("users").doc(result.accountUid).get();
    assert.equal(userSnap.data()?.role, "moph");
    const mSnap = await db
      .collection("organizationMemberships")
      .doc(result.membershipId)
      .get();
    assert.ok(
      mSnap.data()?.capabilities.includes(CAPABILITIES.COORDINATION_HOSPITAL),
    );
  });

  it("SP-03 ordinary staff cannot provision", async () => {
    await expectDenied(
      () =>
        runProvisionStaffMember(db, auth, ordinaryStaffUid, {
          orgId: barangayOrgId,
          email: "blocked.staff@sibol.local",
          displayName: "Blocked",
          password: "Blocked123!",
          capabilities: [CAPABILITIES.CASE_READ],
        }),
      "permission-denied",
    );
  });

  it("SP-04 cross-org provisioning denied", async () => {
    await expectDenied(
      () =>
        runProvisionStaffMember(db, auth, barangayAdminUid, {
          orgId: hospitalOrgId,
          email: "cross.org@sibol.local",
          displayName: "Cross Org",
          password: "CrossOrg123!",
          capabilities: [CAPABILITIES.COORDINATION_HOSPITAL],
        }),
      "permission-denied",
    );
  });

  it("SP-05 cannot assign org management capabilities", async () => {
    await expectDenied(
      () =>
        runProvisionStaffMember(db, auth, barangayAdminUid, {
          orgId: barangayOrgId,
          email: "escalation@sibol.local",
          displayName: "Escalation",
          password: "Escalate123!",
          capabilities: [CAPABILITIES.ORG_MANAGE_MEMBERS],
        }),
      "permission-denied",
    );
  });

  it("SP-07 duplicate email rejected", async () => {
    const email = "duplicate.staff@sibol.local";
    await runProvisionStaffMember(db, auth, barangayAdminUid, {
      orgId: barangayOrgId,
      email,
      displayName: "First",
      password: "Duplicate123!",
      capabilities: [CAPABILITIES.CASE_READ],
    });
    await expectDenied(
      () =>
        runProvisionStaffMember(db, auth, barangayAdminUid, {
          orgId: barangayOrgId,
          email,
          displayName: "Second",
          password: "Duplicate234!",
          capabilities: [CAPABILITIES.CASE_READ, CAPABILITIES.CASE_WRITE],
        }),
      "already-exists",
    );
  });

  it("SP-07 idempotent clientOperationId replay", async () => {
    const email = "idempotent.staff@sibol.local";
    const opId = "client-op-idempotent-001";
    const first = await runProvisionStaffMember(db, auth, barangayAdminUid, {
      orgId: barangayOrgId,
      email,
      displayName: "Idempotent",
      password: "Idempotent123!",
      capabilities: [CAPABILITIES.CASE_READ],
      clientOperationId: opId,
    });
    const second = await runProvisionStaffMember(db, auth, barangayAdminUid, {
      orgId: barangayOrgId,
      email,
      displayName: "Idempotent",
      password: "Idempotent123!",
      capabilities: [CAPABILITIES.CASE_READ],
      clientOperationId: opId,
    });
    assert.equal(second.accountUid, first.accountUid);
    assert.equal(second.idempotentReplay, true);
  });
});
