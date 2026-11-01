import { CoordinationStatus } from "./coordinationStatus";

/** Coordination states that satisfy COMM-ORD-1 (MOPH receipt recorded). */
export const CASE_OPEN_ALLOWED_COORDINATION_STATUSES: ReadonlySet<string> =
  new Set([
    CoordinationStatus.received,
    CoordinationStatus.acceptedForCoordination,
    CoordinationStatus.additionalInformationRequested,
    CoordinationStatus.informationProvided,
    CoordinationStatus.unableToAccommodate,
    CoordinationStatus.coordinationCompleted,
  ]);

export function coordinationStatusAllowsCaseOpen(status: string): boolean {
  return CASE_OPEN_ALLOWED_COORDINATION_STATUSES.has(status);
}
