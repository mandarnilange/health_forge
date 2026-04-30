import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_strava/src/api/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late DateTime now;
    late RateLimiter limiter;

    setUp(() {
      now = DateTime(2026, 3, 18);
      limiter = RateLimiter(
        maxRequestsPer15Min: 3,
        maxRequestsPerDay: 10,
        clock: () => now,
        delay: (_) async {
          // Simulate time passing when delay is triggered.
          now = now.add(const Duration(minutes: 15));
        },
      );
    });

    RequestOptions makeOptions() => RequestOptions(path: '/test');

    test('allows requests under the 15-minute limit', () async {
      var passedThrough = 0;

      for (var i = 0; i < 3; i++) {
        await limiter.onRequest(
          makeOptions(),
          _TestHandler(onNext: () => passedThrough++),
        );
      }

      expect(passedThrough, 3);
    });

    test('delays requests that exceed the 15-minute limit', () async {
      var passedThrough = 0;
      var delayTriggered = false;

      limiter = RateLimiter(
        maxRequestsPer15Min: 3,
        maxRequestsPerDay: 10,
        clock: () => now,
        delay: (_) async {
          delayTriggered = true;
          now = now.add(const Duration(minutes: 15));
        },
      );

      // Fill up the 15-minute window with 3 requests.
      for (var i = 0; i < 3; i++) {
        await limiter.onRequest(
          makeOptions(),
          _TestHandler(onNext: () => passedThrough++),
        );
      }
      expect(passedThrough, 3);
      expect(delayTriggered, isFalse);

      // Advance time by 5 min — still within the 15-minute window.
      now = now.add(const Duration(minutes: 5));

      // 4th request should trigger delay.
      await limiter.onRequest(
        makeOptions(),
        _TestHandler(onNext: () => passedThrough++),
      );

      expect(delayTriggered, isTrue);
      expect(passedThrough, 4);
    });

    test('cleans up timestamps older than 1 day', () async {
      var passedThrough = 0;

      for (var i = 0; i < 3; i++) {
        await limiter.onRequest(
          makeOptions(),
          _TestHandler(onNext: () => passedThrough++),
        );
      }

      // Advance past 15 minutes.
      now = now.add(const Duration(minutes: 16));

      for (var i = 0; i < 3; i++) {
        await limiter.onRequest(
          makeOptions(),
          _TestHandler(onNext: () => passedThrough++),
        );
      }

      expect(passedThrough, 6);
    });

    test('uses default limits of 100/15min and 1000/day', () {
      final defaultLimiter = RateLimiter(clock: () => now);
      expect(defaultLimiter.maxRequestsPer15Min, 100);
      expect(defaultLimiter.maxRequestsPerDay, 1000);
    });
  });
}

class _TestHandler extends RequestInterceptorHandler {
  _TestHandler({required this.onNext});

  final void Function() onNext;

  @override
  void next(RequestOptions requestOptions) {
    onNext();
  }
}
