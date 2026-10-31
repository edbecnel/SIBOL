import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { Timestamp } from "firebase/firestore";
import {
  CAPS,
  ORG_BARANGAY_DEMO,
  ORG_HOSPITAL_DEMO,
  setupM2DemoAuth,
} from "./helpers/org_auth_seed.mjs";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");

const projectId = "demo-sibol-rules";
const barangayUid = "barangay-user-1";
const teenUid = "teen-user-1";
const teenUid2 = "teen-user-2";
const mophUid = "moph-user-1";
const authId = "disclosure-auth-1";
const assistanceRequestId = "assist-req-disclosure-1";
const threadId = "coord-thread-disclosure-1";
const site = "Barangay 3, Balingasag";
const now = Timestamp.fromDate(new Date("2026-11-01T12:00:00Z"));

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const userBase = {
      displayName: "Demo",
      active: true,
      createdAt: new Date(),
      assignedBarangay: site,
    };
    await db.collection("users").doc(barangayUid).set({
      ...userBase,
      role: "barangay",
      primaryOrgId: ORG_BARANGAY_DEMO,
    });
    await db.collection("users").doc(teenUid).set({
      ...userBase,
      role: "teen",
    });
    await db.collection("users").doc(teenUid2).set({
      ...userBase,
      role: "teen",
    });
    await db.collection("users").doc(mophUid).set({
      ...userBase,
      role: "moph",
      primaryOrgId: ORG_HOSPITAL_DEMO,
    });
    await setupM2DemoAuth(db, { barangayUid, teenUid, teenUid2, mophUid, site });
    await db.collection("disclosureAuthorizations").doc(authId).set({
      assistanceRequestId,
      teenUid,
      orgId: ORG_BARANGAY_DEMO,
      targetHospitalOrgId: ORG_HOSPITAL_DEMO,
      purposeCode: "hospital_coordination",
      requestedCategories: ["legal_name"],
      authorizedCategories: ["legal_name"],
      status: "approved",
      requestedAt: now,
      decidedAt: now,
    });
    await db.collection("caseCoordinationThreads").doc(threadId).set({
      barangay: site,
      orgId: ORG_BARANGAY_DEMO,
      targetHospitalOrgId: ORG_HOSPITAL_DEMO,
      displayRef: "SIBOL-REF-RULES-001",
      category: "generalSupport",
      barangayReferralSummary: "Server-generated structured summary.",
      structuredReferral: true,
      disclosureMode: "authorized",
      phase: "referred",
      createdAt: now,
      updatedAt: now,
      lastStaffEventAt: now,
      createdByUid: barangayUid,
    });
    await db
      .collection("caseCoordinationThreads")
      .doc(threadId)
      .collection("authorizedDisclosure")
      .doc("profile")
      .set({
        legalName: "Fictional Teen",
        categoryCodes: ["legal_name"],
        authorizationId: authId,
        createdAt: now,
      });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("disclosureAuthorizations reads", () => {
  it("allows teen to read own authorization", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertSucceeds(
      db.collection("disclosureAuthorizations").doc(authId).get(),
    );
  });

  it("denies other teen reading authorization", async () => {
    const db = testEnv.authenticatedContext(teenUid2).firestore();
    await assertFails(
      db.collection("disclosureAuthorizations").doc(authId).get(),
    );
  });

  it("allows barangay with coordination.barangay on org", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      db.collection("disclosureAuthorizations").doc(authId).get(),
    );
  });

  it("denies MOPH read of authorization documents", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(
      db.collection("disclosureAuthorizations").doc(authId).get(),
    );
  });
});

describe("disclosureAuthorizations writes", () => {
  it("denies teen client create", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db.collection("disclosureAuthorizations").doc("forged").set({
        teenUid,
        status: "approved",
        orgId: ORG_BARANGAY_DEMO,
      }),
    );
  });

  it("denies barangay client update of decision", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db.collection("disclosureAuthorizations").doc(authId).update({
        status: "approved",
        authorizedCategories: ["legal_name", "contact_email"],
      }),
    );
  });
});

describe("authorizedDisclosure profile reads", () => {
  it("allows MOPH read of authorized profile on hospital thread", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertSucceeds(
      db
        .collection("caseCoordinationThreads")
        .doc(threadId)
        .collection("authorizedDisclosure")
        .doc("profile")
        .get(),
    );
  });

  it("denies teen read of authorized profile subdocument", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db
        .collection("caseCoordinationThreads")
        .doc(threadId)
        .collection("authorizedDisclosure")
        .doc("profile")
        .get(),
    );
  });
});
