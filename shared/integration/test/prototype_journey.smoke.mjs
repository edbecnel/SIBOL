import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp as initAdmin, deleteApp, getApps } from "firebase-admin/app";
import { getAuth as getAdminAuth } from "firebase-admin/auth";
import { getFirestore as getAdminFirestore, Timestamp } from "firebase-admin/firestore";
import { initializeApp as initClient } from "firebase/app";
import {
  connectAuthEmulator,
  getAuth,
  signInWithEmailAndPassword,
} from "firebase/auth";
import {
  connectFirestoreEmulator,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  collection,
  query,
  where,
  updateDoc,
  addDoc,
  serverTimestamp,
} from "firebase/firestore";
import { runCreateCoordinationReferral } from "../../functions/lib/coordination/createCoordinationReferral.js";
import { executeEmulatorDemoSeed, loadEmulatorDemoUsers } from "../../provisioning/src/emulator_seed.mjs";
import {
  DEMO_ASSIGNED_BARANGAY,
  DEMO_BARANGAY_ORG_ID,
  EMULATOR_DEMO_ASSISTANCE_INBOX_ID,
} from "../../provisioning/src/emulator_demo_constants.mjs";

const projectId = "sibol-286d0";
let uidByKey;
let barangayStaffUid;
let mophStaffUid;
let teenUid;
let centralUid;

function parseHostPort(envName) {
  const raw = process.env[envName];
  if (!raw) {
    throw new Error(`${envName} is required`);
  }
  const [host, portStr] = raw.split(":");
  const port = Number(portStr);
  if (!host || !Number.isInteger(port)) {
    throw new Error(`${envName} must be host:port`);
  }
  return { host, port };
}

function clientApp() {
  const fs = parseHostPort("FIRESTORE_EMULATOR_HOST");
  const authEp = parseHostPort("FIREBASE_AUTH_EMULATOR_HOST");
  const app = initClient({
    projectId,
    apiKey: "demo-api-key",
  });
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${authEp.host}:${authEp.port}`, {
    disableWarnings: true,
  });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, fs.host, fs.port);
  return { auth, db };
}

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error("Auth and Firestore emulators must be running (emulators:exec).");
  }
  const { users, missing } = loadEmulatorDemoUsers();
  if (missing.length) {
    throw new Error(`Missing smoke passwords: ${missing.join(", ")}`);
  }
  if (!getApps().length) {
    initAdmin({ projectId });
  }
  const result = await executeEmulatorDemoSeed({
    auth: getAdminAuth(),
    db: getAdminFirestore(),
    users,
  });
  uidByKey = result.uidByKey;
  barangayStaffUid = uidByKey.barangay_staff;
  mophStaffUid = uidByKey.moph_staff;
  teenUid = uidByKey.teen;
  centralUid = uidByKey.central;
});

after(async () => {
  for (const app of getApps()) {
    await deleteApp(app);
  }
});

describe("SIBOL-INT-001 prototype journey (emulator smoke)", () => {
  it("teen submits assistance; barangay acknowledges; referral reaches MOPH inbox", async () => {
    const { auth, db } = clientApp();
    const teenCredential = await signInWithEmailAndPassword(
      auth,
      "teen.demo@sibol.local",
      process.env.SIBOL_EMULATOR_PASSWORD_TEEN,
    );
    const signedInTeenUid = teenCredential.user.uid;

    const newRef = await addDoc(collection(db, "teenAssistanceRequests"), {
      teenUid: signedInTeenUid,
      barangay: DEMO_ASSIGNED_BARANGAY,
      orgId: DEMO_BARANGAY_ORG_ID,
      category: "generalSupport",
      description: "Fictional smoke-test assistance request for integration.",
      status: "submitted",
      createdAt: new Date(),
    });

    await auth.signOut();
    const barangayCredential = await signInWithEmailAndPassword(
      auth,
      "barangay.demo@sibol.local",
      process.env.SIBOL_EMULATOR_PASSWORD_BARANGAY_STAFF ||
        process.env.SIBOL_DEMO_PASSWORD_BARANGAY,
    );
    const signedInBarangayUid = barangayCredential.user.uid;

    const ackRef = doc(db, "teenAssistanceRequests", newRef.id);
    await updateDoc(ackRef, {
      status: "acknowledged",
      acknowledgedAt: serverTimestamp(),
      acknowledgedByUid: signedInBarangayUid,
    });

    const referral = await runCreateCoordinationReferral(
      getAdminFirestore(),
      signedInBarangayUid,
      {
      assistanceRequestId: newRef.id,
      barangayReferralSummary:
        "Fictional referral summary for MOPH review (smoke test).",
      },
    );
    assert.ok(referral.threadId);

    await auth.signOut();
    await signInWithEmailAndPassword(
      auth,
      "moph.demo@sibol.local",
      process.env.SIBOL_EMULATOR_PASSWORD_MOPH_STAFF ||
        process.env.SIBOL_DEMO_PASSWORD_MOPH,
    );

    const threadSnap = await getDoc(
      doc(db, "caseCoordinationThreads", referral.threadId),
    );
    assert.equal(threadSnap.exists(), true);
  });

  it("pre-seeded inbox request is visible to barangay staff in org", async () => {
    const { auth, db } = clientApp();
    await signInWithEmailAndPassword(
      auth,
      "barangay.demo@sibol.local",
      process.env.SIBOL_EMULATOR_PASSWORD_BARANGAY_STAFF ||
        process.env.SIBOL_DEMO_PASSWORD_BARANGAY,
    );
    const snap = await getDoc(
      doc(db, "teenAssistanceRequests", EMULATOR_DEMO_ASSISTANCE_INBOX_ID),
    );
    assert.equal(snap.exists(), true);
    assert.equal(snap.data().orgId, DEMO_BARANGAY_ORG_ID);

    const inbox = await getDocs(
      query(
        collection(db, "teenAssistanceRequests"),
        where("orgId", "==", DEMO_BARANGAY_ORG_ID),
      ),
    );
    assert.ok(inbox.size >= 1);
  });

  it("central administrator without case capability cannot read cases", async () => {
    const adminDb = getAdminFirestore();
    const caseRef = adminDb.collection("cases").doc("int-smoke-case");
    if (!(await caseRef.get()).exists) {
      await caseRef.set({
        demoName: "Smoke Case",
        age: 16,
        barangay: DEMO_ASSIGNED_BARANGAY,
        orgId: DEMO_BARANGAY_ORG_ID,
        caseStatus: "active",
        registeredAt: Timestamp.now(),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        reportStatus: "notSubmitted",
      });
    }

    const { auth, db } = clientApp();
    await signInWithEmailAndPassword(
      auth,
      "central.admin@sibol.local",
      process.env.SIBOL_EMULATOR_PASSWORD_CENTRAL,
    );
    await assert.rejects(
      () => getDoc(doc(db, "cases", "int-smoke-case")),
      (err) => err?.code === "permission-denied",
    );
  });

  it("teen cannot read another teen assistance document", async () => {
    const adminDb = getAdminFirestore();
    const otherTeen = "otherTeenUid1234567890123456";
    const otherId = "demo-assist-other-teen";
    await adminDb.collection("users").doc(otherTeen).set({
      role: "teen",
      displayName: "Other Teen",
      active: true,
      assignedBarangay: DEMO_ASSIGNED_BARANGAY,
      selectedBarangayOrgId: DEMO_BARANGAY_ORG_ID,
      createdAt: Timestamp.now(),
    });
    await adminDb.collection("teenAssistanceRequests").doc(otherId).set({
      teenUid: otherTeen,
      barangay: DEMO_ASSIGNED_BARANGAY,
      orgId: DEMO_BARANGAY_ORG_ID,
      category: "generalSupport",
      description: "Other teen fictional request.",
      status: "submitted",
      createdAt: Timestamp.now(),
    });

    const { auth, db } = clientApp();
    await signInWithEmailAndPassword(
      auth,
      "teen.demo@sibol.local",
      process.env.SIBOL_EMULATOR_PASSWORD_TEEN,
    );
    await assert.rejects(
      () => getDoc(doc(db, "teenAssistanceRequests", otherId)),
      (err) => err?.code === "permission-denied",
    );
  });
});
