import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/config/app_config.dart';
import 'package:sibol_app/core/router/app_router.dart';
import 'package:sibol_app/core/theme/app_theme.dart';
import 'package:sibol_app/features/offline/presentation/offline_sync_host.dart';

class SibolApp extends ConsumerWidget {
  const SibolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return OfflineSyncHost(
      child: MaterialApp.router(
        title: AppConfig.appName,
        theme: AppTheme.light(),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
