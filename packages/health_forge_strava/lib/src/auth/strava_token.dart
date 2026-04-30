/// Immutable representation of a Strava OAuth 2.0 token set.
class StravaToken {
  /// Creates a Strava token set.
  const StravaToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// Deserializes from JSON.
  factory StravaToken.fromJson(Map<String, dynamic> json) => StravaToken(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  /// The OAuth 2.0 access token for API requests.
  final String accessToken;

  /// The refresh token used to obtain new access tokens.
  final String refreshToken;

  /// The date and time when [accessToken] expires.
  final DateTime expiresAt;

  /// Whether the access token has passed its expiry time.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      };
}
