import type { Firestore } from "firebase-admin/firestore";
import {
  CASE_COLLECTION,
  LIFECYCLE_EVENTS,
} from "./caseLifecycleConstants";

export type LifecycleEventPayload = {
  eventType: string;
  actorUid: string;
  createdAt: Date;
  previousStatus?: string;
  newStatus?: string;
  reasonOrOutcome?: string;
  assignedCoordinatorUid?: string;
};

export function appendLifecycleEventInTransaction(
  tx: FirebaseFirestore.Transaction,
  db: Firestore,
  caseId: string,
  payload: LifecycleEventPayload,
): void {
  const ref = db
    .collection(CASE_COLLECTION)
    .doc(caseId)
    .collection(LIFECYCLE_EVENTS)
    .doc();
  tx.set(ref, {
    eventType: payload.eventType,
    actorUid: payload.actorUid,
    createdAt: payload.createdAt,
    ...(payload.previousStatus != null
      ? { previousStatus: payload.previousStatus }
      : {}),
    ...(payload.newStatus != null ? { newStatus: payload.newStatus } : {}),
    ...(payload.reasonOrOutcome != null
      ? { reasonOrOutcome: payload.reasonOrOutcome }
      : {}),
    ...(payload.assignedCoordinatorUid != null
      ? { assignedCoordinatorUid: payload.assignedCoordinatorUid }
      : {}),
  });
}
