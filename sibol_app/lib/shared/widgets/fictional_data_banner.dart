import 'package:flutter/material.dart';
import 'package:sibol_app/config/app_config.dart';

class FictionalDataBanner extends StatelessWidget {
  const FictionalDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(AppConfig.fictionalDataNotice),
      leading: const Icon(Icons.info_outline),
      backgroundColor: Colors.amber.shade50,
      actions: const [SizedBox.shrink()],
    );
  }
}
