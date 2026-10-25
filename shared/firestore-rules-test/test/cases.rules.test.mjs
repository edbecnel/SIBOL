import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import {
  ORG_BARANGAY_DEMO,
  ORG_BARANGAY_OTHER,
  setupM2DemoAuth,
  seedMembership,
  CAPS,
} from "./helpers/org_auth_seed.mjs";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");

const projectId = "demo-sibol-rules";
const barangayUid = "barangay-user-1";
const barangayUidOther = "barangay-user-2";
const teenUid = "teen-user-1";
const mophUid = "moph-user-1";
const DEMO_BARANGAY = "Barangay Tres, Balingasag";

let testEnv;

function validCase(overrides = {}) {
  const now = new Date();
  return {
    demoName: "Ana Demo",
    age: 16,
    barangay: DEMO_BARANGAY,
    orgId: ORG_BARANGAY_DEMO,
    caseStatus: "active",
    registeredAt: now,
    createdAt: now,
    updatedAt: now,
    reportStatus: "notSubmitted",
    notes: "Fictional",
    ...overrides,
  };
}

/** Mirrors provisioned fictional demo case shape (demo-case-001 style). */
function demoProvisionedCase() {
  const registered = new Date("2026-01-15T08:00:00.000Z");
  const created = new Date("2026-01-15T08:05:00.000Z");
  return {
    demoName: "Bea Demo Santos",
    age: 17,
    barangay: DEMO_BARANGAY,
    orgId: ORG_BARANGAY_DEMO,
    caseStatus: "followUpScheduled",
    registeredAt: registered,
    nextFollowUpAt: new Date("2026-11-06T10:00:00.000Z"),
    notes: "Fictional demonstration record.",
    createdAt: created,
    updatedAt: created,
    reportStatus: "notSubmitted",
  };
}

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
      assignedBarangay: DEMO_BARANGAY,
    };
    await db.collection("users").doc(barangayUid).set({
      ...userBase,
      role: "barangay",
      displayName: "Barangay Demo",
    });
    await db.collection("users").doc(barangayUidOther).set({
      ...userBase,
      role: "barangay",
      assignedBarangay: "Other Demo Barangay",
      displayName: "Other BNS",
    });
    await db.collection("users").doc(teenUid).set({
      ...userBase,
      role: "teen",
      displayName: "Teen Demo",
    });
    await db.collection("users").doc(mophUid).set({
      ...userBase,
      role: "moph",
      displayName: "MOPH Demo",
    });
    await setupM2DemoAuth(db, {
      barangayUid,
      barangayUidOther,
      teenUid,
      mophUid,
    });
    await db.collection("cases").doc("demo-case-read").set(demoProvisionedCase());
    await db
      .collection("cases")
      .doc("demo-case-read")
      .collection("followUps")
      .doc("fu-1")
      .set({
        scheduledAt: new Date("2026-11-06T10:00:00.000Z"),
        notes: "Fictional follow-up",
        createdAt: new Date(),
      });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("cases collection", () => {
  it("allows barangay to create case with notSubmitted reportStatus", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      db.collection("cases").doc("case-create-1").set(validCase()),
    );
  });

  it("allows barangay org-scoped list query for home org", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      db
        .collection("cases")
        .where("orgId", "==", ORG_BARANGAY_DEMO)
        .orderBy("registeredAt", "desc")
        .get(),
    );
  });

  it("denies barangay list query for other org", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db
        .collection("cases")
        .where("orgId", "==", ORG_BARANGAY_OTHER)
        .orderBy("registeredAt", "desc")
        .get(),
    );
  });

  it("allows barangay to create follow-up on authorized case", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      db
        .collection("cases")
        .doc("demo-case-read")
        .collection("followUps")
        .doc("fu-create-1")
        .set({
          caseId: "demo-case-read",
          scheduledAt: new Date("2026-11-07T10:00:00.000Z"),
          completedAt: new Date("2026-11-07T11:00:00.000Z"),
          status: "completed",
          notes: "Fictional home visit documented.",
          createdByUid: barangayUid,
          createdAt: new Date("2026-11-07T11:00:00.000Z"),
        }),
    );
  });

  it("denies teen creating follow-up on case", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db
        .collection("cases")
        .doc("demo-case-read")
        .collection("followUps")
        .doc("fu-teen")
        .set({
          caseId: "demo-case-read",
          scheduledAt: new Date(),
          notes: "teen attempt",
          createdByUid: teenUid,
          createdAt: new Date(),
        }),
    );
  });

  it("allows barangay to read provisioned demo-style case and follow-ups", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(db.collection("cases").doc("demo-case-read").get());
    await assertSucceeds(
      db
        .collection("cases")
        .doc("demo-case-read")
        .collection("followUps")
        .doc("fu-1")
        .get(),
    );
  });

  it("denies unauthenticated read and write on cases", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.collection("cases").doc("demo-case-read").get());
    await assertFails(
      db.collection("cases").doc("case-anon").set(validCase()),
    );
  });

  it("denies teen read and write on cases", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(db.collection("cases").doc("demo-case-read").get());
    await assertFails(
      db.collection("cases").doc("case-teen-write").set(validCase()),
    );
    await assertFails(
      db.collection("cases").doc("demo-case-read").update({ notes: "hack" }),
    );
  });

  it("denies MOPH read, create, and update on cases", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(db.collection("cases").doc("demo-case-read").get());
    await assertFails(
      db.collection("cases").doc("case-moph-create").set(validCase()),
    );
    await assertFails(
      db.collection("cases").doc("demo-case-read").update({ notes: "moph" }),
    );
  });

  it("denies create with pendingSubmit or submitted reportStatus", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db
        .collection("cases")
        .doc("case-pending")
        .set(validCase({ reportStatus: "pendingSubmit" })),
    );
    await assertFails(
      db
        .collection("cases")
        .doc("case-submitted")
        .set(validCase({ reportStatus: "submitted" })),
    );
  });

  it("denies update that changes reportStatus to any other value", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    const caseId = "case-update-report";
    await assertSucceeds(db.collection("cases").doc(caseId).set(validCase()));
    await assertFails(
      db.collection("cases").doc(caseId).update({
        reportStatus: "pendingSubmit",
      }),
    );
    await assertFails(
      db.collection("cases").doc(caseId).update({
        reportStatus: "submitted",
      }),
    );
  });

  it("denies update that changes createdAt", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    const caseId = "case-update-created";
    const payload = validCase();
    await assertSucceeds(db.collection("cases").doc(caseId).set(payload));
    await assertFails(
      db.collection("cases").doc(caseId).update({
        createdAt: new Date(2020, 1, 1),
      }),
    );
  });

  it("allows barangay to update editable fields (full document merge)", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    const caseId = "case-update-ok";
    const payload = validCase();
    await assertSucceeds(db.collection("cases").doc(caseId).set(payload));
    const snap = await db.collection("cases").doc(caseId).get();
    const data = snap.data();
    await assertSucceeds(
      db.collection("cases").doc(caseId).update({
        ...data,
        demoName: "Revised Demo Name",
        updatedAt: new Date(),
      }),
    );
  });

  it("allows barangay partial update of permitted fields without dropping protected data", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    const caseId = "case-partial-update";
    await assertSucceeds(db.collection("cases").doc(caseId).set(validCase()));
    await assertSucceeds(
      db.collection("cases").doc(caseId).update({
        demoName: "Partial Edit",
        updatedAt: new Date(),
      }),
    );
    const before = (await db.collection("cases").doc(caseId).get()).data();
    const after = (await db.collection("cases").doc(caseId).get()).data();
    assert.equal(after.reportStatus, "notSubmitted");
    assert.equal(after.createdAt.toMillis(), before.createdAt.toMillis());
    assert.equal(after.demoName, "Partial Edit");
  });

  it("denies create and update with unexpected fields", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db
        .collection("cases")
        .doc("case-extra-create")
        .set(validCase({ ownerUid: barangayUid })),
    );
    const caseId = "case-extra-update";
    await assertSucceeds(db.collection("cases").doc(caseId).set(validCase()));
    await assertFails(
      db.collection("cases").doc(caseId).update({
        organizationId: "org-1",
      }),
    );
  });

  it("denies case delete for barangay", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    const caseId = "case-no-delete";
    await assertSucceeds(db.collection("cases").doc(caseId).set(validCase()));
    await assertFails(db.collection("cases").doc(caseId).delete());
  });

  it("denies cross-barangay read and write", async () => {
    const otherDb = testEnv.authenticatedContext(barangayUidOther).firestore();
    await assertFails(otherDb.collection("cases").doc("demo-case-read").get());
    await assertFails(
      otherDb.collection("cases").doc("case-cross").set(validCase()),
    );
  });

  it("denies barangay with org admin only (no case capabilities)", async () => {
    const adminOnlyUid = "barangay-admin-only-uid12";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("users").doc(adminOnlyUid).set({
        role: "barangay",
        displayName: "Org Admin",
        active: true,
        createdAt: new Date(),
        primaryOrgId: ORG_BARANGAY_DEMO,
      });
      await seedMembership(db, ORG_BARANGAY_DEMO, adminOnlyUid, CAPS.orgAdminOnly);
    });
    const db = testEnv.authenticatedContext(adminOnlyUid).firestore();
    await assertFails(db.collection("cases").doc("demo-case-read").get());
  });

  it("denies legacy case without orgId", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const { orgId: _drop, ...legacy } = validCase();
      await context.firestore().collection("cases").doc("legacy-no-org").set(legacy);
    });
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(db.collection("cases").doc("legacy-no-org").get());
  });

  it("denies forged orgId on create", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db
        .collection("cases")
        .doc("forged-org")
        .set(validCase({ orgId: ORG_BARANGAY_OTHER })),
    );
  });

  it("denies update that changes orgId", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    const caseId = "case-org-immutable";
    await assertSucceeds(db.collection("cases").doc(caseId).set(validCase()));
    const snap = await db.collection("cases").doc(caseId).get();
    const data = snap.data();
    await assertFails(
      db.collection("cases").doc(caseId).update({
        ...data,
        orgId: ORG_BARANGAY_OTHER,
        updatedAt: new Date(),
      }),
    );
  });

  it("denies invalid field types and status values", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db
        .collection("cases")
        .doc("case-bad-age")
        .set(validCase({ age: "sixteen" })),
    );
    await assertFails(
      db.collection("cases").doc("case-bad-age-int").set(validCase({ age: 12 })),
    );
    await assertFails(
      db
        .collection("cases")
        .doc("case-bad-status")
        .set(validCase({ caseStatus: "archived" })),
    );
  });
});

describe("reports collection (legacy per-case client payload denied)", () => {
  it("denies barangay create with non-aggregate schema", async () => {
    const barangayDb = testEnv.authenticatedContext(barangayUid).firestore();
    const mophDb = testEnv.authenticatedContext(mophUid).firestore();
    const payload = {
      caseId: "demo-case-read",
      reportStatus: "submitted",
      acceptedAt: new Date(),
    };
    await assertFails(barangayDb.collection("reports").doc("r1").set(payload));
    await assertFails(mophDb.collection("reports").doc("r1").set(payload));
  });
});
