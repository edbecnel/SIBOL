#!/usr/bin/env node
/**
 * Read-only verification that canonical demo orgs exist in the Firestore emulator.
 */
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import {
  DEMO_BARANGAY_ORG_ID,
  DEMO_HOSPITAL_ORG_ID,
} from "../../reg/src/org_id.mjs";
import { assertEmulatorEnvironment } from "./emulator_guard.mjs";

const guard = await assertEmulatorEnvironment({
  confirmFlag: true,
  checkReachable: true,
});
if (!guard.ok) {
  console.error(guard.message);
  process.exit(1);
}

if (!getApps().length) {
  initializeApp({ projectId: guard.projectId });
}
const db = getFirestore();

let ok = true;
for (const orgId of [DEMO_BARANGAY_ORG_ID, DEMO_HOSPITAL_ORG_ID]) {
  const snap = await db.collection("organizations").doc(orgId).get();
  if (!snap.exists) {
    console.error(`MISSING organization: ${orgId}`);
    ok = false;
  } else {
    const data = snap.data();
    console.log(`OK: ${orgId} type=${data.type} name=${data.name}`);
  }
}

const inbox = await db.collection("teenAssistanceRequests").doc("demo-assist-inbox-001").get();
if (inbox.exists) {
  console.log(`OK: sample inbox request orgId=${inbox.data()?.orgId}`);
} else {
  console.warn("WARN: demo-assist-inbox-001 not found (optional until seed).");
}

process.exit(ok ? 0 : 1);
