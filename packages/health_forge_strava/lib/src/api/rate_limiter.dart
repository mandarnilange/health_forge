import 'dart:async';

import 'package:dio/dio.dart';

/// A Dio interceptor that enforces dual sliding-window rate limits.
///
/// Strava enforces two rate limits:
/// - 100 requests per 15 minutes
/// - 1000 requests per day
///
/// An injectable clock function enables deterministic testing.
class RateLimiter extends Interceptor {
  /// Creates a rate limiter with configurable limits.
  ///
  /// Optional [clock] and [delay] functions can be injected for testing.
  RateLimiter({
    this.maxRequestsPer15Min = 100,
    this.maxRequestsPerDay = 1000,
    DateTime Function()? clock,
    Future<void> Function(Duration)? delay,
  })  : _clock = clock ?? DateTime.now,
        _delay = delay ?? Future<void>.delayed;

  /// Maximum allowed requests within a 15-minute sliding window.
  final int maxRequestsPer15Min;

  /// Maximum allowed requests within a 24-hour sliding window.
  final int maxRequestsPerDay;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _delay;
  final _timestamps = <DateTime>[];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _waitIfNeeded();
    _timestamps.add(_clock());
    handler.next(options);
  }

  Future<void> _waitIfNeeded() async {
    _cleanOldTimestamps();

    final now = _clock();
    final fifteenMinAgo = now.subtract(const Duration(minutes: 15));
    final recentCount =
        _timestamps.where((t) => t.isAfter(fifteenMinAgo)).length;

    if (recentCount >= maxRequestsPer15Min) {
      final oldest = _timestamps.where((t) => t.isAfter(fifteenMinAgo)).first;
      final waitUntil = oldest.add(const Duration(minutes: 15));
      final waitDuration = waitUntil.difference(now);
      if (!waitDuration.isNegative) {
        await _delay(waitDuration);
      }
      _cleanOldTimestamps();
    }
  }

  void _cleanOldTimestamps() {
    final cutoff = _clock().subtract(const Duration(days: 1));
    _timestamps.removeWhere((t) => t.isBefore(cutoff));
  }
}
