import 'dart:async';

import 'package:dio/dio.dart';

/// A Dio interceptor that enforces a maximum number of requests per second.
///
/// Uses a sliding-window approach: timestamps of recent requests are tracked
/// and, when the window is full, the next request is delayed until the oldest
/// timestamp expires.
///
/// An injectable clock function enables deterministic testing without real
/// timers.
class RateLimiter extends Interceptor {
  /// Creates a rate limiter with the given [maxRequestsPerSecond].
  ///
  /// An optional [clock] function can be injected for testing.
  RateLimiter({
    this.maxRequestsPerSecond = 5,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Maximum allowed requests within a one-second sliding window.
  final int maxRequestsPerSecond;
  final DateTime Function() _clock;
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

    if (_timestamps.length >= maxRequestsPerSecond) {
      final oldest = _timestamps.first;
      final waitUntil = oldest.add(const Duration(seconds: 1));
      final now = _clock();
      final delay = waitUntil.difference(now);

      if (!delay.isNegative) {
        await Future<void>.delayed(delay);
      }

      _cleanOldTimestamps();
    }
  }

  void _cleanOldTimestamps() {
    final cutoff = _clock().subtract(const Duration(seconds: 1));
    _timestamps.removeWhere((t) => t.isBefore(cutoff));
  }
}
