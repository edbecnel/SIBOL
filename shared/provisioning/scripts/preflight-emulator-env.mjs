#!/usr/bin/env node
import { assertEmulatorEnvironment } from "../src/emulator_guard.mjs";

const checkReachable = process.argv.includes("--check-reachable");
const result = await assertEmulatorEnvironment({
  confirmFlag: true,
  checkReachable,
});
if (!result.ok) {
  console.error(result.message);
  process.exit(1);
}
console.log("OK: emulator environment validated (canonical ports, local hosts).");
