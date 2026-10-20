import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/config/app_config.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  static const _authErrorMessage =
      'Could not verify sign-in status. Please try again.';
  static const _profileErrorMessage =
      'Could not load your profile. Please try again.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final Widget statusChild;
    if (authAsync.hasError) {
      if (kDebugMode) {
        debugPrint('SIBOL startup auth error: ${authAsync.error}');
      }
      statusChild = AppErrorWidget(
        message: _authErrorMessage,
        onRetry: () => retryStartup(ref),
      );
    } else if (authAsync.value != null && profileAsync.hasError) {
      if (kDebugMode) {
        debugPrint('SIBOL startup profile error: ${profileAsync.error}');
      }
      statusChild = AppErrorWidget(
        message: _profileErrorMessage,
        onRetry: () => retryStartup(ref),
      );
    } else {
      statusChild = const AppLoadingIndicator(message: 'Starting…');
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/sibol_logo.png',
                    height: 96,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.local_hospital, size: 96),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  statusChild,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
