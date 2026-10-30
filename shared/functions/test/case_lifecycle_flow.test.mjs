import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { runOpenBarangayCaseFromAssistance } from "../lib/cases/openBarangayCaseFromAssistance.js";
import { runTransitionBarangayCaseStatus } from "../lib/cases/transitionBarangayCaseStatus.js";
import { runCreateCoordinationReferral } from "../lib/coordination/createCoordinationReferral.js";
import { runUpdateMophCoordinationStatus } from "../lib/coordination/updateMophCoordinationStatus.js";
import { runBarangayRespondToMophInformationRequest } from "../lib/coordination/barangayRespondToMophInformationRequest.js";
import { assertFunctionsIntegrationEmulatorEnv } from "./helpers/emulator_env_guard.mjs";
import {
  hospitalOrgId,
  membershipDoc,
  orgId,
  seedAcknowledgedAssistance,
  seedBaseOrgs,
  site,
} from "./helpers/coordination_seed.mjs";

const projectId = "demo-sibol-case-flow-fn";
const teenUid = "teenFlowUid1234567890123456";
const barangayUid = "barangayFlowUid1234567890123";
const mophUid = "mophFlowUid12345678901234567";
const wrongMophUid = "wrongMophUid1234567890123456";
const assistanceId = "assist-lifecycle-flow-001";

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
    displayName: "Flow Teen",
    active: true,
    assignedBarangay: site,
    dateOfBirth: "2008-03-01",
    createdAt: now,
  });
  await db.collection("users").doc(barangayUid).set({
    role: "barangay",
    displayName: "Flow BNS",
    active: true,
    assignedBarangay: site,
    primaryOrgId: orgId,
    createdAt: now,
  });
  await db.collection("users").doc(mophUid).set({
    role: "moph",
    displayName: "Flow MOPH",
    active: true,
    primaryOrgId: hospitalOrgId,
    createdAt: now,
  });
  await db.collection("users").doc(wrongMophUid).set({
    role: "moph",
    displayName: "Wrong Hospital MOPH",
    active: true,
    primaryOrgId: "hospital99",
    createdAt: now,
  });
  await db.collection("organizations").doc("hospital99").set({
    orgId: "hospital99",
    type: "hospital",
    name: "Other Hospital",
    status: "active",
    createdAt: now,
    updatedAt: now,
  });
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${orgId}__${barangayUid}`)
    .set(
      membershipDoc(orgId, barangayUid, [
        "case.write",
        "case.read",
        "coordination.barangay",
      ]),
    );
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${hospitalOrgId}__${mophUid}`)
    .set(membershipDoc(hospitalOrgId, mophUid, ["coordination.hospital"]));
  await db
    .collection("organizationMemberships")
    .doc(`mbr_hospital99__${wrongMophUid}`)
    .set(
      membershipDoc("hospital99", wrongMophUid, ["coordination.hospital"]),
    );
  await seedAcknowledgedAssistance(db, assistanceId, { teenUid, barangayUid });
});

after(async () => {
  for (const app of getApps()) {
    await deleteApp(app);
  }
});

describe("CASE-LIFECYCLE-001 emulator flow", () => {
  it("runs open → referral → MOPH/Barangay coordination → resolve/close with audit", async () => {
    const open = await runOpenBarangayCaseFromAssistance(db, barangayUid, {
      assistanceRequestId: assistanceId,
      idempotencyKey: "flow-open-1",
    });
    assert.ok(open.caseId);

    await runTransitionBarangayCaseStatus(db, barangayUid, {
      caseId: open.caseId,
      targetStatus: "inProgress",
    });

    const referral = await runCreateCoordinationReferral(db, barangayUid, {
      assistanceRequestId: assistanceId,
      barangayReferralSummary:
        "Fictional summary for hospital coordination without teen identifiers.",
    });
    assert.ok(referral.threadId);

    await runUpdateMophCoordinationStatus(db, mophUid, {
      threadId: referral.threadId,
      targetStatus: "received",
    });
    await runUpdateMophCoordinationStatus(db, mophUid, {
      threadId: referral.threadId,
      targetStatus: "additionalInformationRequested",
      note: "Please confirm barangay follow-up schedule.",
    });

    await runBarangayRespondToMophInformationRequest(db, barangayUid, {
      threadId: referral.threadId,
      responseSummary:
        "Fictional administrative response with sufficient detail for MOPH.",
    });

    await runUpdateMophCoordinationStatus(db, mophUid, {
      threadId: referral.threadId,
      targetStatus: "coordinationCompleted",
    });

    await runTransitionBarangayCaseStatus(db, barangayUid, {
      caseId: open.caseId,
      targetStatus: "resolved",
      resolutionSummary:
        "Fictional resolution after hospital coordination completed.",
    });
    await runTransitionBarangayCaseStatus(db, barangayUid, {
      caseId: open.caseId,
      targetStatus: "closed",
      closureReason: "Service coordination finished for demonstration.",
      closureNotes:
        "Case closed after terminal hospital coordination status recorded.",
    });

    const caseSnap = await db.collection("cases").doc(open.caseId).get();
    assert.equal(caseSnap.data()?.caseStatus, "closed");

    const events = await db
      .collection("cases")
      .doc(open.caseId)
      .collection("lifecycleEvents")
      .get();
    assert.ok(events.size >= 3);

    const threadSnap = await db
      .collection("caseCoordinationThreads")
      .doc(referral.threadId)
      .get();
    assert.equal(threadSnap.data()?.coordinationStatus, "coordinationCompleted");
  });

  it("rejects cross-hospital MOPH status update", async () => {
    const assistAuthz = "assist-lifecycle-authz-002";
    await seedAcknowledgedAssistance(db, assistAuthz, { teenUid, barangayUid });
    const referral = await runCreateCoordinationReferral(db, barangayUid, {
      assistanceRequestId: assistAuthz,
      barangayReferralSummary:
        "Fictional referral for cross-hospital authorization testing.",
    });
    await assert.rejects(
      () =>
        runUpdateMophCoordinationStatus(db, wrongMophUid, {
          threadId: referral.threadId,
          targetStatus: "received",
        }),
      (err) => {
        assert.ok(err instanceof HttpsError);
        assert.equal(err.code, "permission-denied");
        return true;
      },
    );
  });
});
