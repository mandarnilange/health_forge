/// URL constants for the Oura Ring REST API.
class OuraApiEndpoints {
  const OuraApiEndpoints._();

  /// Base URL for the Oura API.
  static const baseUrl = 'https://api.ouraring.com';

  /// API version string.
  static const apiVersion = 'v2';

  /// OAuth 2.0 authorization endpoint.
  static const authorizeUrl = 'https://cloud.ouraring.com/oauth/authorize';

  /// OAuth 2.0 token exchange endpoint.
  static const tokenUrl = 'https://api.ouraring.com/oauth/token';

  /// Detailed sleep data endpoint.
  static const sleep = '/v2/usercollection/sleep';

  /// Daily sleep score endpoint.
  static const dailySleep = '/v2/usercollection/daily_sleep';

  /// Daily activity data endpoint.
  static const dailyActivity = '/v2/usercollection/daily_activity';

  /// Heart rate samples endpoint.
  static const heartRate = '/v2/usercollection/heartrate';

  /// Daily readiness data endpoint.
  static const dailyReadiness = '/v2/usercollection/daily_readiness';

  /// Daily stress data endpoint.
  static const dailyStress = '/v2/usercollection/daily_stress';

  /// Daily SpO2 data endpoint.
  static const dailySpo2 = '/v2/usercollection/daily_spo2';
}
