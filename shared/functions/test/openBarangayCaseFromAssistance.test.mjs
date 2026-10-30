import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { runOpenBarangayCaseFromAssistance } from "../lib/cases/openBarangayCaseFromAssistance.js";
import { assertFunctionsIntegrationEmulatorEnv } from "./helpers/emulator_env_guard.mjs";
import {
  membershipDoc,
  orgId,
  seedAcknowledgedAssistance,
  seedBaseOrgs,
  site,
} from "./helpers/coordination_seed.mjs";

const projectId = "demo-sibol-case-open-fn";
const teenUid = "teenCaseOpenUid1234567890123";
const barangayUid = "barangayCaseOpenUid12345678901";
const assistanceId = "assist-open-case-001";
const assistanceReplayId = "assist-open-case-replay";
const assistanceConcurrentId = "assist-open-case-concurrent";

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
  await seedAcknowledgedAssistance(db, assistanceReplayId, {
    teenUid,
    barangayUid,
  });
  await seedAcknowledgedAssistance(db, assistanceConcurrentId, {
    teenUid,
    barangayUid,
  });
});

after(async () => {
  for (const app of getApps()) {
    await deleteApp(app);
  }
});

describe("openBarangayCaseFromAssistance", () => {
  it("creates case, binding, and lifecycle event", async () => {
    const key = `open-${Date.now()}`;
    const result = await runOpenBarangayCaseFromAssistance(db, barangayUid, {
      assistanceRequestId: assistanceId,
      idempotencyKey: key,
    });
    assert.ok(result.caseId);
    assert.equal(result.assistanceRequestId, assistanceId);
    assert.equal(result.idempotent, false);

    const binding = (
      await db.collection("assistanceCaseBindings").doc(assistanceId).get()
    ).data();
    assert.equal(binding?.caseId, result.caseId);

    const caseSnap = await db.collection("cases").doc(result.caseId).get();
    assert.equal(caseSnap.data()?.caseStatus, "open");
    assert.equal(caseSnap.data()?.assistanceRequestId, assistanceId);

    const events = await db
      .collection("cases")
      .doc(result.caseId)
      .collection("lifecycleEvents")
      .get();
    assert.ok(events.size >= 1);
  });

  it("returns same case on idempotency replay", async () => {
    const key = `open-replay-${Date.now()}`;
    const first = await runOpenBarangayCaseFromAssistance(db, barangayUid, {
      assistanceRequestId: assistanceReplayId,
      idempotencyKey: key,
    });
    const second = await runOpenBarangayCaseFromAssistance(db, barangayUid, {
      assistanceRequestId: assistanceReplayId,
      idempotencyKey: key,
    });
    assert.equal(second.caseId, first.caseId);
    assert.equal(second.idempotent, true);
  });

  it("concurrent open attempts resolve to one case", async () => {
    const key = `concurrent-${Date.now()}`;
    const results = await Promise.all(
      Array.from({ length: 5 }, () =>
        runOpenBarangayCaseFromAssistance(db, barangayUid, {
          assistanceRequestId: assistanceConcurrentId,
          idempotencyKey: key,
        }),
      ),
    );
    const caseIds = new Set(results.map((r) => r.caseId));
    assert.equal(caseIds.size, 1);
    const binding = (
      await db.collection("assistanceCaseBindings").doc(assistanceConcurrentId).get()
    ).data();
    assert.equal(binding?.caseId, results[0].caseId);
  });
});
