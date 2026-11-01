/**
 * Gate G worker (spawned with network-deny-nonlocal preload).
 */
import { assertAdminSdkTestIsolation } from "../src/admin_test_isolation.mjs";

const label = process.argv[2] ?? "unknown";
const deny = globalThis.__SIBOL_NETWORK_DENY__;

function report(marker, extra = "") {
  const blocked = deny?.blockedHosts?.length ?? 0;
  console.log(
    `${marker} label=${label} blockedNonLocalAttempts=${blocked}${extra ? ` ${extra}` : ""}`,
  );
}

try {
  if (process.env.SIBOL_GATE_G_DIRECT === "1") {
    // Simulates direct script entry without shell wrapper — guard must still run first.
    assertAdminSdkTestIsolation();
  } else {
    assertAdminSdkTestIsolation();
  }

  if (label === "valid-emulator-local-only") {
    const { initializeApp, getApps, deleteApp } = await import("firebase-admin/app");
    const { getFirestore } = await import("firebase-admin/firestore");
    for (const app of getApps()) {
      await deleteApp(app);
    }
    initializeApp({ projectId: process.env.FIREBASE_PROJECT_ID });
    const db = getFirestore();
    await db.collection("_gate_g_probe").doc("ping").set({ ok: true, t: Date.now() });
    report("LOCAL_EMULATOR_OK");
    process.exit(0);
  }

  report("UNEXPECTED_PASS");
  process.exit(2);
} catch (err) {
  const blocked = deny?.blockedHosts?.length ?? 0;
  if (blocked > 0) {
    report("FAIL_NETWORK_BEFORE_GUARD", err.message);
    process.exit(3);
  }
  report("REJECTED_BEFORE_ADMIN_INIT", err.message);
  process.exit(0);
}
