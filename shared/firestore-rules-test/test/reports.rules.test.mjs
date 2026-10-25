import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { serverTimestamp, Timestamp } from "firebase/firestore";
import {
  CAPS,
  ORG_BARANGAY_DEMO,
  ORG_BARANGAY_OTHER,
  ORG_HOSPITAL_DEMO,
  seedMembership,
  setupM2DemoAuth,
} from "./helpers/org_auth_seed.mjs";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");

const projectId = "demo-sibol-rules";
const barangayUid = "barangay-user-1";
const barangayUid2 = "barangay-user-2";
const teenUid = "teen-user-1";
const mophUid = "moph-user-1";
const site = "Barangay Tres, Balingasag";
const otherSite = "Other Demo Barangay";

let testEnv;

const minAcceptedAt = Timestamp.fromMillis(1);

function mophProductionListQuery(db) {
  return db
    .collection("reports")
    .where("reportStatus", "==", "submitted")
    .where("acceptedAt", ">", minAcceptedAt)
    .orderBy("acceptedAt", "desc");
}

function mophLegacyListQuery(db) {
  return db
    .collection("reports")
    .where("reportStatus", "==", "submitted")
    .orderBy("submittedAt", "desc");
}

function barangayProductionListQuery(db, barangay) {
  return db
    .collection("reports")
    .where("barangay", "==", barangay)
    .where("orgId", "==", ORG_BARANGAY_DEMO)
    .where("reportStatus", "==", "submitted")
    .where("acceptedAt", ">", minAcceptedAt)
    .orderBy("acceptedAt", "desc");
}

function validAggregateReport(overrides = {}) {
  return {
    barangay: site,
    orgId: ORG_BARANGAY_DEMO,
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
    await db.collection("users").doc(barangayUid2).set({
      ...userBase,
      role: "barangay",
      displayName: "Other Barangay Demo",
      assignedBarangay: otherSite,
    });
    await setupM2DemoAuth(db, {
      barangayUid,
      barangayUid2,
      teenUid,
      mophUid,
      otherSite,
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

  it("denies barangay create with wrong org or mismatched counts", async () => {
    const barangayDb = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      barangayDb
        .collection("reports")
        .add(validAggregateReport({ orgId: ORG_BARANGAY_OTHER })),
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
        orgId: ORG_BARANGAY_DEMO,
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

  it("allows MOPH production list query; denies legacy list query shape", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const now = new Date();
      const db = context.firestore();
      await db.collection("reports").doc("good-report").set({
        barangay: site,
        orgId: ORG_BARANGAY_DEMO,
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
      await db.collection("reports").doc("legacy-no-accepted").set({
        reportStatus: "submitted",
        caseId: "legacy",
      });
    });
    const mophDb = testEnv.authenticatedContext(mophUid).firestore();
    await assertSucceeds(mophProductionListQuery(mophDb).get());
    await assertFails(mophLegacyListQuery(mophDb).get());
  });

  it("allows barangay production list query for assigned site", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const now = new Date();
      await context.firestore().collection("reports").doc("brgy-list").set({
        barangay: site,
        orgId: ORG_BARANGAY_DEMO,
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
    await assertSucceeds(barangayProductionListQuery(barangayDb, site).get());
  });

  it("denies teen MOPH production list query", async () => {
    const teenDb = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(mophProductionListQuery(teenDb).get());
  });

  it("allows MOPH production list without primaryOrgId when hospital01 membership grants coordination", async () => {
    const legacyMophUid = "moph-legacy-reports";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("users").doc(legacyMophUid).set({
        displayName: "Legacy MOPH",
        active: true,
        createdAt: new Date(),
        role: "moph",
      });
      await seedMembership(db, ORG_HOSPITAL_DEMO, legacyMophUid, CAPS.hospitalCoord);
    });
    const mophDb = testEnv.authenticatedContext(legacyMophUid).firestore();
    await assertSucceeds(mophProductionListQuery(mophDb).get());
  });

  it("denies MOPH management-only admin on production list query", async () => {
    const adminUid = "moph-admin-reports";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("users").doc(adminUid).set({
        displayName: "MOPH Org Admin",
        active: true,
        createdAt: new Date(),
        role: "moph",
        primaryOrgId: ORG_HOSPITAL_DEMO,
      });
      await seedMembership(db, ORG_HOSPITAL_DEMO, adminUid, CAPS.orgAdminOnly);
    });
    const mophDb = testEnv.authenticatedContext(adminUid).firestore();
    await assertFails(mophProductionListQuery(mophDb).get());
  });

  it("denies other barangay read of submitted report (single doc and list)", async () => {
    const reportId = "demo-report-site-scope";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const now = new Date();
      await context.firestore().collection("reports").doc(reportId).set({
        barangay: site,
        orgId: ORG_BARANGAY_DEMO,
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
    const otherBarangayDb = testEnv.authenticatedContext(barangayUid2).firestore();
    await assertFails(otherBarangayDb.collection("reports").doc(reportId).get());
    await assertSucceeds(
      otherBarangayDb
        .collection("reports")
        .where("barangay", "==", otherSite)
        .where("orgId", "==", ORG_BARANGAY_OTHER)
        .where("reportStatus", "==", "submitted")
        .where("acceptedAt", ">", minAcceptedAt)
        .orderBy("acceptedAt", "desc")
        .get(),
    );
  });

  it("denies teen read of barangay submitted report document", async () => {
    const reportId = "demo-report-teen-deny";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const now = new Date();
      await context.firestore().collection("reports").doc(reportId).set({
        barangay: site,
        orgId: ORG_BARANGAY_DEMO,
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
    const teenDb = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(teenDb.collection("reports").doc(reportId).get());
  });

  it("denies barangay update on reports", async () => {
    const reportId = "demo-report-no-update";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const now = new Date();
      await context.firestore().collection("reports").doc(reportId).set({
        barangay: site,
        orgId: ORG_BARANGAY_DEMO,
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
