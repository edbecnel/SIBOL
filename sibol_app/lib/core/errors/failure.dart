import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure({required this.code, required super.message});

  final String code;

  @override
  List<Object?> get props => [code, message];
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super(message: 'No internet connection');
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}
