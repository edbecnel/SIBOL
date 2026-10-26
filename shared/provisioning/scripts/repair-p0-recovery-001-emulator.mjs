#!/usr/bin/env node
/**
 * SIBOL-P0-RECOVERY-001 — emulator-only: replace obsolete Barangay Tres demo labels
 * on active user profiles (assignedBarangay). Idempotent.
 *
 * Run from repo root:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8195 node shared/provisioning/scripts/repair-p0-recovery-001-emulator.mjs
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const EXPECTED_EMULATOR_HOST = "127.0.0.1:8195";
const EXPECTED_PROJECT_ID = "sibol-286d0";
const OBSOLETE_SITE = "Barangay Tres, Balingasag";
const CANONICAL_SITE = "Barangay 3, Balingasag";
const OBSOLETE_ORG_NAME = "Barangay Tres";
const CANONICAL_ORG_NAME = "Barangay 3 (Poblacion)";

function abort(message) {
  console.error(`ABORT: ${message}`);
  process.exit(1);
}

const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host) {
  abort("FIRESTORE_EMULATOR_HOST is not set (refusing to run against production).");
}
if (host !== EXPECTED_EMULATOR_HOST) {
  abort(`FIRESTORE_EMULATOR_HOST must be ${EXPECTED_EMULATOR_HOST} (got ${host}).`);
}

initializeApp({ projectId: EXPECTED_PROJECT_ID });
const db = getFirestore();

let usersPatched = 0;
const usersSnap = await db.collection("users").get();
for (const doc of usersSnap.docs) {
  const data = doc.data();
  if (data.assignedBarangay === OBSOLETE_SITE) {
    await doc.ref.update({ assignedBarangay: CANONICAL_SITE });
    usersPatched += 1;
  }
}

let orgsPatched = 0;
const orgRef = db.collection("organizations").doc("barangay03");
const orgSnap = await orgRef.get();
if (orgSnap.exists && orgSnap.data().name === OBSOLETE_ORG_NAME) {
  await orgRef.update({ name: CANONICAL_ORG_NAME });
  orgsPatched += 1;
}

const dirRef = db.collection("organizationDirectory").doc("barangay03");
const dirSnap = await dirRef.get();
if (dirSnap.exists) {
  const dir = dirSnap.data();
  const patch = {};
  if (dir.name === OBSOLETE_ORG_NAME) patch.name = CANONICAL_ORG_NAME;
  if (dir.geographicSiteLabel === OBSOLETE_SITE) {
    patch.geographicSiteLabel = CANONICAL_SITE;
  }
  if (Object.keys(patch).length > 0) {
    patch.updatedAt = FieldValue.serverTimestamp();
    await dirRef.update(patch);
  }
}

let casesPatched = 0;
const casesSnap = await db.collection("cases").get();
for (const doc of casesSnap.docs) {
  if (doc.data().barangay === OBSOLETE_SITE) {
    await doc.ref.update({ barangay: CANONICAL_SITE });
    casesPatched += 1;
  }
}

let reportsPatched = 0;
const reportsSnap = await db.collection("reports").get();
for (const doc of reportsSnap.docs) {
  if (doc.data().barangay === OBSOLETE_SITE) {
    await doc.ref.update({ barangay: CANONICAL_SITE });
    reportsPatched += 1;
  }
}

const remaining = [];
for (const col of ["users", "cases", "reports", "organizationDirectory", "organizations"]) {
  const snap = await db.collection(col).get();
  for (const doc of snap.docs) {
    const raw = JSON.stringify(doc.data());
    if (raw.includes("Barangay Tres")) {
      remaining.push(`${col}/${doc.id}`);
    }
  }
}

if (remaining.length > 0) {
  abort(`Obsolete strings remain: ${remaining.join(", ")}`);
}

console.log(
  JSON.stringify(
    {
      ok: true,
      usersPatched,
      orgsPatched,
      casesPatched,
      reportsPatched,
      canonicalSite: CANONICAL_SITE,
      canonicalOrgName: CANONICAL_ORG_NAME,
    },
    null,
    2,
  ),
);
