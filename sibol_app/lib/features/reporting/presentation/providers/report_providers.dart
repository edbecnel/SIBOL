import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/reporting/data/repositories/report_repository_impl.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/reporting/domain/entities/moph_aggregate_report.dart';
import 'package:sibol_app/features/reporting/domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(firestoreProvider));
});

Stream<List<MophAggregateReport>> _mophSubmittedReportsStream(Ref ref) {
  final access = ref.watch(mophOperationalContextProvider);
  if (access.isLoading) {
    return const Stream<List<MophAggregateReport>>.empty();
  }
  if (access.hasError) {
    return Stream<List<MophAggregateReport>>.error(
      access.error!,
      access.stackTrace ?? StackTrace.empty,
    );
  }
  return ref.watch(reportRepositoryProvider).watchSubmittedReportsForMoph();
}

final mophSubmittedReportsProvider =
    StreamProvider<List<MophAggregateReport>>((ref) {
  return _mophSubmittedReportsStream(ref);
});

final mophReportDetailProvider =
    StreamProvider.family<MophAggregateReport?, String>((ref, reportId) {
  final access = ref.watch(mophOperationalContextProvider);
  if (access.isLoading) {
    return const Stream<MophAggregateReport?>.empty();
  }
  if (access.hasError) {
    return Stream<MophAggregateReport?>.error(
      access.error!,
      access.stackTrace ?? StackTrace.empty,
    );
  }
  return ref.watch(reportRepositoryProvider).watchReportForMoph(reportId);
});

final barangaySubmittedReportsProvider =
    StreamProvider<List<MophAggregateReport>>((ref) {
  final orgId = ref.watch(barangayReportOrgIdProvider);
  if (orgId == null) {
    return Stream.error(
      StateError('Organization context is not available for barangay reports.'),
    );
  }
  return ref.watch(reportRepositoryProvider).watchReportsForOrg(orgId);
});

final barangayReportReceiptProvider =
    StreamProvider.family<MophAggregateReport?, String>((ref, reportId) {
  final orgId = ref.watch(barangayReportOrgIdProvider);
  if (orgId == null) {
    return const Stream.empty();
  }
  return ref.watch(reportRepositoryProvider).watchReportForOrg(reportId, orgId);
});

final barangayReportAggregateProvider =
    Provider<AsyncValue<BarangayReportAggregateCounts?>>((ref) {
  final orgPresentation = ref.watch(barangayReportOrgPresentationProvider);
  final casesAsync = ref.watch(casesStreamProvider);
  return orgPresentation.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (presentation) {
      final orgId = ref.watch(barangayReportOrgIdProvider);
      if (orgId == null) {
        return AsyncError(
          StateError('Organization context is not available for barangay reports.'),
          StackTrace.current,
        );
      }
      return casesAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (snapshot) => AsyncData(
          computeBarangayReportAggregate(
            cases: snapshot.items.map((e) => e.record).toList(),
            orgId: orgId,
            barangay: presentation.siteLabel,
          ),
        ),
      );
    },
  );
});
