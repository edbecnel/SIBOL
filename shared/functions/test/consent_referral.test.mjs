import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { runCreateCoordinationReferral } from "../lib/coordination/createCoordinationReferral.js";
import { runRequestMophDisclosureAuthorization } from "../lib/disclosure/requestMophDisclosureAuthorization.js";
import { runRecordTeenDisclosureDecision } from "../lib/disclosure/recordTeenDisclosureDecision.js";
import { runWithdrawDisclosureAuthorization } from "../lib/disclosure/withdrawDisclosureAuthorization.js";
import { runOpenBarangayCaseFromAssistance } from "../lib/cases/openBarangayCaseFromAssistance.js";
import { runUpdateMophCoordinationStatus } from "../lib/coordination/updateMophCoordinationStatus.js";
import { runBarangayRespondToMophInformationRequest } from "../lib/coordination/barangayRespondToMophInformationRequest.js";
import {
  authorizedStructuredReferral,
  minimumStructuredReferral,
  structuredInformationResponse,
} from "./helpers/structured_referral.mjs";
import {
  membershipDoc,
  orgId,
  seedAcknowledgedAssistance,
  seedBaseOrgs,
  site,
  hospitalOrgId,
} from "./helpers/coordination_seed.mjs";

const projectId = "demo-sibol-coord-fn";
const teenUid = "teenConsentUid123456789012345";
const barangayUid = "barangayConsentUid1234567890123";
const mophUid = "mophConsentUid1234567890123456";
const assistanceMin = "assist-consent-min-001";
const assistanceAuth = "assist-consent-auth-001";
const assistanceDecline = "assist-consent-decline-001";

let db;

before(async () => {
  if (process.env.FIREBASE_PROJECT_ID === "sibol-286d0") {
    throw new Error("Refusing production project");
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  const now = Timestamp.now();
  await seedBaseOrgs(db);
  await db.collection("users").doc(teenUid).set({
    role: "teen",
    displayName: "Consent Teen",
    active: true,
    assignedBarangay: site,
    dateOfBirth: "2008-04-15",
    contactEmail: "consent.teen@sibol.local",
    contactPhone: "+639170000001",
    createdAt: now,
  });
  await db.collection("users").doc(barangayUid).set({
    role: "barangay",
    displayName: "Consent BNS",
    active: true,
    assignedBarangay: site,
    primaryOrgId: orgId,
    createdAt: now,
  });
  await db.collection("users").doc(mophUid).set({
    role: "moph",
    displayName: "Consent MOPH",
    active: true,
    primaryOrgId: hospitalOrgId,
    createdAt: now,
  });
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${orgId}__${barangayUid}`)
    .set(
      membershipDoc(orgId, barangayUid, [
        "coordination.barangay",
        "case.write",
        "case.read",
      ]),
    );
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${hospitalOrgId}__${mophUid}`)
    .set(membershipDoc(hospitalOrgId, mophUid, ["coordination.hospital"]));

  await seedAcknowledgedAssistance(db, assistanceMin, { teenUid, barangayUid });
  await seedAcknowledgedAssistance(db, assistanceAuth, { teenUid, barangayUid });
  await seedAcknowledgedAssistance(db, assistanceDecline, { teenUid, barangayUid });
});

after(async () => {
  for (const app of getApps()) {
    await deleteApp(app);
  }
});

describe("SIBOL-CONSENT-REFERRAL-001", () => {
  it("rejects legacy barangayReferralSummary (C1)", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, barangayUid, {
          assistanceRequestId: "missing",
          barangayReferralSummary: "Legacy free text must be rejected now.",
        }),
      (err) => err.code === "invalid-argument",
    );
  });

  it("creates minimum structured referral without authorization", async () => {
    const result = await runCreateCoordinationReferral(
      db,
      barangayUid,
      minimumStructuredReferral(assistanceMin),
    );
    assert.equal(result.disclosureMode, "minimum");
    const header = (
      await db.collection("caseCoordinationThreads").doc(result.threadId).get()
    ).data();
    assert.equal(header.structuredReferral, true);
    assert.equal(header.disclosureMode, "minimum");
  });

  it("runs authorization approve and authorized referral when legal gate on", async () => {
    const req = await runRequestMophDisclosureAuthorization(db, barangayUid, {
      assistanceRequestId: assistanceAuth,
      purposeCode: "hospital_coordination",
      requestedCategories: ["legal_name", "contact_email"],
    });
    const decision = await runRecordTeenDisclosureDecision(db, teenUid, {
      authorizationId: req.authorizationId,
      decision: "approved",
    });
    assert.equal(decision.status, "approved");

    const referral = await runCreateCoordinationReferral(
      db,
      barangayUid,
      authorizedStructuredReferral(assistanceAuth, req.authorizationId),
    );
    assert.equal(referral.disclosureMode, "authorized");
    const profile = (
      await db
        .collection("caseCoordinationThreads")
        .doc(referral.threadId)
        .collection("authorizedDisclosure")
        .doc("profile")
        .get()
    ).data();
    assert.equal(profile.legalName, "Consent Teen");
    assert.equal(profile.contactEmail, "consent.teen@sibol.local");

    await runUpdateMophCoordinationStatus(db, mophUid, {
      threadId: referral.threadId,
      targetStatus: "received",
    });

    await runOpenBarangayCaseFromAssistance(db, barangayUid, {
      assistanceRequestId: assistanceAuth,
      idempotencyKey: "consent-case-open-1",
    });

    await runUpdateMophCoordinationStatus(db, mophUid, {
      threadId: referral.threadId,
      targetStatus: "additionalInformationRequested",
    });

    await runBarangayRespondToMophInformationRequest(
      db,
      barangayUid,
      structuredInformationResponse(referral.threadId, {
        template: "administrative_update",
      }),
    );
  });

  it("allows minimum referral after teen declines authorization", async () => {
    const req = await runRequestMophDisclosureAuthorization(db, barangayUid, {
      assistanceRequestId: assistanceDecline,
      purposeCode: "hospital_coordination",
      requestedCategories: ["legal_name"],
    });
    await runRecordTeenDisclosureDecision(db, teenUid, {
      authorizationId: req.authorizationId,
      decision: "declined",
    });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(
          db,
          barangayUid,
          authorizedStructuredReferral(assistanceDecline, req.authorizationId),
        ),
      (err) => err.code === "failed-precondition",
    );
    const min = await runCreateCoordinationReferral(
      db,
      barangayUid,
      minimumStructuredReferral(assistanceDecline),
    );
    assert.equal(min.disclosureMode, "minimum");
  });

  it("blocks authorized referral when legal gate off", async () => {
    const prior = process.env.SIBOL_DISCLOSURE_LEGAL_GATE;
    process.env.SIBOL_DISCLOSURE_LEGAL_GATE = "false";
    const assistId = "assist-consent-gate-off";
    await seedAcknowledgedAssistance(db, assistId, { teenUid, barangayUid });
    const req = await runRequestMophDisclosureAuthorization(db, barangayUid, {
      assistanceRequestId: assistId,
      purposeCode: "hospital_coordination",
      requestedCategories: ["legal_name"],
    });
    await runRecordTeenDisclosureDecision(db, teenUid, {
      authorizationId: req.authorizationId,
      decision: "approved",
    });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(
          db,
          barangayUid,
          authorizedStructuredReferral(assistId, req.authorizationId),
        ),
      (err) => err.message.includes("not legally activated"),
    );
    process.env.SIBOL_DISCLOSURE_LEGAL_GATE = prior;
  });

  it("rejects teen approving another teen authorization", async () => {
    const otherTeen = "otherTeenConsentUid1234567890";
    const assistId = "assist-consent-other-teen";
    await db.collection("users").doc(otherTeen).set({
      role: "teen",
      displayName: "Other Teen",
      active: true,
      assignedBarangay: site,
      createdAt: Timestamp.now(),
    });
    await seedAcknowledgedAssistance(db, assistId, {
      teenUid: otherTeen,
      barangayUid,
    });
    const req = await runRequestMophDisclosureAuthorization(db, barangayUid, {
      assistanceRequestId: assistId,
      purposeCode: "hospital_coordination",
      requestedCategories: ["legal_name"],
    });
    await assert.rejects(
      () =>
        runRecordTeenDisclosureDecision(db, teenUid, {
          authorizationId: req.authorizationId,
          decision: "approved",
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects authorized referral when authorization expired", async () => {
    const assistId = "assist-consent-expired-1";
    await seedAcknowledgedAssistance(db, assistId, { teenUid, barangayUid });
    const req = await runRequestMophDisclosureAuthorization(db, barangayUid, {
      assistanceRequestId: assistId,
      purposeCode: "hospital_coordination",
      requestedCategories: ["legal_name"],
    });
    await runRecordTeenDisclosureDecision(db, teenUid, {
      authorizationId: req.authorizationId,
      decision: "approved",
    });
    await db
      .collection("disclosureAuthorizations")
      .doc(req.authorizationId)
      .update({
        validUntil: Timestamp.fromDate(new Date(Date.now() - 60_000)),
      });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(
          db,
          barangayUid,
          authorizedStructuredReferral(assistId, req.authorizationId),
        ),
      (err) => err.code === "failed-precondition",
    );
  });

  it("rejects authorized referral when authorization superseded", async () => {
    const assistId = "assist-consent-superseded-1";
    await seedAcknowledgedAssistance(db, assistId, { teenUid, barangayUid });
    const req = await runRequestMophDisclosureAuthorization(db, barangayUid, {
      assistanceRequestId: assistId,
      purposeCode: "hospital_coordination",
      requestedCategories: ["legal_name"],
    });
    await runRecordTeenDisclosureDecision(db, teenUid, {
      authorizationId: req.authorizationId,
      decision: "approved",
    });
    await db
      .collection("disclosureAuthorizations")
      .doc(req.authorizationId)
      .update({ status: "superseded" });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(
          db,
          barangayUid,
          authorizedStructuredReferral(assistId, req.authorizationId),
        ),
      (err) => err.code === "failed-precondition",
    );
  });

  it("rejects legacy responseSummary on information response", async () => {
    const assistId = "assist-consent-resp-legacy";
    await seedAcknowledgedAssistance(db, assistId, { teenUid, barangayUid });
    const referral = await runCreateCoordinationReferral(
      db,
      barangayUid,
      minimumStructuredReferral(assistId),
    );
    await runUpdateMophCoordinationStatus(db, mophUid, {
      threadId: referral.threadId,
      targetStatus: "additionalInformationRequested",
    });
    await assert.rejects(
      () =>
        runBarangayRespondToMophInformationRequest(db, barangayUid, {
          threadId: referral.threadId,
          responseSummary: "Legacy free text must be rejected.",
        }),
      (err) => err.code === "invalid-argument",
    );
  });

  it("withdrawal blocks subsequent authorized disclosure on new referral id", async () => {
    const assistId = "assist-consent-withdraw-1";
    await seedAcknowledgedAssistance(db, assistId, { teenUid, barangayUid });
    const req = await runRequestMophDisclosureAuthorization(db, barangayUid, {
      assistanceRequestId: assistId,
      purposeCode: "hospital_coordination",
      requestedCategories: ["contact_phone"],
    });
    await runRecordTeenDisclosureDecision(db, teenUid, {
      authorizationId: req.authorizationId,
      decision: "approved",
    });
    await runWithdrawDisclosureAuthorization(db, teenUid, {
      authorizationId: req.authorizationId,
    });
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(
          db,
          barangayUid,
          authorizedStructuredReferral(assistId, req.authorizationId),
        ),
      (err) => err.code === "failed-precondition",
    );
  });
});
