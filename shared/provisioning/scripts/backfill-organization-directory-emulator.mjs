#!/usr/bin/env node
/**
 * Idempotent organizationDirectory backfill for local emulator QA orgs.
 * Does not modify organizations/* or reseed operational data.
 *
 * Usage (emulator running, FIRESTORE_EMULATOR_HOST set):
 *   node shared/provisioning/scripts/backfill-organization-directory-emulator.mjs
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import {
  upsertDemoOrganizationDirectoryEntries,
} from "../src/sync_organization_directory.mjs";

const projectId = process.env.GCLOUD_PROJECT ?? process.env.FIREBASE_PROJECT ?? "sibol-286d0";

initializeApp({ projectId });
const db = getFirestore();

const results = await upsertDemoOrganizationDirectoryEntries(db);
console.log(JSON.stringify({ projectId, results }, null, 2));
