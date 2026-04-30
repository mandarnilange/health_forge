import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/interfaces/auth_result.dart';
import 'package:health_forge_core/src/interfaces/provider_capability.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/time_range.dart';

/// Abstract interface for a health data provider.
abstract class HealthProvider {
  /// The type of this provider.
  DataProvider get providerType;

  /// Human-readable name of this provider.
  String get displayName;

  /// The capabilities of this provider.
  ProviderCapabilities get capabilities;

  /// Whether the provider is currently authorized.
  Future<bool> isAuthorized();

  /// Requests authorization from the provider.
  Future<AuthResult> authorize();

  /// Revokes authorization from the provider.
  Future<void> deauthorize();

  /// Fetches health records for the given [metricType] within [timeRange].
  Future<List<HealthRecordMixin>> fetchRecords({
    required MetricType metricType,
    required TimeRange timeRange,
  });
}
