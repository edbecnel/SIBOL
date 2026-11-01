import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { runPublishTeenAssistanceCommunication } from "../lib/teenCommunication/publishTeenAssistanceCommunication.js";
import { runConfirmTeenCoordinationOutcome } from "../lib/teenCommunication/confirmTeenCoordinationOutcome.js";
import { runTransitionBarangayCaseStatus } from "../lib/cases/transitionBarangayCaseStatus.js";
import { assertFunctionsIntegrationEmulatorEnv } from "./helpers/emulator_env_guard.mjs";
import {
  membershipDoc,
  orgId,
  seedAcknowledgedAssistance,
  seedBaseOrgs,
  seedCoordinationReferralForAssistance,
  site,
} from "./helpers/coordination_seed.mjs";

const projectId = "demo-sibol-teen-comm-fn";
const teenUid = "teenCommUid1234567890123456";
const barangayUid = "barangayCommUid1234567890123";
const assistanceId = "assist-teen-comm-001";

let db;

before(async () => {
  assertFunctionsIntegrationEmulatorEnv();
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  const now = Timestamp.now();
  await seedBaseOrgs(db);
  await db.collection("users").doc(teenUid).set({
    role: "teen",
    displayName: "Comm Teen",
    active: true,
    assignedBarangay: site,
    dateOfBirth: "2008-01-01",
    createdAt: now,
  });
  await db.collection("users").doc(barangayUid).set({
    role: "barangay",
    displayName: "Comm BNS",
    active: true,
    assignedBarangay: site,
    primaryOrgId: orgId,
    createdAt: now,
  });
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${orgId}__${barangayUid}`)
    .set(membershipDoc(orgId, barangayUid, ["case.write", "case.read"]));
  await seedAcknowledgedAssistance(db, assistanceId, { teenUid, barangayUid });
  await seedCoordinationReferralForAssistance(db, assistanceId, {
    teenUid,
    barangayUid,
    coordinationStatus: "coordinationCompleted",
    threadId: "thread-teen-comm",
  });
  await db.collection("caseCoordinationThreads").doc("thread-teen-comm").update({
    pendingTeenOutcomePublication: true,
  });
});

after(async () => {
  for (const app of getApps()) {
    await deleteApp(app);
  }
});

describe("teen assistance communications", () => {
  it("publishes barangay progress template with idempotency", async () => {
    const key = `progress-${Date.now()}`;
    const first = await runPublishTeenAssistanceCommunication(db, barangayUid, {
      assistanceRequestId: assistanceId,
      templateCode: "coordination_progress_generic",
      idempotencyKey: key,
    });
    const second = await runPublishTeenAssistanceCommunication(db, barangayUid, {
      assistanceRequestId: assistanceId,
      templateCode: "coordination_progress_generic",
      idempotencyKey: key,
    });
    assert.equal(second.messageId, first.messageId);
    assert.equal(second.idempotent, true);
  });

  it("requires terminal coordination before outcome confirmation", async () => {
    await db.collection("caseCoordinationThreads").doc("thread-pending").set({
      barangay: site,
      orgId,
      displayRef: "SIBOL-REF-PENDING",
      category: "generalSupport",
      barangayReferralSummary: "Test",
      referralPurposeCode: "hospital_coordination",
      coordinationNeedCodes: ["schedule_coordination"],
      disclosureMode: "minimum",
      structuredReferral: true,
      phase: "awaitingMoph",
      coordinationStatus: "received",
      targetHospitalOrgId: "hospital01",
      assistanceRequestId: "assist-pending-outcome",
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      lastStaffEventAt: Timestamp.now(),
      createdByUid: barangayUid,
    });
    await db.collection("barangayCoordinationRegistry").doc("assist-pending-outcome").set({
      threadId: "thread-pending",
      orgId,
      teenUid,
      active: true,
      createdAt: Timestamp.now(),
    });
    await seedAcknowledgedAssistance(db, "assist-pending-outcome", {
      teenUid,
      barangayUid,
    });
    await assert.rejects(
      () =>
        runConfirmTeenCoordinationOutcome(db, barangayUid, {
          assistanceRequestId: "assist-pending-outcome",
          idempotencyKey: "outcome-pending",
        }),
      (err) => err.code === "failed-precondition",
    );
  });

  it("confirms terminal outcome for teenager once", async () => {
    const key = `outcome-${Date.now()}`;
    const result = await runConfirmTeenCoordinationOutcome(db, barangayUid, {
      assistanceRequestId: assistanceId,
      idempotencyKey: key,
    });
    assert.ok(result.messageId);
    await assert.rejects(
      () =>
        runConfirmTeenCoordinationOutcome(db, barangayUid, {
          assistanceRequestId: assistanceId,
          idempotencyKey: `${key}-retry`,
        }),
      (err) => err.code === "failed-precondition",
    );
  });
});
