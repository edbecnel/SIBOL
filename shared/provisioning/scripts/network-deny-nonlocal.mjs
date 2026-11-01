/**
 * Preload: deny outbound TCP to non-local hosts (Gate G network boundary).
 * Counts blocked attempts for evidence.
 */
import net from "node:net";
import tls from "node:tls";

const blockedHosts = [];
const allowedLocal = new Set(["127.0.0.1", "localhost", "::1", "[::1]"]);

function hostFromConnectArgs(args) {
  if (args.length === 0) return null;
  const first = args[0];
  if (typeof first === "object" && first !== null && "host" in first) {
    return String(first.host);
  }
  if (typeof first === "number") {
    return typeof args[1] === "string" ? args[1] : null;
  }
  return typeof first === "string" ? first : null;
}

function wrapConnect(original, label) {
  return function patchedConnect(...args) {
    const host = hostFromConnectArgs(args);
    if (host && !allowedLocal.has(host)) {
      blockedHosts.push({ label, host, when: Date.now() });
      const err = new Error(`NETWORK_DENY:${label}:${host}`);
      err.code = "NETWORK_DENY";
      throw err;
    }
    return original.apply(this, args);
  };
}

net.connect = wrapConnect(net.connect, "net.connect");
if (tls.connect) {
  tls.connect = wrapConnect(tls.connect, "tls.connect");
}

globalThis.__SIBOL_NETWORK_DENY__ = {
  blockedHosts,
  reset() {
    blockedHosts.length = 0;
  },
};
