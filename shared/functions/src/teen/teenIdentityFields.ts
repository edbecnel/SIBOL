import { AuthzError } from "../authz/assert";

const DOB_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const MIN_ADOLESCENT_AGE = 10;
const MAX_ADOLESCENT_AGE = 19;

function parseDob(raw: string): { year: number; month: number; day: number } | null {
  const trimmed = raw.trim();
  if (!DOB_PATTERN.test(trimmed)) return null;
  const [y, m, d] = trimmed.split("-").map((p) => Number.parseInt(p, 10));
  if (!Number.isFinite(y) || !Number.isFinite(m) || !Number.isFinite(d)) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  const date = new Date(y, m - 1, d);
  if (date.getFullYear() !== y || date.getMonth() !== m - 1 || date.getDate() !== d) {
    return null;
  }
  return { year: y, month: m, day: d };
}

function adolescentAgeOn(dob: { year: number; month: number; day: number }, on: Date): number {
  let age = on.getFullYear() - dob.year;
  const hadBirthday =
    on.getMonth() + 1 > dob.month ||
    (on.getMonth() + 1 === dob.month && on.getDate() >= dob.day);
  if (!hadBirthday) age -= 1;
  return age;
}

export type TeenIdentityFields = {
  displayName: string;
  dateOfBirth: string;
  contactEmail?: string;
  contactPhone?: string;
};

export function resolveTeenIdentityFields(data: {
  displayName?: string;
  dateOfBirth?: string;
  contactEmail?: string;
  contactPhone?: string;
}): TeenIdentityFields {
  const displayName =
    typeof data.displayName === "string" ? data.displayName.trim() : "";
  if (displayName.length < 2) {
    throw new AuthzError("Full name is required.", "invalid-argument");
  }

  const dateOfBirth =
    typeof data.dateOfBirth === "string" ? data.dateOfBirth.trim() : "";
  const parsedDob = parseDob(dateOfBirth);
  if (!parsedDob) {
    throw new AuthzError(
      "Enter a valid date of birth (YYYY-MM-DD).",
      "invalid-argument",
    );
  }
  const today = new Date();
  const onDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const birth = new Date(parsedDob.year, parsedDob.month - 1, parsedDob.day);
  if (birth > onDay) {
    throw new AuthzError("Date of birth cannot be in the future.", "invalid-argument");
  }
  const age = adolescentAgeOn(parsedDob, onDay);
  if (age < MIN_ADOLESCENT_AGE || age > MAX_ADOLESCENT_AGE) {
    throw new AuthzError(
      `Age must be between ${MIN_ADOLESCENT_AGE} and ${MAX_ADOLESCENT_AGE} for this prototype.`,
      "invalid-argument",
    );
  }

  const contactEmail =
    typeof data.contactEmail === "string" && data.contactEmail.trim()
      ? data.contactEmail.trim()
      : undefined;
  const contactPhone =
    typeof data.contactPhone === "string" && data.contactPhone.trim()
      ? data.contactPhone.trim()
      : undefined;

  if (!contactEmail && !contactPhone) {
    throw new AuthzError(
      "Provide a contact email or phone number.",
      "invalid-argument",
    );
  }
  if (contactEmail && contactEmail.length < 5) {
    throw new AuthzError("Enter a valid contact email.", "invalid-argument");
  }
  if (contactPhone && contactPhone.length < 7) {
    throw new AuthzError("Enter a valid contact phone number.", "invalid-argument");
  }

  return {
    displayName,
    dateOfBirth,
    contactEmail,
    contactPhone,
  };
}
