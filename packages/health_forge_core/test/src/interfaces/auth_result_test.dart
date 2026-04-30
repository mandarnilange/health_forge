import 'package:health_forge_core/src/interfaces/auth_result.dart';
import 'package:health_forge_core/src/interfaces/auth_status.dart';
import 'package:test/test.dart';

void main() {
  group('AuthResult', () {
    group('success', () {
      test('has connected status', () {
        final result = AuthResult.success();
        expect(result.status, AuthStatus.connected);
      });

      test('isSuccess is true', () {
        final result = AuthResult.success();
        expect(result.isSuccess, isTrue);
      });

      test('errorMessage is null', () {
        final result = AuthResult.success();
        expect(result.errorMessage, isNull);
      });
    });

    group('denied', () {
      test('has disconnected status', () {
        final result = AuthResult.denied();
        expect(result.status, AuthStatus.disconnected);
      });

      test('isSuccess is false', () {
        final result = AuthResult.denied();
        expect(result.isSuccess, isFalse);
      });

      test('has permission denied error message', () {
        final result = AuthResult.denied();
        expect(result.errorMessage, 'Permission denied');
      });
    });

    group('error', () {
      test('has disconnected status', () {
        final result = AuthResult.error('Something went wrong');
        expect(result.status, AuthStatus.disconnected);
      });

      test('isSuccess is false', () {
        final result = AuthResult.error('Something went wrong');
        expect(result.isSuccess, isFalse);
      });

      test('has provided error message', () {
        final result = AuthResult.error('Something went wrong');
        expect(result.errorMessage, 'Something went wrong');
      });
    });

    group('expired', () {
      test('has expired status', () {
        final result = AuthResult.expired();
        expect(result.status, AuthStatus.expired);
      });

      test('isSuccess is false', () {
        final result = AuthResult.expired();
        expect(result.isSuccess, isFalse);
      });

      test('errorMessage is null', () {
        final result = AuthResult.expired();
        expect(result.errorMessage, isNull);
      });
    });
  });
}
