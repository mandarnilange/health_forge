/// Immutable representation of an Oura OAuth 2.0 token set.
class OuraToken {
  /// Creates an Oura token set.
  const OuraToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// Deserializes from JSON.
  factory OuraToken.fromJson(Map<String, dynamic> json) => OuraToken(
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
