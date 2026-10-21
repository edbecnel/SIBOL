import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/features/reporting/data/repositories/report_repository_impl.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/reporting/domain/entities/moph_aggregate_report.dart';
import 'package:sibol_app/features/reporting/domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(firestoreProvider));
});

final mophSubmittedReportsProvider =
    StreamProvider<List<MophAggregateReport>>((ref) {
  return ref.watch(reportRepositoryProvider).watchSubmittedReportsForMoph();
});

final mophReportDetailProvider =
    StreamProvider.family<MophAggregateReport?, String>((ref, reportId) {
  return ref.watch(reportRepositoryProvider).watchReportForMoph(reportId);
});

final barangayReportAggregateProvider =
    Provider<AsyncValue<BarangayReportAggregateCounts?>>((ref) {
  final profile = ref.watch(userProfileProvider);
  final casesAsync = ref.watch(casesStreamProvider);
  return profile.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (user) {
      if (user == null || user.assignedBarangay == null) {
        return const AsyncData(null);
      }
      return casesAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (cases) => AsyncData(
          computeBarangayReportAggregate(
            cases: cases,
            barangay: user.assignedBarangay!,
          ),
        ),
      );
    },
  );
});
