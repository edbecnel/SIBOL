#!/usr/bin/env node
/**
 * Live-only: create central.admin@sibol.local (Auth + Firestore profile).
 * Never logs passwords.
 */
import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

const PROJECT = "sibol-286d0";
const EMAIL = "central.admin@sibol.local";
const DISPLAY_NAME = "Demo Central Administrator";
const PASSWORD_ENV = "SIBOL_EMULATOR_PASSWORD_CENTRAL";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "../../..");

function loadEnvFile(path) {
  if (!existsSync(path)) return {};
  const out = {};
  for (const line of readFileSync(path, "utf8").split("\n")) {
    let trimmed = line.trim();
    if (trimmed.startsWith("export ")) trimmed = trimmed.slice(7).trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq <= 0) continue;
    const key = trimmed.slice(0, eq).trim();
    let val = trimmed.slice(eq + 1).trim();
    if (
      (val.startsWith('"') && val.endsWith('"')) ||
      (val.startsWith("'") && val.endsWith("'"))
    ) {
      val = val.slice(1, -1);
    }
    out[key] = val;
  }
  return out;
}

const { values } = parseArgs({
  options: {
    "dry-run": { type: "boolean", default: false },
    execute: { type: "boolean", default: false },
    "confirm-project": { type: "string" },
    "env-file": { type: "string" },
  },
});

if (!values["dry-run"] && !values.execute) {
  console.error("Pass --dry-run or --execute");
  process.exit(1);
}
if (values.execute && values["confirm-project"] !== PROJECT) {
  console.error(`Execute requires --confirm-project=${PROJECT}`);
  process.exit(1);
}

const envFile =
  values["env-file"] ?? resolve(REPO_ROOT, ".env.emulator.local");
const fileEnv = loadEnvFile(envFile);
const password = (
  process.env[PASSWORD_ENV] ??
  fileEnv[PASSWORD_ENV] ??
  ""
).trim();
if (!password) {
  console.error(
    JSON.stringify({ error: "password_unavailable", envVar: PASSWORD_ENV }),
  );
  process.exit(1);
}

initializeApp({ projectId: PROJECT, credential: applicationDefault() });
const auth = getAuth();
const db = getFirestore();

let existing = null;
try {
  existing = await auth.getUserByEmail(EMAIL);
} catch (e) {
  if (e.code !== "auth/user-not-found") throw e;
}

const plan = {
  project: PROJECT,
  email: EMAIL,
  mode: values.execute ? "execute" : "dry-run",
  passwordSourceEnvVar: PASSWORD_ENV,
  existingUid: existing?.uid ?? null,
  action: existing ? "update_password_and_profile" : "create_auth_and_profile",
};

if (values["dry-run"]) {
  console.log(JSON.stringify(plan, null, 2));
  process.exit(0);
}

let uid;
if (existing) {
  uid = existing.uid;
  await auth.updateUser(uid, { password, displayName: DISPLAY_NAME });
} else {
  const created = await auth.createUser({
    email: EMAIL,
    password,
    displayName: DISPLAY_NAME,
  });
  uid = created.uid;
}

const profileRef = db.collection("users").doc(uid);
const profileSnap = await profileRef.get();
const now = Timestamp.now();
if (!profileSnap.exists) {
  await profileRef.set({
    role: "barangay",
    displayName: DISPLAY_NAME,
    active: true,
    isCentralAdmin: true,
    createdAt: now,
  });
} else {
  const data = profileSnap.data() ?? {};
  const merge = {
    role: data.role === "barangay" ? undefined : "barangay",
    active: data.active === true ? undefined : true,
    isCentralAdmin: data.isCentralAdmin === true ? undefined : true,
    displayName:
      typeof data.displayName === "string" && data.displayName.trim()
        ? undefined
        : DISPLAY_NAME,
  };
  const payload = Object.fromEntries(
    Object.entries(merge).filter(([, v]) => v !== undefined),
  );
  if (Object.keys(payload).length > 0) {
    await profileRef.set(payload, { merge: true });
  }
}

console.log(
  JSON.stringify(
    {
      ...plan,
      uid,
      profileEnsured: true,
      isCentralAdmin: true,
      role: "barangay",
      active: true,
    },
    null,
    2,
  ),
);
