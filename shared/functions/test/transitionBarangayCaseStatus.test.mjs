import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { runTransitionBarangayCaseStatus } from "../lib/cases/transitionBarangayCaseStatus.js";
import { assertFunctionsIntegrationEmulatorEnv } from "./helpers/emulator_env_guard.mjs";
import {
  membershipDoc,
  orgId,
  seedAcknowledgedAssistance,
  seedBaseOrgs,
  site,
} from "./helpers/coordination_seed.mjs";

const projectId = "demo-sibol-case-transition-fn";
const teenUid = "teenCaseTransUid1234567890123";
const barangayUid = "barangayCaseTransUid1234567890";
const assistanceId = "assist-trans-case-001";
const threadId = "thread-block-close-001";

let db;
let caseId;

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
    displayName: "Fictional Teen",
    active: true,
    assignedBarangay: site,
    dateOfBirth: "2008-06-15",
    createdAt: now,
  });
  await db.collection("users").doc(barangayUid).set({
    role: "barangay",
    displayName: "Barangay Staff",
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

  const { runOpenBarangayCaseFromAssistance } = await import(
    "../lib/cases/openBarangayCaseFromAssistance.js"
  );
  const opened = await runOpenBarangayCaseFromAssistance(db, barangayUid, {
    assistanceRequestId: assistanceId,
    idempotencyKey: `seed-open-${Date.now()}`,
  });
  caseId = opened.caseId;

  await db.collection("barangayCoordinationRegistry").doc(assistanceId).set({
    threadId,
    orgId,
    createdAt: now,
  });
  await db.collection("caseCoordinationThreads").doc(threadId).set({
    orgId,
    assistanceRequestId: assistanceId,
    coordinationStatus: "received",
    phase: "submitted",
    createdAt: now,
  });
});

after(async () => {
  for (const app of getApps()) {
    await deleteApp(app);
  }
});

describe("transitionBarangayCaseStatus", () => {
  it("blocks close while referral coordination is non-terminal", async () => {
    await assert.rejects(
      () =>
        runTransitionBarangayCaseStatus(db, barangayUid, {
          caseId,
          targetStatus: "closed",
          closureReason: "resolved",
          closureNotes: "Attempted close with active referral in progress.",
        }),
      (err) => {
        assert.ok(err instanceof HttpsError);
        assert.equal(err.code, "failed-precondition");
        return true;
      },
    );
  });

  it("allows transition to inProgress", async () => {
    const result = await runTransitionBarangayCaseStatus(db, barangayUid, {
      caseId,
      targetStatus: "inProgress",
    });
    assert.equal(result.caseStatus, "inProgress");
    const snap = await db.collection("cases").doc(caseId).get();
    assert.equal(snap.data()?.caseStatus, "inProgress");
  });
});
