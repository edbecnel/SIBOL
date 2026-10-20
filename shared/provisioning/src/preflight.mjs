import { buildDemoCasePlans } from "./case_payloads.mjs";
import {
  CANONICAL_ROLES,
  DEMO_CASE_IDS,
  DEMO_USER_SPECS,
  EXPECTED_DEMO_PROJECT_ID,
} from "./constants.mjs";
import {
  assertProjectConfirmation,
  loadDemoPasswords,
  resolveProjectId,
} from "./config.mjs";
import {
  validateDemoUserSpec,
  validateFictionalCasePayload,
} from "./schema_validate.mjs";

/**
 * Local-only preflight (no Firebase I/O unless remoteRead adapter supplied).
 */
export function runLocalPreflight({ argv, requirePasswords = true }) {
  const projectId = resolveProjectId();
  const confirmProject = argv.find((a) => a.startsWith("--confirm-project="))?.split("=")[1] ?? null;
  const dryRun = argv.includes("--dry-run");

  const projectCheck = assertProjectConfirmation(projectId, confirmProject);
  if (!projectCheck.ok) {
    return { ok: false, stage: "project", message: projectCheck.message, dryRun };
  }

  const userErrors = [];
  for (const spec of DEMO_USER_SPECS) {
    userErrors.push(...validateDemoUserSpec(spec));
    if (!CANONICAL_ROLES.has(spec.role)) {
      userErrors.push(`non-canonical role: ${spec.role}`);
    }
  }

  const invalidCaseIds = DEMO_CASE_IDS.filter((id) => !/^demo-case-\d{3}$/.test(id));
  if (invalidCaseIds.length) {
    userErrors.push(`invalid demo case ids: ${invalidCaseIds.join(", ")}`);
  }

  const casePlans = buildDemoCasePlans();
  const caseErrors = [];
  for (const plan of casePlans) {
    caseErrors.push(...validateFictionalCasePayload(plan.case));
  }

  let passwordState = { users: [], missing: [] };
  if (requirePasswords) {
    passwordState = loadDemoPasswords();
    if (passwordState.missing.length) {
      return {
        ok: false,
        stage: "credentials",
        message: `Missing required environment variables: ${passwordState.missing.join(", ")}`,
        dryRun,
        projectId,
      };
    }
  }

  if (userErrors.length || caseErrors.length) {
    return {
      ok: false,
      stage: "validation",
      message: [...userErrors, ...caseErrors].join("; "),
      dryRun,
      projectId,
    };
  }

  return {
    ok: true,
    dryRun,
    projectId,
    expectedDemoProjectId: EXPECTED_DEMO_PROJECT_ID,
    users: passwordState.users.length ? passwordState.users : DEMO_USER_SPECS,
    casePlans,
    warnings:
      projectId !== EXPECTED_DEMO_PROJECT_ID
        ? [`Project ${projectId} is not the documented demo project ${EXPECTED_DEMO_PROJECT_ID}.`]
        : [],
  };
}

/**
 * Plans provisioning operations without performing writes.
 */
export function planProvisioningOperations({ users, casePlans, remoteSnapshot = null }) {
  const operations = [];

  for (const user of users) {
    const remoteUser = remoteSnapshot?.authByEmail?.[user.email];
    if (remoteUser) {
      operations.push({
        type: "auth_user_exists",
        email: user.email,
        uid: remoteUser.uid,
        action: "skip_create_preserve_password",
      });
      const profile = remoteSnapshot?.profiles?.[remoteUser.uid];
      if (profile) {
        if (profile.role !== user.role || profile.active !== true) {
          operations.push({
            type: "user_profile_conflict",
            email: user.email,
            uid: remoteUser.uid,
            action: "skip_update_preserve_role_and_active",
            existingRole: profile.role,
            existingActive: profile.active,
          });
        } else {
          operations.push({
            type: "user_profile_exists",
            email: user.email,
            uid: remoteUser.uid,
            action: "skip_update",
          });
        }
      } else {
        operations.push({
          type: "user_profile_create",
          email: user.email,
          uid: remoteUser.uid,
          role: user.role,
          action: "create_profile",
        });
      }
    } else {
      operations.push({
        type: "auth_user_create",
        email: user.email,
        role: user.role,
        action: "create_user_with_env_password",
      });
      operations.push({
        type: "user_profile_create",
        email: user.email,
        role: user.role,
        action: "create_profile_after_auth",
      });
    }
  }

  for (const plan of casePlans) {
    const existingCase = remoteSnapshot?.cases?.[plan.caseId];
    if (existingCase) {
      operations.push({
        type: "case_exists",
        caseId: plan.caseId,
        action: "skip_overwrite",
      });
    } else {
      operations.push({
        type: "case_create",
        caseId: plan.caseId,
        action: "create_case_and_follow_up",
      });
    }
  }

  return operations;
}

export function formatDryRunReport(preflight, operations) {
  const lines = [];
  lines.push(`SIBOL provisioning dry-run (no writes)`);
  lines.push(`Target project: ${preflight.projectId}`);
  lines.push(`Mode: local validation${operations.some((o) => o.uid) ? " + remote read snapshot" : ""}`);
  lines.push("");
  lines.push(`Demo users (${preflight.users.length}):`);
  for (const u of preflight.users) {
    lines.push(`  - ${u.email} role=${u.role}`);
  }
  lines.push(`Demo cases: ${DEMO_CASE_IDS.join(", ")}`);
  lines.push("");
  lines.push("Planned operations:");
  for (const op of operations) {
    lines.push(`  - [${op.type}] ${op.action}${op.caseId ? ` (${op.caseId})` : ""}${op.email ? ` (${op.email})` : ""}`);
  }
  if (preflight.warnings?.length) {
    lines.push("");
    lines.push("Warnings:");
    for (const w of preflight.warnings) {
      lines.push(`  - ${w}`);
    }
  }
  return lines.join("\n");
}
