/// Authorization status of a health data provider.
enum AuthStatus {
  /// Provider is authorized and connected.
  connected,

  /// Provider is not authorized or has been disconnected.
  disconnected,

  /// Provider authorization has expired.
  expired,
}
