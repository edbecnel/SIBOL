import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';

class OfflineSyncHost extends ConsumerStatefulWidget {
  const OfflineSyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OfflineSyncHost> createState() => _OfflineSyncHostState();
}

class _OfflineSyncHostState extends ConsumerState<OfflineSyncHost>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = Connectivity().onConnectivityChanged.listen((_) => _sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final uid = ref.read(authStateChangesProvider).value?.uid;
      if (uid != null) {
        ref.invalidate(pendingOperationsProvider(uid));
      }
    }
  }

  Future<void> _sync() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;
    await ref.read(offlineSyncServiceProvider).syncForUser(uid);
    ref.invalidate(pendingOperationsProvider(uid));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateChangesProvider, (prev, next) {
      final uid = next.value?.uid;
      if (uid != null) {
        _sync();
      }
    });
    return widget.child;
  }
}
