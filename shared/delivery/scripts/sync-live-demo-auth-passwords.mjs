#!/usr/bin/env node
/**
 * One-time live Auth password alignment for tranche-1 demo emails only.
 * Never logs password values.
 */
import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

const PROJECT = "sibol-286d0";
const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "../../..");

const TARGETS = [
  {
    email: "teen.demo@sibol.local",
    passwordEnvVars: ["SIBOL_EMULATOR_PASSWORD_TEEN", "SIBOL_DEMO_PASSWORD_TEEN"],
  },
  {
    email: "barangay.demo@sibol.local",
    passwordEnvVars: [
      "SIBOL_EMULATOR_PASSWORD_BARANGAY_STAFF",
      "SIBOL_DEMO_PASSWORD_BARANGAY",
    ],
  },
  {
    email: "moph.demo@sibol.local",
    passwordEnvVars: [
      "SIBOL_EMULATOR_PASSWORD_MOPH_STAFF",
      "SIBOL_DEMO_PASSWORD_MOPH",
    ],
  },
];

function loadEnvFile(path) {
  if (!existsSync(path)) return {};
  const out = {};
  const text = readFileSync(path, "utf8");
  for (const line of text.split("\n")) {
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

function resolvePassword(env, passwordEnvVars) {
  for (const name of passwordEnvVars) {
    const fromProcess = process.env[name];
    const fromFile = env[name];
    const value = (fromProcess ?? fromFile ?? "").trim();
    if (value) return { value, source: name };
  }
  return { missing: passwordEnvVars };
}

const { values } = parseArgs({
  options: {
    "dry-run": { type: "boolean", default: false },
    execute: { type: "boolean", default: false },
    "confirm-project": { type: "string" },
    "env-file": { type: "string" },
  },
});

const envFile =
  values["env-file"] ??
  resolve(REPO_ROOT, ".env.emulator.local");
const fileEnv = loadEnvFile(envFile);

if (!values["dry-run"] && !values.execute) {
  console.error("Pass --dry-run or --execute");
  process.exit(1);
}
if (values.execute && values["confirm-project"] !== PROJECT) {
  console.error(`Live execute requires --confirm-project=${PROJECT}`);
  process.exit(1);
}

const plan = [];
for (const target of TARGETS) {
  const resolved = resolvePassword(fileEnv, target.passwordEnvVars);
  if (resolved.missing) {
    console.error(
      JSON.stringify({
        error: "password_unavailable",
        email: target.email,
        triedEnvVars: resolved.missing,
        envFile,
      }),
    );
    process.exit(1);
  }
  plan.push({
    email: target.email,
    passwordSourceEnvVar: resolved.source,
    password: resolved.value,
  });
}

initializeApp({ projectId: PROJECT, credential: applicationDefault() });
const auth = getAuth();

const rows = [];
for (const item of plan) {
  const user = await auth.getUserByEmail(item.email);
  if (user.email !== item.email) {
    console.error({ error: "email_mismatch", expected: item.email });
    process.exit(1);
  }
  rows.push({
    email: item.email,
    uid: user.uid,
    disabled: user.disabled,
    passwordSourceEnvVar: item.passwordSourceEnvVar,
    action: values.execute ? "update_password" : "would_update_password",
  });
  if (values.execute) {
    if (user.disabled) {
      console.error({ error: "account_disabled", email: item.email });
      process.exit(1);
    }
    await auth.updateUser(user.uid, { password: item.password });
  }
}

console.log(
  JSON.stringify(
    {
      project: PROJECT,
      mode: values.execute ? "execute" : "dry-run",
      envFileUsed: envFile,
      accounts: rows,
    },
    null,
    2,
  ),
);
