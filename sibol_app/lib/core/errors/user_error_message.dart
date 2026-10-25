import 'package:cloud_functions/cloud_functions.dart';
import 'package:sibol_app/core/errors/app_exception.dart';
import 'package:sibol_app/core/errors/failure.dart';

/// User-visible error text without stack traces or type names.
String userErrorMessage(Object error) {
  if (error is Failure) return error.message;
  if (error is AppException) return error.toFailure().message;
  if (error is FirebaseFunctionsException) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      if (message.contains('not registered in SIBOL')) {
        return 'This Barangay is not yet registered for assistance routing in SIBOL. '
            'Choose another Barangay or contact your administrator.';
      }
      return message;
    }
    return 'Request failed. Check your connection and try again.';
  }
  return 'Something went wrong. Please try again.';
}
