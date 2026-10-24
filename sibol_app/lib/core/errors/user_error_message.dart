import 'package:sibol_app/core/errors/app_exception.dart';
import 'package:sibol_app/core/errors/failure.dart';

/// User-visible error text without stack traces or type names.
String userErrorMessage(Object error) {
  if (error is Failure) return error.message;
  if (error is AppException) return error.toFailure().message;
  return 'Something went wrong. Please try again.';
}
