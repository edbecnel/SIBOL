import { randomBytes } from "node:crypto";

const ORG_ALPHABET =
  "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

function randomSuffix(length: number): string {
  const bytes = randomBytes(length);
  let out = "";
  for (let i = 0; i < length; i++) {
    out += ORG_ALPHABET[bytes[i] % ORG_ALPHABET.length];
  }
  return out;
}

export function generateOrgId(): string {
  return `org${randomSuffix(22)}`;
}

export function generateInvitationId(): string {
  return `inv_${randomSuffix(22)}`;
}

export function generateAuditEventId(): string {
  return `aud_${randomSuffix(22)}`;
}
