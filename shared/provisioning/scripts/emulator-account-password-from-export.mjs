#!/usr/bin/env node
/**
 * Reads emulator Auth export fakeHash password for one account email.
 * For local device/integration use only — never commit output.
 *
 * Usage: node emulator-account-password-from-export.mjs <accounts.json> <email>
 */
import { readFileSync } from "node:fs";

const [accountsPath, email] = process.argv.slice(2);
if (!accountsPath || !email) {
  process.stderr.write("usage: emulator-account-password-from-export.mjs <accounts.json> <email>\n");
  process.exit(1);
}
const users = JSON.parse(readFileSync(accountsPath, "utf8")).users ?? [];
const user = users.find((u) => u.email === email);
if (!user?.passwordHash) {
  process.exit(2);
}
const marker = ":password=";
const idx = user.passwordHash.indexOf(marker);
if (idx < 0) {
  process.exit(3);
}
process.stdout.write(user.passwordHash.slice(idx + marker.length));
