#!/usr/bin/env node
/**
 * SIBOL-GEO-001-FIX-003 — emulator-only repair for barangay03 display name and QA Teen 03 assignedBarangay.
 * Run from shared/functions: FIRESTORE_EMULATOR_HOST=127.0.0.1:8195 node scripts/repair-geo-fix-003-emulator.mjs
 */
import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "../../..");

const EXPECTED_EMULATOR_HOST = "127.0.0.1:8195";
const EXPECTED_PROJECT_ID = "demo-sibol-emulator";
const ORG_ID = "barangay03";
const TEEN_DISPLAY_NAME = "QA Teen 03";
const TARGET_ORG_NAME = "Barangay 3 (Poblacion)";
const TARGET_ASSIGNED_BARANGAY = "Barangay 3, Balingasag";
const BACKUP_META = resolve(
  REPO_ROOT,
  ".firebase-qa-backups/pre-fix-002/firebase-export-metadata.json",
);

function abort(message) {
  console.error(`ABORT: ${message}`);
  process.exit(1);
}

const host = process.env.FIRESTORE_EMULATOR_HOST;
if (!host) {
  abort("FIRESTORE_EMULATOR_HOST is not set (refusing to run against production).");
}
if (host !== EXPECTED_EMULATOR_HOST) {
  abort(
    `FIRESTORE_EMULATOR_HOST must be exactly ${EXPECTED_EMULATOR_HOST} (got ${host}).`,
  );
}
if (process.env.GOOGLE_CLOUD_PROJECT && process.env.GOOGLE_CLOUD_PROJECT !== EXPECTED_PROJECT_ID) {
  abort(`GOOGLE_CLOUD_PROJECT mismatch (expected ${EXPECTED_PROJECT_ID}).`);
}

if (!existsSync(BACKUP_META)) {
  abort(`Missing backup metadata: ${BACKUP_META}`);
}
try {
  const meta = JSON.parse(readFileSync(BACKUP_META, "utf8"));
  if (!meta?.firestore?.path || !meta?.auth?.path) {
    abort("Backup metadata is missing firestore or auth export paths.");
  }
} catch (e) {
  abort(`Invalid backup metadata: ${e.message}`);
}

initializeApp({ projectId: EXPECTED_PROJECT_ID });
const db = getFirestore();

const orgRef = db.collection("organizations").doc(ORG_ID);
const orgSnap = await orgRef.get();
if (!orgSnap.exists) {
  abort(`Organization ${ORG_ID} not found on emulator.`);
}
const org = orgSnap.data();
if (org.orgId !== ORG_ID || org.type !== "barangay" || org.status !== "active") {
  abort(
    `Organization ${ORG_ID} precondition failed: orgId=${org.orgId} type=${org.type} status=${org.status}`,
  );
}

const teenQuery = await db
  .collection("users")
  .where("displayName", "==", TEEN_DISPLAY_NAME)
  .get();
if (teenQuery.size !== 1) {
  abort(`Expected exactly one user with displayName "${TEEN_DISPLAY_NAME}" (found ${teenQuery.size}).`);
}
const teenDoc = teenQuery.docs[0];
const teen = teenDoc.data();
if (teen.role !== "teen" || teen.active !== true) {
  abort(`QA teen precondition failed: role=${teen.role} active=${teen.active}`);
}
if (teen.selectedBarangayOrgId !== ORG_ID) {
  abort(
    `QA teen selectedBarangayOrgId must be ${ORG_ID} (got ${teen.selectedBarangayOrgId}).`,
  );
}
if (teen.assignedBarangay && String(teen.assignedBarangay).trim().length > 0) {
  abort(
    `QA teen already has assignedBarangay="${teen.assignedBarangay}"; repair not required.`,
  );
}

const membershipSnap = await db
  .collection("organizationMemberships")
  .where("orgId", "==", ORG_ID)
  .get();
const membershipCountBefore = membershipSnap.size;

console.log("Preconditions OK. Applying field-level updates…");
await orgRef.update({ name: TARGET_ORG_NAME });
await teenDoc.ref.update({ assignedBarangay: TARGET_ASSIGNED_BARANGAY });

const orgAfter = (await orgRef.get()).data();
const teenAfter = (await teenDoc.ref.get()).data();
const membershipSnapAfter = await db
  .collection("organizationMemberships")
  .where("orgId", "==", ORG_ID)
  .get();

const checks = [
  ["org.name", orgAfter.name, TARGET_ORG_NAME],
  ["org.orgId", orgAfter.orgId, ORG_ID],
  ["org.type", orgAfter.type, "barangay"],
  ["org.status", orgAfter.status, "active"],
  ["teen.assignedBarangay", teenAfter.assignedBarangay, TARGET_ASSIGNED_BARANGAY],
  ["teen.selectedBarangayOrgId", teenAfter.selectedBarangayOrgId, ORG_ID],
  ["teen.displayName", teenAfter.displayName, TEEN_DISPLAY_NAME],
];

let failed = false;
for (const [label, actual, expected] of checks) {
  if (actual !== expected) {
    console.error(`VERIFY FAIL ${label}: expected "${expected}", got "${actual}"`);
    failed = true;
  }
}
if (membershipSnapAfter.size !== membershipCountBefore) {
  console.error(
    `VERIFY FAIL memberships count: before ${membershipCountBefore} after ${membershipSnapAfter.size}`,
  );
  failed = true;
}

if (failed) {
  abort("Read-back verification failed.");
}

console.log(
  JSON.stringify(
    {
      ok: true,
      orgId: ORG_ID,
      teenUid: teenDoc.id,
      orgName: orgAfter.name,
      assignedBarangay: teenAfter.assignedBarangay,
      memberships: membershipSnapAfter.size,
    },
    null,
    2,
  ),
);
