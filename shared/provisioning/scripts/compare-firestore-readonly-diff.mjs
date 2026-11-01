#!/usr/bin/env node
/**
 * Deterministic diff of two compare-firestore-readonly-inventory.mjs outputs.
 * Usage: node compare-firestore-readonly-diff.mjs backup.json live.json
 */
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";

function loadInventory(path) {
  const text = readFileSync(path, "utf8").trim();
  const start = text.indexOf('{"projectId"');
  const jsonText = start >= 0 ? text.slice(start) : text;
  const end = jsonText.lastIndexOf("}");
  return JSON.parse(jsonText.slice(0, end + 1));
}

function pathHash(path) {
  return createHash("sha256").update(path).digest("hex").slice(0, 12);
}

function topCollection(path) {
  return path.split("/")[0];
}

function countByCollection(paths) {
  const out = {};
  for (const p of paths) {
    const c = topCollection(p);
    out[c] = (out[c] || 0) + 1;
  }
  return out;
}

const [backupPath, livePath] = process.argv.slice(2);
if (!backupPath || !livePath) {
  console.error("Usage: node compare-firestore-readonly-diff.mjs <backup-inventory.json> <live-inventory.json>");
  process.exit(1);
}

const backup = loadInventory(backupPath);
const live = loadInventory(livePath);
const b = backup.documents;
const l = live.documents;
const all = new Set([...Object.keys(b), ...Object.keys(l)]);

const added = [];
const deleted = [];
const modified = [];
const unchanged = [];

for (const path of [...all].sort()) {
  const inB = path in b;
  const inL = path in l;
  if (inB && inL) {
    if (b[path] === l[path]) unchanged.push(path);
    else modified.push({ path, pathHash: pathHash(path), backupFp: b[path], liveFp: l[path] });
  } else if (inL) added.push({ path, pathHash: pathHash(path) });
  else deleted.push({ path, pathHash: pathHash(path) });
}

const summary = {
  backup: { projectId: backup.projectId, count: backup.count },
  live: { projectId: live.projectId, count: live.count },
  unchanged: unchanged.length,
  added: added.length,
  deleted: deleted.length,
  modified: modified.length,
  notComparable: 0,
  byCollection: {
    backup: countByCollection(Object.keys(b)),
    live: countByCollection(Object.keys(l)),
    added: countByCollection(added.map((x) => x.path)),
    deleted: countByCollection(deleted.map((x) => x.path)),
    modified: countByCollection(modified.map((x) => x.path)),
    unchanged: countByCollection(unchanged),
  },
  added,
  deleted,
  modified,
};

process.stdout.write(`${JSON.stringify(summary, null, 2)}\n`);
