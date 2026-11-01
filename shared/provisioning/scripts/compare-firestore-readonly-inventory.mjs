#!/usr/bin/env node
/**
 * Read-only Firestore document inventory for backup-vs-live comparison.
 * Does not write to Firestore. Output: JSON map path -> content fingerprint.
 */
import { createHash } from "node:crypto";
import { initializeApp, getApps, deleteApp } from "firebase-admin/app";
import { getFirestore, Timestamp, GeoPoint, DocumentReference } from "firebase-admin/firestore";

const PROJECT = process.env.FIRESTORE_COMPARE_PROJECT || "sibol-286d0";
const EMULATOR = process.env.FIRESTORE_EMULATOR_HOST;

function stableValue(value) {
  if (value === null || value === undefined) return null;
  if (value instanceof Timestamp) {
    return { __ts: value.toDate().toISOString() };
  }
  if (value instanceof GeoPoint) {
    return { __geo: [value.latitude, value.longitude] };
  }
  if (value instanceof DocumentReference) {
    return { __ref: value.path };
  }
  if (value instanceof Buffer) {
    return { __bytes: createHash("sha256").update(value).digest("hex") };
  }
  if (Array.isArray(value)) {
    return value.map(stableValue);
  }
  if (typeof value === "object") {
    const out = {};
    for (const key of Object.keys(value).sort()) {
      out[key] = stableValue(value[key]);
    }
    return out;
  }
  return value;
}

function fingerprint(data) {
  const canonical = JSON.stringify(stableValue(data));
  return createHash("sha256").update(canonical).digest("hex");
}

async function walkCollection(ref, out) {
  const snap = await ref.get();
  for (const doc of snap.docs) {
    out[doc.ref.path] = fingerprint(doc.data());
    const subcols = await doc.ref.listCollections();
    for (const sub of subcols) {
      await walkCollection(sub, out);
    }
  }
}

async function inventory() {
  for (const app of getApps()) {
    await deleteApp(app);
  }
  initializeApp({ projectId: PROJECT });
  const db = getFirestore();
  const out = {};
  const roots = await db.listCollections();
  for (const col of roots) {
    await walkCollection(col, out);
  }
  return out;
}

const inv = await inventory();
process.stdout.write(JSON.stringify({ projectId: PROJECT, emulator: EMULATOR || null, count: Object.keys(inv).length, documents: inv }));
