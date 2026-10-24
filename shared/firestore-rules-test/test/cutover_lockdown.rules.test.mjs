import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules.cutover-lockdown",
);
const rules = readFileSync(rulesPath, "utf8");
const projectId = "demo-sibol-cutover-lockdown";
const uid = "barangayStaffUid123456789012";

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().collection("users").doc(uid).set({
      role: "barangay",
      active: true,
      displayName: "Staff",
      createdAt: new Date(),
    });
    await context.firestore().collection("cases").doc("c1").set({
      demoName: "Locked",
      orgId: "barangay03",
      barangay: "Demo",
      caseStatus: "active",
      age: 16,
      registeredAt: new Date(),
      createdAt: new Date(),
      updatedAt: new Date(),
      reportStatus: "notSubmitted",
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("cutover lockdown rules", () => {
  it("allows user to read own profile only", async () => {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertSucceeds(db.collection("users").doc(uid).get());
  });

  it("denies barangay case read during lockdown", async () => {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertFails(db.collection("cases").doc("c1").get());
  });

  it("denies barangay case list during lockdown", async () => {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertFails(
      db
        .collection("cases")
        .where("orgId", "==", "barangay03")
        .get(),
    );
  });

  it("denies assistance and coordination reads", async () => {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertFails(db.collection("teenAssistanceRequests").doc("r1").get());
    await assertFails(db.collection("caseCoordinationThreads").doc("t1").get());
    await assertFails(db.collection("reports").doc("rep1").get());
  });

  it("allows admin SDK writes with rules disabled (migration path)", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await assertSucceeds(
        context
          .firestore()
          .collection("organizations")
          .doc("barangay03")
          .set({ orgId: "barangay03", status: "active" }),
      );
    });
  });
});
