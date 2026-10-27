#!/usr/bin/env node
/**
 * Read-only inventory of a firebase emulators:export directory.
 * Does not print password hashes or localId secrets.
 */
import { readFileSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";

const exportDir = resolve(
  process.argv[2] ??
    ".firebase-qa-backups/po-case-identity-prep-20261026-1832",
);

function loadAuthEmails(dir) {
  const path = join(dir, "auth_export", "accounts.json");
  if (!existsSync(path)) {
    return { error: `missing ${path}`, emails: [] };
  }
  const raw = JSON.parse(readFileSync(path, "utf8"));
  const users = raw.users ?? [];
  return {
    count: users.length,
    emails: users
      .map((u) => u.email)
      .filter(Boolean)
      .sort(),
    providers: users.map((u) => ({
      email: u.email ?? "(no email)",
      providerCount: (u.providerUserInfo ?? []).length,
    })),
  };
}

function loadMetadata(dir) {
  const path = join(dir, "firebase-export-metadata.json");
  if (!existsSync(path)) return null;
  return JSON.parse(readFileSync(path, "utf8"));
}

const auth = loadAuthEmails(exportDir);
const metadata = loadMetadata(exportDir);

const fictionalDemoEmails = new Set([
  "teen.demo@sibol.local",
  "barangay.demo@sibol.local",
  "moph.demo@sibol.local",
  "central.admin@sibol.local",
  "barangay.org.admin@sibol.local",
  "backup.barangay.admin@sibol.local",
  "moph.org.admin@sibol.local",
]);

const qaLike = (auth.emails ?? []).filter(
  (e) =>
    !fictionalDemoEmails.has(e) &&
    (e.includes(".qa.") || e.includes("qa") || e.includes("example.com")),
);

console.log(
  JSON.stringify(
    {
      exportDir,
      metadata,
      auth: {
        count: auth.count,
        emails: auth.emails,
        qaOrNonDemoEmails: qaLike,
        note:
          "Firestore document counts are not parsed from export files; use live inventory or emulators:import + Admin SDK for collection counts.",
      },
    },
    null,
    2,
  ),
);
