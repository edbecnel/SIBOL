import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/router/app_navigator_key.dart';
import 'package:sibol_app/core/router/app_redirect.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sibol_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:sibol_app/features/cases/presentation/screens/barangay_home_screen.dart';
import 'package:sibol_app/features/cases/presentation/screens/case_detail_screen.dart';
import 'package:sibol_app/features/cases/presentation/screens/case_edit_screen.dart';
import 'package:sibol_app/features/moph/presentation/screens/moph_home_screen.dart';
import 'package:sibol_app/features/coordination/presentation/screens/barangay_coordination_detail_screen.dart';
import 'package:sibol_app/features/coordination/presentation/screens/barangay_coordination_referral_screen.dart';
import 'package:sibol_app/features/coordination/presentation/screens/barangay_submitted_referrals_screen.dart';
import 'package:sibol_app/features/moph/presentation/screens/moph_coordination_detail_screen.dart';
import 'package:sibol_app/features/moph/presentation/screens/moph_report_detail_screen.dart';
import 'package:sibol_app/features/reporting/presentation/screens/barangay_report_receipt_screen.dart';
import 'package:sibol_app/features/reporting/presentation/screens/barangay_submit_report_screen.dart';
import 'package:sibol_app/features/reporting/presentation/screens/barangay_submitted_reports_screen.dart';
import 'package:sibol_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sibol_app/features/teenager/presentation/screens/barangay_incoming_request_detail_screen.dart';
import 'package:sibol_app/features/teenager/presentation/screens/barangay_incoming_requests_screen.dart';
import 'package:sibol_app/features/teenager/presentation/screens/assistance_request_detail_screen.dart';
import 'package:sibol_app/features/teenager/presentation/screens/assistance_request_form_screen.dart';
import 'package:sibol_app/features/teenager/presentation/screens/assistance_request_list_screen.dart';
import 'package:sibol_app/features/teenager/presentation/screens/teen_home_screen.dart';
import 'package:sibol_app/features/auth/presentation/screens/unauthorized_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      return resolveAppRedirect(
        location: state.matchedLocation,
        authAsync: ref.read(authStateChangesProvider),
        profileAsync: ref.read(userProfileProvider),
      );
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.unauthorized,
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: Routes.teenHome,
        builder: (context, state) => const TeenHomeScreen(),
        routes: [
          GoRoute(
            path: Routes.teenAssistanceSegment,
            builder: (context, state) => const AssistanceRequestListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    const AssistanceRequestFormScreen(),
              ),
              GoRoute(
                path: ':requestId',
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId']!;
                  return AssistanceRequestDetailScreen(requestId: requestId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.barangayHome,
        builder: (context, state) => const BarangayHomeScreen(),
        routes: [
          GoRoute(
            path: Routes.barangayIncomingRequestsSegment,
            builder: (context, state) =>
                const BarangayIncomingRequestsScreen(),
            routes: [
              GoRoute(
                path: ':requestId',
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId']!;
                  return BarangayIncomingRequestDetailScreen(
                    requestId: requestId,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'coordination-referral',
                    builder: (context, state) {
                      final requestId = state.pathParameters['requestId']!;
                      return BarangayCoordinationReferralScreen(
                        assistanceRequestId: requestId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '${Routes.barangayCaseSegment}/new',
            builder: (context, state) => const CaseEditScreen(),
          ),
          GoRoute(
            path: '${Routes.barangayCaseSegment}/:caseId/edit',
            builder: (context, state) {
              final caseId = state.pathParameters['caseId']!;
              return CaseEditScreen(caseId: caseId);
            },
          ),
          GoRoute(
            path: '${Routes.barangayCaseSegment}/:caseId',
            builder: (context, state) {
              final caseId = state.pathParameters['caseId']!;
              return CaseDetailScreen(caseId: caseId);
            },
          ),
          GoRoute(
            path: 'reports/submit',
            builder: (context, state) => const BarangaySubmitReportScreen(),
          ),
          GoRoute(
            path: Routes.barangaySubmittedReportsSegment,
            builder: (context, state) =>
                const BarangaySubmittedReportsScreen(),
            routes: [
              GoRoute(
                path: ':reportId',
                builder: (context, state) {
                  final reportId = state.pathParameters['reportId']!;
                  return BarangayReportReceiptScreen(reportId: reportId);
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.barangaySubmittedReferralsSegment,
            builder: (context, state) =>
                const BarangaySubmittedReferralsScreen(),
            routes: [
              GoRoute(
                path: ':threadId',
                builder: (context, state) {
                  final threadId = state.pathParameters['threadId']!;
                  return BarangayCoordinationDetailScreen(threadId: threadId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.mophHome,
        builder: (context, state) => const MophHomeScreen(),
        routes: [
          GoRoute(
            path: '${Routes.mophCoordinationSegment}/:threadId',
            builder: (context, state) {
              final threadId = state.pathParameters['threadId']!;
              return MophCoordinationDetailScreen(threadId: threadId);
            },
          ),
          GoRoute(
            path: '${Routes.mophReportsSegment}/:reportId',
            builder: (context, state) {
              final reportId = state.pathParameters['reportId']!;
              return MophReportDetailScreen(reportId: reportId);
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
