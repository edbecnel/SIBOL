#!/usr/bin/env node
/**
 * SIBOL-DELIVERY-001 consolidated dry-run (read-only on live Firebase).
 * No writes. Does not require demo passwords.
 */
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

const root = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const project = process.env.FIREBASE_PROJECT_ID ?? "sibol-286d0";
const exportDir =
  process.argv.find((a) => a.startsWith("--export="))?.split("=")[1] ??
  ".firebase-qa-backups/po-case-identity-prep-20261026-1832";

function runNode(script, args = []) {
  const res = spawnSync(process.execPath, [script, ...args], {
    cwd: root,
    encoding: "utf8",
  });
  return { status: res.status, stdout: res.stdout, stderr: res.stderr };
}

async function liveInventory() {
  initializeApp({ projectId: project });
  const db = getFirestore();
  const { collectInventory } = await import(
    join(root, "shared/migration/src/inventory.mjs")
  );
  const inv = await collectInventory(db);
  const auth = getAuth();
  const listed = await auth.listUsers(1000);
  return {
    counts: inv.counts,
    barangayLabels: inv.barangayLabels,
    authEmails: listed.users.map((u) => u.email).filter(Boolean).sort(),
    authCount: listed.users.length,
  };
}

const exportInv = runNode(
  join(root, "shared/delivery/scripts/inventory-emulator-export.mjs"),
  [join(root, exportDir)],
);
const fnCompare = runNode(
  join(root, "shared/delivery/scripts/compare-functions.mjs"),
);

let live = null;
let liveError = null;
try {
  live = await liveInventory();
} catch (e) {
  liveError = e.message;
}

const plan = {
  handover: "SIBOL-DELIVERY-001",
  project,
  gitHeadNote: "Run: git rev-parse HEAD at execution time",
  approach:
    "Selective idempotent migration — not full emulator import. Auth passwords are not exportable; UIDs differ between emulator and live. Use Admin SDK provisioning (by email), org/membership backfill, optional shared/migration orgId patches, then deploy rules/indexes/functions from repo HEAD.",
  excludedFromLiveImport: [
    "QA-only emulator accounts (maria.qa.*, teen.qa*, example.com)",
    "Maria Offline Test and other PO QA case ids unless explicitly approved",
    "Emulator password hashes / localId fields",
  ],
  emulatorExport: exportInv.status === 0 ? JSON.parse(exportInv.stdout) : { error: exportInv.stderr },
  liveInventory: live ?? { error: liveError },
  functions: fnCompare.status === 0 ? JSON.parse(fnCompare.stdout) : { error: fnCompare.stderr },
  proposedLiveActionsAfterApproval: {
    backup: [
      "gcloud firestore export gs://<PO_APPROVED_BUCKET>/sibol-backup-$(date +%Y%m%d) --project=sibol-286d0",
      "Optional: firebase auth:export gs://... (service account; no passwords in git)",
    ],
    deploy: [
      "firebase deploy --only firestore:rules,firestore:indexes --project sibol-286d0",
      "cd shared/functions && npm run build",
      "firebase deploy --only functions --project sibol-286d0",
    ],
    data: [
      "shared/provisioning npm run seed -- --dry-run --remote-read (then live seed with PA auth; never overwrites passwords)",
      "shared/migration npm run migrate -- --dry-run (orgId mapping on existing live docs)",
      "Optional org/directory backfill scripts under shared/provisioning/scripts/",
    ],
    noDestructiveDeletes: true,
  },
  androidApk: {
    buildCommand:
      "cd sibol_app && flutter build apk --release --dart-define=ENVIRONMENT=production --dart-define=USE_FIREBASE_EMULATORS=false",
    connectsTo: "live Firebase (sibol-286d0)",
    signing: "release build uses debug keystore per android/app/build.gradle.kts until release keystore is configured",
  },
  approvalGate: {
    summary:
      "PO must approve live backup bucket + deploy rules/indexes/functions + idempotent demo seed/migration before any write.",
    liveResourcesChanged: [
      "Firestore rules and indexes",
      "All Cloud Functions in shared/functions/src/index.ts",
      "Firestore documents via idempotent provisioning/migration only",
      "Auth: create missing demo users only; never reset existing passwords",
    ],
    recordsOverwritten: "None by default (provisioning skips existing cases and does not change Auth passwords)",
    rollback:
      "Restore Firestore from pre-migration export; redeploy prior rules/functions from last known good release tag",
  },
};

console.log(JSON.stringify(plan, null, 2));
