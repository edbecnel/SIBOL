#!/usr/bin/env node
/**
 * Read-only QA-001 anchor check against canonical Firestore emulator (8195).
 */
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const PROJECT = "sibol-286d0";
const host = process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8195";

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = host;
}

if (getApps().length === 0) {
  initializeApp({ projectId: PROJECT });
}
const db = getFirestore();

const reqId = "32sQiFj9v8T6R6T3Asih";
const req = await db.collection("teenAssistanceRequests").doc(reqId).get();
const registry = await db.collection("barangayCoordinationRegistry").doc(reqId).get();
const teen = await db.collection("users").doc("pjHSdYK7Vh2qYAnBzu6FmMeWjUMU").get();
const thread = await db
  .collection("caseCoordinationThreads")
  .doc("CxsRXE0ciuhrxXa1L0Ay")
  .get();

const summary = {
  qaAssistanceRequest: req.exists
    ? { id: reqId, status: req.data()?.status, orgId: req.data()?.orgId }
    : { id: reqId, exists: false },
  coordinationRegistry: registry.exists,
  qaTeenProfile: teen.exists,
  coordinationThread: thread.exists ? { phase: thread.data()?.phase } : false,
};

console.log(JSON.stringify(summary, null, 2));

const apps = getApps();
if (apps.length) await deleteApp(apps[0]);

if (!req.exists) process.exit(1);
