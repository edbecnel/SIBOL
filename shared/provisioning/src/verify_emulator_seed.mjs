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

const projectId = process.env.FIREBASE_PROJECT_ID || "sibol-286d0";

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error("FIRESTORE_EMULATOR_HOST is required.");
  process.exit(1);
}
if (projectId !== "sibol-286d0") {
  console.error("Refusing: FIREBASE_PROJECT_ID must be sibol-286d0 for demo verify.");
  process.exit(1);
}

if (!getApps().length) {
  initializeApp({ projectId });
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
