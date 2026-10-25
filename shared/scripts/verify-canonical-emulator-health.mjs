#!/usr/bin/env node
/**
 * Non-destructive health check for canonical SIBOL emulators (9099/8195/5001).
 */
import { createConnection } from "node:net";
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const AUTH_PORT = 9099;
const FIRESTORE_PORT = 8195;
const FUNCTIONS_PORT = 5001;
const PROJECT = "sibol-286d0";
const REGION = "us-central1";

const REQUIRED_CALLABLES = [
  "regSubmitTeenAssistanceRequest",
  "regAcknowledgeTeenAssistanceRequest",
  "createCoordinationReferral",
];

function checkPort(port) {
  return new Promise((resolve) => {
    const socket = createConnection({ host: "127.0.0.1", port }, () => {
      socket.end();
      resolve(true);
    });
    socket.on("error", () => resolve(false));
    socket.setTimeout(2000, () => {
      socket.destroy();
      resolve(false);
    });
  });
}

async function checkCallable(name) {
  const res = await fetch(
    `http://127.0.0.1:${FUNCTIONS_PORT}/${PROJECT}/${REGION}/${name}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ data: {} }),
    },
  );
  const body = await res.json();
  if (res.status === 401 && body?.error?.status === "UNAUTHENTICATED") {
    return { name, ok: true };
  }
  if (res.status === 200 && body?.result) {
    return { name, ok: true };
  }
  return { name, ok: false, status: res.status, body };
}

async function main() {
  const ports = {
    auth: await checkPort(AUTH_PORT),
    firestore: await checkPort(FIRESTORE_PORT),
    functions: await checkPort(FUNCTIONS_PORT),
  };
  console.log("ports", ports);
  if (!ports.auth || !ports.firestore || !ports.functions) {
    console.error("FAIL: canonical emulator ports not all listening");
    process.exit(1);
  }

  const callableResults = [];
  for (const name of REQUIRED_CALLABLES) {
    callableResults.push(await checkCallable(name));
  }
  console.log("callables", callableResults);
  if (callableResults.some((r) => !r.ok)) {
    console.error("FAIL: required callables not registered");
    process.exit(1);
  }

  const qaScript = join(
    dirname(fileURLToPath(import.meta.url)),
    "../functions/scripts/verify-canonical-qa-anchors.mjs",
  );
  const qa = spawnSync("node", [qaScript], {
    encoding: "utf8",
    env: { ...process.env, FIRESTORE_EMULATOR_HOST: `127.0.0.1:${FIRESTORE_PORT}` },
  });
  if (qa.stdout) process.stdout.write(qa.stdout);
  if (qa.status !== 0) {
    if (qa.stderr) process.stderr.write(qa.stderr);
    process.exit(qa.status ?? 1);
  }

  console.log("OK: canonical emulator health verified");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
