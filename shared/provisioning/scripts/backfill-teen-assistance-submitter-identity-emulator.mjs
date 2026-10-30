#!/usr/bin/env node
/**
 * SIBOL-P0-RECOVERY-001 — emulator-only idempotent backfill of
 * submitterDisplayName / submitterAccountEmail on teenAssistanceRequests.
 *
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8195 \
 *   FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
 *   node shared/provisioning/scripts/backfill-teen-assistance-submitter-identity-emulator.mjs
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

const EXPECTED_EMULATOR_HOST = "127.0.0.1:8195";
const EXPECTED_AUTH_HOST = "127.0.0.1:9099";
const EXPECTED_PROJECT_ID = "demo-sibol-emulator";
const COLLECTION = "teenAssistanceRequests";

function abort(message) {
  console.error(`ABORT: ${message}`);
  process.exit(1);
}

const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
if (!firestoreHost) {
  abort("FIRESTORE_EMULATOR_HOST is not set.");
}
if (firestoreHost !== EXPECTED_EMULATOR_HOST) {
  abort(`FIRESTORE_EMULATOR_HOST must be ${EXPECTED_EMULATOR_HOST} (got ${firestoreHost}).`);
}
if (!authHost) {
  abort("FIREBASE_AUTH_EMULATOR_HOST is not set.");
}
if (authHost !== EXPECTED_AUTH_HOST) {
  abort(`FIREBASE_AUTH_EMULATOR_HOST must be ${EXPECTED_AUTH_HOST} (got ${authHost}).`);
}

initializeApp({ projectId: EXPECTED_PROJECT_ID });
const db = getFirestore();

async function resolveIdentity(teenUid) {
  const snapshot = {};
  const userSnap = await db.collection("users").doc(teenUid).get();
  if (userSnap.exists) {
    const rawName = userSnap.data()?.displayName;
    if (typeof rawName === "string" && rawName.trim().length > 0) {
      snapshot.submitterDisplayName = rawName.trim();
    }
  }
  try {
    const authUser = await getAuth().getUser(teenUid);
    const rawEmail = authUser.email;
    if (typeof rawEmail === "string" && rawEmail.trim().length > 0) {
      snapshot.submitterAccountEmail = rawEmail.trim();
    }
  } catch {
    // optional
  }
  return snapshot;
}

function identityComplete(data) {
  const name = data.submitterDisplayName;
  const email = data.submitterAccountEmail;
  return (
    typeof name === "string" &&
    name.trim().length > 0 &&
    typeof email === "string" &&
    email.trim().length > 0
  );
}

const snap = await db.collection(COLLECTION).get();
let examined = 0;
let patched = 0;
let alreadyComplete = 0;
let skippedNoTeen = 0;

for (const doc of snap.docs) {
  examined += 1;
  const data = doc.data();
  const teenUid = data.teenUid;
  if (typeof teenUid !== "string" || teenUid.length < 1) {
    skippedNoTeen += 1;
    continue;
  }
  if (identityComplete(data)) {
    alreadyComplete += 1;
    continue;
  }
  const resolved = await resolveIdentity(teenUid);
  const update = {};
  if (
    resolved.submitterDisplayName &&
    data.submitterDisplayName !== resolved.submitterDisplayName
  ) {
    update.submitterDisplayName = resolved.submitterDisplayName;
  }
  if (
    resolved.submitterAccountEmail &&
    data.submitterAccountEmail !== resolved.submitterAccountEmail
  ) {
    update.submitterAccountEmail = resolved.submitterAccountEmail;
  }
  if (Object.keys(update).length > 0) {
    await doc.ref.update(update);
    patched += 1;
  }
}

const verify = [];
const after = await db.collection(COLLECTION).get();
for (const doc of after.docs) {
  const data = doc.data();
  if (!identityComplete(data)) {
    verify.push(doc.id);
  }
}
if (verify.length > 0) {
  abort(`After backfill, incomplete identity on: ${verify.join(", ")}`);
}

console.log(
  JSON.stringify(
    {
      ok: true,
      examined,
      patched,
      alreadyComplete,
      skippedNoTeen,
      total: after.size,
    },
    null,
    2,
  ),
);
