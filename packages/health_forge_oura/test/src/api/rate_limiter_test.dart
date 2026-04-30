import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/api/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late DateTime now;
    late RateLimiter limiter;

    setUp(() {
      now = DateTime(2026, 3, 17);
      limiter = RateLimiter(
        maxRequestsPerSecond: 3,
        clock: () => now,
      );
    });

    RequestOptions makeOptions() => RequestOptions(path: '/test');

    test('allows requests under the limit', () async {
      var passedThrough = 0;

      for (var i = 0; i < 3; i++) {
        await limiter.onRequest(
          makeOptions(),
          _TestHandler(onNext: () => passedThrough++),
        );
      }

      expect(passedThrough, 3);
    });

    test('delays requests that exceed the limit', () async {
      var passedThrough = 0;

      // Fill up the window with 3 requests.
      for (var i = 0; i < 3; i++) {
        await limiter.onRequest(
          makeOptions(),
          _TestHandler(onNext: () => passedThrough++),
        );
      }
      expect(passedThrough, 3);

      // Advance time by 500ms — still within the 1-second window.
      now = now.add(const Duration(milliseconds: 500));

      // The 4th request should trigger a delay. We simulate the passage of
      // time by advancing the clock past the 1-second window before the
      // Future.delayed completes.
      final future = limiter.onRequest(
        makeOptions(),
        _TestHandler(onNext: () => passedThrough++),
      );

      // Advance time so the delay resolves and timestamps expire.
      now = now.add(const Duration(seconds: 1));

      await future;
      expect(passedThrough, 4);
    });

    test('cleans up old timestamps outside the window', () async {
      var passedThrough = 0;

      // Send 3 requests at time T.
      for (var i = 0; i < 3; i++) {
        await limiter.onRequest(
          makeOptions(),
          _TestHandler(onNext: () => passedThrough++),
        );
      }

      // Advance time well past the 1-second window.
      now = now.add(const Duration(seconds: 2));

      // Should be able to send 3 more without delay since old ones expired.
      for (var i = 0; i < 3; i++) {
        await limiter.onRequest(
          makeOptions(),
          _TestHandler(onNext: () => passedThrough++),
        );
      }

      expect(passedThrough, 6);
    });

    test('uses default maxRequestsPerSecond of 5', () {
      final defaultLimiter = RateLimiter(clock: () => now);
      expect(defaultLimiter.maxRequestsPerSecond, 5);
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
