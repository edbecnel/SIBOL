import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { serverTimestamp } from "firebase/firestore";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");

const projectId = "demo-sibol-rules";
const barangayUid = "barangay-user-1";
const teenUid = "teen-user-1";
const mophUid = "moph-user-1";
const site = "Barangay Tres, Balingasag";

let testEnv;

function validAggregateReport(overrides = {}) {
  return {
    barangay: site,
    submittedAt: serverTimestamp(),
    submittedByUid: barangayUid,
    totalCaseCount: 2,
    activeCaseCount: 1,
    followUpScheduledCount: 1,
    followUpCompletedCount: 0,
    closedCaseCount: 0,
    reportStatus: "submitted",
    acceptedAt: serverTimestamp(),
    ...overrides,
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
      assignedBarangay: site,
    };
    await db.collection("users").doc(barangayUid).set({
      ...userBase,
      role: "barangay",
      displayName: "Barangay Demo",
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
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("reports collection (DEMO-004 aggregate)", () => {
  it("allows barangay create of aggregate submitted report", async () => {
    const barangayDb = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      barangayDb.collection("reports").add(validAggregateReport()),
    );
  });

  it("denies teen and MOPH client create on reports", async () => {
    const teenDb = testEnv.authenticatedContext(teenUid).firestore();
    const mophDb = testEnv.authenticatedContext(mophUid).firestore();
    const payload = validAggregateReport();
    await assertFails(teenDb.collection("reports").add(payload));
    await assertFails(mophDb.collection("reports").add(payload));
  });

  it("denies barangay create with wrong site or mismatched counts", async () => {
    const barangayDb = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      barangayDb
        .collection("reports")
        .add(validAggregateReport({ barangay: "Other Barangay" })),
    );
    await assertFails(
      barangayDb.collection("reports").add(
        validAggregateReport({
          totalCaseCount: 3,
          activeCaseCount: 1,
          followUpScheduledCount: 1,
          closedCaseCount: 0,
          followUpCompletedCount: 0,
        }),
      ),
    );
  });

  it("allows MOPH read of submitted report; denies teen read", async () => {
    const reportId = "demo-report-read";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const now = new Date();
      await context.firestore().collection("reports").doc(reportId).set({
        barangay: site,
        submittedAt: now,
        submittedByUid: barangayUid,
        totalCaseCount: 1,
        activeCaseCount: 1,
        followUpScheduledCount: 0,
        followUpCompletedCount: 0,
        closedCaseCount: 0,
        reportStatus: "submitted",
        acceptedAt: now,
      });
    });
    const mophDb = testEnv.authenticatedContext(mophUid).firestore();
    const teenDb = testEnv.authenticatedContext(teenUid).firestore();
    await assertSucceeds(mophDb.collection("reports").doc(reportId).get());
    await assertFails(teenDb.collection("reports").doc(reportId).get());
  });

  it("denies MOPH read of cases collection", async () => {
    const mophDb = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(mophDb.collection("cases").doc("any-case").get());
  });

  it("denies barangay update on reports", async () => {
    const reportId = "demo-report-no-update";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const now = new Date();
      await context.firestore().collection("reports").doc(reportId).set({
        barangay: site,
        submittedAt: now,
        submittedByUid: barangayUid,
        totalCaseCount: 1,
        activeCaseCount: 1,
        followUpScheduledCount: 0,
        followUpCompletedCount: 0,
        closedCaseCount: 0,
        reportStatus: "submitted",
        acceptedAt: now,
      });
    });
    const barangayDb = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      barangayDb.collection("reports").doc(reportId).update({
        totalCaseCount: 99,
      }),
    );
  });
});
