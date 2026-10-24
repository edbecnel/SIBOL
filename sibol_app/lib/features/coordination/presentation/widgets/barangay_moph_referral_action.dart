import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';

/// Referral CTA on Barangay incoming request detail (acknowledged requests only).
class BarangayMophReferralAction extends StatelessWidget {
  const BarangayMophReferralAction({
    super.key,
    required this.isAcknowledged,
    required this.referralExistsAsync,
    required this.onReferPressed,
  });

  final bool isAcknowledged;
  final AsyncValue<bool> referralExistsAsync;
  final VoidCallback onReferPressed;

  @override
  Widget build(BuildContext context) {
    if (!isAcknowledged) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: referralExistsAsync.when(
        loading: () => AppButton.primary(
          label: 'Refer to MOPH coordination',
          isLoading: true,
          onPressed: null,
        ),
        error: (e, _) => AppErrorWidget(
          message:
              'Could not verify whether a MOPH referral was already submitted: $e',
        ),
        data: (exists) {
          if (exists) {
            return const Text(
              'MOPH coordination referral already submitted for this request.',
            );
          }
          return AppButton.primary(
            label: 'Refer to MOPH coordination',
            onPressed: onReferPressed,
          );
        },
      ),
    );
  }
}
