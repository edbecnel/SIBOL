import { DEMO_USER_SPECS } from "./constants.mjs";

export function parseArgv(argv) {
  const flags = {
    confirmProject: null,
    dryRun: false,
    remoteRead: false,
  };

  for (const arg of argv) {
    if (arg === "--dry-run") {
      flags.dryRun = true;
    } else if (arg === "--remote-read") {
      flags.remoteRead = true;
    } else if (arg.startsWith("--confirm-project=")) {
      flags.confirmProject = arg.split("=")[1];
    }
  }

  return flags;
}

export function resolveProjectId() {
  return process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || null;
}

/**
 * Loads demo passwords from environment. Never log returned values.
 */
export function loadDemoPasswords() {
  const users = [];
  const missing = [];

  for (const spec of DEMO_USER_SPECS) {
    const password = process.env[spec.passwordEnvVar];
    if (!password || !String(password).trim()) {
      missing.push(spec.passwordEnvVar);
      continue;
    }
    users.push({
      ...spec,
      password: String(password),
    });
  }

  return { users, missing };
}

export function assertProjectConfirmation(projectId, confirmProject) {
  if (!projectId) {
    return {
      ok: false,
      message: "Set FIREBASE_PROJECT_ID (or GCLOUD_PROJECT) before running.",
    };
  }
  if (!confirmProject) {
    return {
      ok: false,
      message: `Refusing to run: pass --confirm-project=${projectId} to acknowledge the target project.`,
    };
  }
  if (confirmProject !== projectId) {
    return {
      ok: false,
      message: `Project mismatch: FIREBASE_PROJECT_ID=${projectId} but --confirm-project=${confirmProject}.`,
    };
  }
  return { ok: true };
}
