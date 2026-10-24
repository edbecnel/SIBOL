import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { runCreateCoordinationReferral } from "../lib/coordination/createCoordinationReferral.js";
import {
  membershipDoc,
  orgId,
  otherOrgId,
  seedAcknowledgedAssistance,
  seedBaseOrgs,
  site,
} from "./helpers/coordination_seed.mjs";

const projectId = "demo-sibol-coord-fn";
const barangayUid = "barangayStaffUid123456789012";
const noMemberUid = "barangayNoMembershipUid123456";
const suspendedMemberUid = "barangaySuspendedMemUid1234567";
const wrongCapUid = "barangayWrongCapUid12345678901";
const inactiveUid = "barangayInactiveStaffUid1234567";
const teenUid = "teenUserUid123456789012345";
const mophUid = "mophStaffUid1234567890123456";
const otherBnsUid = "otherBarangayStaffUid12345678901";

const summary =
  "Fictional barangay summary for authorization regression testing.";

let db;

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST must be set by emulators:exec");
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  const now = new Date();
  const userBase = { displayName: "Demo", createdAt: now, assignedBarangay: site };
  await db.collection("users").doc(barangayUid).set({
    ...userBase,
    role: "barangay",
    active: true,
  });
  await db.collection("users").doc(noMemberUid).set({
    ...userBase,
    role: "barangay",
    active: true,
  });
  await db.collection("users").doc(suspendedMemberUid).set({
    ...userBase,
    role: "barangay",
    active: true,
  });
  await db.collection("users").doc(wrongCapUid).set({
    ...userBase,
    role: "barangay",
    active: true,
  });
  await db.collection("users").doc(inactiveUid).set({
    ...userBase,
    role: "barangay",
    active: false,
  });
  await db.collection("users").doc(teenUid).set({ ...userBase, role: "teen", active: true });
  await db.collection("users").doc(mophUid).set({ ...userBase, role: "moph", active: true });
  await db.collection("users").doc(otherBnsUid).set({
    ...userBase,
    role: "barangay",
    active: true,
    assignedBarangay: "Other Demo Barangay",
  });

  await seedBaseOrgs(db);
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${orgId}__${barangayUid}`)
    .set(membershipDoc(orgId, barangayUid, ["coordination.barangay"]));
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${otherOrgId}__${otherBnsUid}`)
    .set(membershipDoc(otherOrgId, otherBnsUid, ["coordination.barangay"]));
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${orgId}__${suspendedMemberUid}`)
    .set(membershipDoc(orgId, suspendedMemberUid, ["coordination.barangay"], "suspended"));
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${orgId}__${wrongCapUid}`)
    .set(membershipDoc(orgId, wrongCapUid, ["case.read", "case.write"]));

  const suspendedOrg = "org5555555555555555555555";
  await db.collection("organizations").doc(suspendedOrg).set({
    orgId: suspendedOrg,
    type: "barangay",
    name: "Suspended",
    status: "suspended",
    createdAt: now,
    updatedAt: now,
  });
});

after(async () => {
  for (const app of getApps()) {
    await deleteApp(app);
  }
});

describe("createCoordinationReferral org authorization", () => {
  it("rejects barangay without membership", async () => {
    const id = "assist-no-membership";
    await seedAcknowledgedAssistance(db, id, { teenUid, barangayUid });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, noMemberUid, {
          assistanceRequestId: id,
          barangayReferralSummary: summary,
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects suspended membership", async () => {
    const id = "assist-suspended-member";
    await seedAcknowledgedAssistance(db, id, { teenUid, barangayUid: suspendedMemberUid });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, suspendedMemberUid, {
          assistanceRequestId: id,
          barangayReferralSummary: summary,
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects missing coordination.barangay capability", async () => {
    const id = "assist-wrong-cap";
    await seedAcknowledgedAssistance(db, id, { teenUid, barangayUid: wrongCapUid });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, wrongCapUid, {
          assistanceRequestId: id,
          barangayReferralSummary: summary,
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects inactive account", async () => {
    const id = "assist-inactive-account";
    await seedAcknowledgedAssistance(db, id, { teenUid, barangayUid });
    await db
      .collection("organizationMemberships")
      .doc(`mbr_${orgId}__${inactiveUid}`)
      .set(membershipDoc(orgId, inactiveUid, ["coordination.barangay"]));
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, inactiveUid, {
          assistanceRequestId: id,
          barangayReferralSummary: summary,
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects assistance without orgId", async () => {
    const id = "assist-missing-org";
    const now = new Date();
    await db.collection("teenAssistanceRequests").doc(id).set({
      teenUid,
      barangay: site,
      category: "generalSupport",
      description: "Missing org scope.",
      status: "acknowledged",
      createdAt: now,
      acknowledgedAt: now,
      acknowledgedByUid: barangayUid,
    });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, barangayUid, {
          assistanceRequestId: id,
          barangayReferralSummary: summary,
        }),
      (err) => err.code === "failed-precondition",
    );
  });

  it("rejects forged org (assistance org not matching membership scope)", async () => {
    const id = "assist-forged-org";
    await seedAcknowledgedAssistance(db, id, {
      teenUid,
      barangayUid,
      org: otherOrgId,
    });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, barangayUid, {
          assistanceRequestId: id,
          barangayReferralSummary: summary,
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects suspended organization on assistance orgId", async () => {
    const suspendedOrg = "org5555555555555555555555";
    const id = "assist-suspended-org";
    await seedAcknowledgedAssistance(db, id, {
      teenUid,
      barangayUid,
      org: suspendedOrg,
    });
    await db
      .collection("organizationMemberships")
      .doc(`mbr_${suspendedOrg}__${barangayUid}`)
      .set(membershipDoc(suspendedOrg, barangayUid, ["coordination.barangay"]));
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, barangayUid, {
          assistanceRequestId: id,
          barangayReferralSummary: summary,
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects MOPH caller (no referral create)", async () => {
    const id = "assist-moph-deny";
    await seedAcknowledgedAssistance(db, id, { teenUid, barangayUid });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, mophUid, {
          assistanceRequestId: id,
          barangayReferralSummary: summary,
        }),
      (err) => err.code === "permission-denied",
    );
  });
});
