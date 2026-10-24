#!/usr/bin/env node
import { parseArgs } from "node:util";
import { buildMigrationPlan, planSummary } from "./plan.mjs";
import { collectInventory } from "./inventory.mjs";
import { applyMigrationPlan, verifyPostMigration } from "./apply.mjs";
import { loadOrgMapping } from "./load_mapping.mjs";

const { values, positionals } = parseArgs({
  options: {
    dryRun: { type: "boolean", default: true },
    inventory: { type: "boolean", default: false },
    verify: { type: "boolean", default: false },
    execute: { type: "boolean", default: false },
    "confirm-project": { type: "string" },
    mapping: { type: "string" },
  },
  allowPositionals: true,
});

async function getDb() {
  const { initializeApp, applicationDefault, cert } = await import(
    "firebase-admin/app"
  );
  const { getFirestore } = await import("firebase-admin/firestore");
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && !process.env.FIREBASE_CONFIG) {
    throw new Error(
      "Set GOOGLE_APPLICATION_CREDENTIALS or use emulator (FIRESTORE_EMULATOR_HOST).",
    );
  }
  try {
    initializeApp(applicationDefault());
  } catch {
    initializeApp();
  }
  return getFirestore();
}

async function main() {
  const mapping = loadOrgMapping(values.mapping);
  const db = await getDb();

  if (values.inventory) {
    const inv = await collectInventory(db);
    console.log(JSON.stringify(inv, null, 2));
    return;
  }

  const inv = await collectInventory(db);
  const plan = buildMigrationPlan({ dbSnapshot: inv.snapshot, mapping });
  console.log("Plan summary:", planSummary(plan));
  if (plan.errors.length) {
    console.error("Plan errors:", JSON.stringify(plan.errors, null, 2));
  }

  const dryRun = !values.execute;
  if (values.execute) {
    const project = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    if (!values["confirm-project"] || values["confirm-project"] !== project) {
      throw new Error(
        `Live execute requires --confirm-project=${project ?? "<set GCLOUD_PROJECT>"}`,
      );
    }
    console.warn("EXECUTING LIVE MIGRATION — not authorized in M1 handover except emulators.");
  }

  const result = await applyMigrationPlan(db, plan, { dryRun });
  console.log(
    JSON.stringify(
      { dryRun: result.dryRun, previewCount: result.preview.length, applied: result.applied },
      null,
      2,
    ),
  );
  if (dryRun && result.preview.length <= 200) {
    console.log(JSON.stringify(result.preview, null, 2));
  }

  if (values.verify && !dryRun) {
    const issues = await verifyPostMigration(db, plan);
    console.log("Verify:", issues.length ? issues : "OK");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
