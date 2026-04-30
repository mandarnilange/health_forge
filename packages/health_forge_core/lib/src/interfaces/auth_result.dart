import 'package:health_forge_core/src/interfaces/auth_status.dart';

/// The result of an authorization attempt with a health data provider.
class AuthResult {
  /// Creates a successful authorization result.
  AuthResult.success() : status = AuthStatus.connected, errorMessage = null;

  /// Creates a denied authorization result.
  AuthResult.denied()
    : status = AuthStatus.disconnected,
      errorMessage = 'Permission denied';

  /// Creates an error authorization result with a message.
  AuthResult.error(String message)
    : status = AuthStatus.disconnected,
      errorMessage = message;

  /// Creates an expired authorization result.
  AuthResult.expired() : status = AuthStatus.expired, errorMessage = null;

  /// The authorization status.
  final AuthStatus status;

  /// An optional error message describing what went wrong.
  final String? errorMessage;

  /// Whether the authorization was successful.
  bool get isSuccess => status == AuthStatus.connected;
}
