import 'package:uuid/uuid.dart';

/// Generates unique identifiers for health records.
class IdGenerator {
  static const _uuid = Uuid();

  /// Generates a new UUID v4 string.
  static String generate() => _uuid.v4();
}
