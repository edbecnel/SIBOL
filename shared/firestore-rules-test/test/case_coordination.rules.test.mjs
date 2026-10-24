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

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");

const projectId = "demo-sibol-rules";
const barangayUid = "barangay-user-1";
const barangayUid2 = "barangay-user-2";
const teenUid = "teen-user-1";
const teenUid2 = "teen-user-2";
const mophUid = "moph-user-1";
const site = "Barangay Tres, Balingasag";
const otherSite = "Other Demo Barangay";

const threadId = "coord-thread-1";
const assistanceRequestId = "assist-req-1";
const now = Timestamp.fromDate(new Date("2026-10-24T12:00:00Z"));

let testEnv;

function validThreadHeader(overrides = {}) {
  return {
    barangay: site,
    displayRef: "SIBOL-REF-DEMO-001",
    category: "generalSupport",
    barangayReferralSummary:
      "Fictional barangay-prepared summary for hospital coordination demo.",
    phase: "referred",
    createdAt: now,
    updatedAt: now,
    lastStaffEventAt: now,
    createdByUid: barangayUid,
    ...overrides,
  };
}

function mophThreadListQuery(db) {
  return db
    .collection("caseCoordinationThreads")
    .where("phase", "in", ["referred", "awaitingMoph", "awaitingBarangay"])
    .orderBy("lastStaffEventAt", "desc");
}

function barangayThreadListQuery(db, barangay) {
  return db
    .collection("caseCoordinationThreads")
    .where("barangay", "==", barangay)
    .where("phase", "==", "referred")
    .orderBy("lastStaffEventAt", "desc");
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
    await db.collection("users").doc(barangayUid2).set({
      ...userBase,
      role: "barangay",
      assignedBarangay: otherSite,
      displayName: "Other BNS",
    });
    await db.collection("users").doc(teenUid).set({
      ...userBase,
      role: "teen",
      displayName: "Teen Demo",
    });
    await db.collection("users").doc(teenUid2).set({
      ...userBase,
      role: "teen",
      displayName: "Teen Two",
    });
    await db.collection("users").doc(mophUid).set({
      ...userBase,
      role: "moph",
      displayName: "MOPH Demo",
    });

    await db.collection("caseCoordinationThreads").doc(threadId).set(
      validThreadHeader(),
    );
    await db
      .collection("caseCoordinationThreads")
      .doc(threadId)
      .collection("private")
      .doc("binding")
      .set({
        teenUid,
        assistanceRequestId,
        createdAt: now,
        createdByUid: barangayUid,
      });
    await db
      .collection("caseCoordinationThreads")
      .doc(threadId)
      .collection("staffEvents")
      .doc("evt-1")
      .set({
        eventType: "referral_submitted",
        body: "Fictional staff coordination note for MOPH and barangay only.",
        actorUid: barangayUid,
        createdAt: now,
      });
    await db.collection("teenAssistanceRequests").doc(assistanceRequestId).set({
      teenUid,
      barangay: site,
      category: "healthInformation",
      description: "Fictional assistance request for coordination rules tests.",
      status: "acknowledged",
      createdAt: now,
      acknowledgedAt: now,
      acknowledgedByUid: barangayUid,
    });
    await db.collection("barangayCoordinationRegistry").doc(assistanceRequestId).set({
      threadId,
      barangay: site,
      teenUid,
      active: true,
      createdAt: now,
    });
    await db
      .collection("teenCoordinationLinks")
      .doc(teenUid)
      .collection("links")
      .doc(assistanceRequestId)
      .set({
        threadId,
        progressCode: "referred",
        progressLabel: "Your request is being coordinated with hospital staff.",
        updatedAt: now,
        barangay: site,
      });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("caseCoordinationThreads reads", () => {
  it("allows MOPH to read coordination thread header", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertSucceeds(
      db.collection("caseCoordinationThreads").doc(threadId).get(),
    );
  });

  it("allows MOPH list query on phase and lastStaffEventAt", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertSucceeds(mophThreadListQuery(db).get());
  });

  it("denies MOPH read of private binding", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(
      db
        .collection("caseCoordinationThreads")
        .doc(threadId)
        .collection("private")
        .doc("binding")
        .get(),
    );
  });

  it("allows MOPH read of staffEvents", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertSucceeds(
      db
        .collection("caseCoordinationThreads")
        .doc(threadId)
        .collection("staffEvents")
        .doc("evt-1")
        .get(),
    );
  });

  it("allows barangay in assigned barangay to read thread", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      db.collection("caseCoordinationThreads").doc(threadId).get(),
    );
  });

  it("allows barangay production list query", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(barangayThreadListQuery(db, site).get());
  });

  it("allows barangay to read private binding for its thread", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      db
        .collection("caseCoordinationThreads")
        .doc(threadId)
        .collection("private")
        .doc("binding")
        .get(),
    );
  });

  it("denies other barangay thread read", async () => {
    const db = testEnv.authenticatedContext(barangayUid2).firestore();
    await assertFails(
      db.collection("caseCoordinationThreads").doc(threadId).get(),
    );
  });

  it("denies teen read of coordination thread", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db.collection("caseCoordinationThreads").doc(threadId).get(),
    );
  });

  it("denies teen read of staffEvents", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db
        .collection("caseCoordinationThreads")
        .doc(threadId)
        .collection("staffEvents")
        .doc("evt-1")
        .get(),
    );
  });
});

describe("barangayCoordinationRegistry reads", () => {
  it("allows barangay to read missing registry when assistance request is owned", async () => {
    const unregisteredId = "assist-req-no-registry";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("teenAssistanceRequests").doc(unregisteredId).set({
        teenUid,
        barangay: site,
        category: "generalSupport",
        description: "Fictional request without coordination registry row.",
        status: "acknowledged",
        createdAt: now,
        acknowledgedAt: now,
        acknowledgedByUid: barangayUid,
      });
    });
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      db.collection("barangayCoordinationRegistry").doc(unregisteredId).get(),
    );
  });

  it("allows barangay to read registry for its site", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      db.collection("barangayCoordinationRegistry").doc(assistanceRequestId).get(),
    );
  });

  it("denies MOPH registry read", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(
      db.collection("barangayCoordinationRegistry").doc(assistanceRequestId).get(),
    );
  });

  it("denies other barangay registry read", async () => {
    const db = testEnv.authenticatedContext(barangayUid2).firestore();
    await assertFails(
      db.collection("barangayCoordinationRegistry").doc(assistanceRequestId).get(),
    );
  });

  it("denies teen registry read", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db.collection("barangayCoordinationRegistry").doc(assistanceRequestId).get(),
    );
  });

  it("denies barangay registry read for other site assistance request (no registry row)", async () => {
    const otherSiteRequestId = "assist-req-other-site";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("teenAssistanceRequests").doc(otherSiteRequestId).set({
        teenUid,
        barangay: otherSite,
        category: "generalSupport",
        description: "Fictional request at another barangay site.",
        status: "acknowledged",
        createdAt: now,
        acknowledgedAt: now,
        acknowledgedByUid: barangayUid2,
      });
    });
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db.collection("barangayCoordinationRegistry").doc(otherSiteRequestId).get(),
    );
  });

  it("denies barangay registry read when assistance request does not exist", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db.collection("barangayCoordinationRegistry").doc("assist-req-unknown").get(),
    );
  });
});

describe("teenCoordinationLinks reads", () => {
  it("allows teen to read own progress link", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertSucceeds(
      db
        .collection("teenCoordinationLinks")
        .doc(teenUid)
        .collection("links")
        .doc(assistanceRequestId)
        .get(),
    );
  });

  it("denies other teen reading link", async () => {
    const db = testEnv.authenticatedContext(teenUid2).firestore();
    await assertFails(
      db
        .collection("teenCoordinationLinks")
        .doc(teenUid)
        .collection("links")
        .doc(assistanceRequestId)
        .get(),
    );
  });

  it("denies MOPH teen progress read", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(
      db
        .collection("teenCoordinationLinks")
        .doc(teenUid)
        .collection("links")
        .doc(assistanceRequestId)
        .get(),
    );
  });
});

describe("client writes denied (Increment A)", () => {
  it("denies barangay client create of coordination thread", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db.collection("caseCoordinationThreads").doc("new-thread").set(validThreadHeader()),
    );
  });

  it("denies barangay client update of thread phase", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db.collection("caseCoordinationThreads").doc(threadId).update({
        phase: "awaitingMoph",
      }),
    );
  });

  it("denies MOPH client create staffEvent", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(
      db
        .collection("caseCoordinationThreads")
        .doc(threadId)
        .collection("staffEvents")
        .doc("evt-forged")
        .set({
          eventType: "moph_clarification_request",
          body: "Forged clarification",
          actorUid: mophUid,
          createdAt: now,
        }),
    );
  });

  it("denies barangay client create private binding", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db
        .collection("caseCoordinationThreads")
        .doc("other-thread")
        .collection("private")
        .doc("binding")
        .set({
          teenUid,
          assistanceRequestId: "other-req",
          createdAt: now,
          createdByUid: barangayUid,
        }),
    );
  });

  it("denies barangay client create registry entry", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db.collection("barangayCoordinationRegistry").doc("new-assist-id").set({
        threadId: "x",
        barangay: site,
        teenUid,
        active: true,
        createdAt: now,
      }),
    );
  });

  it("denies teen client write to progress link", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db
        .collection("teenCoordinationLinks")
        .doc(teenUid)
        .collection("links")
        .doc("forged")
        .set({
          threadId,
          progressCode: "hacked",
          progressLabel: "Hacked",
          updatedAt: now,
          barangay: site,
        }),
    );
  });
});

describe("MOPH cannot access teen assistance", () => {
  it("denies MOPH read of teenAssistanceRequests", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      await adminDb.collection("teenAssistanceRequests").doc("tar-1").set({
        teenUid,
        barangay: site,
        category: "generalSupport",
        description: "Teen original fictional description.",
        status: "acknowledged",
        createdAt: now,
      });
    });
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(db.collection("teenAssistanceRequests").doc("tar-1").get());
  });
});
