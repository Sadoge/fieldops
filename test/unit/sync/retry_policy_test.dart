import 'package:fieldops/core/sync/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetryPolicy', () {
    group('shouldAbandon', () {
      test('returns false below maxRetries', () {
        expect(RetryPolicy.shouldAbandon(0), isFalse);
        expect(RetryPolicy.shouldAbandon(4), isFalse);
      });

      test('returns true at maxRetries', () {
        expect(RetryPolicy.shouldAbandon(RetryPolicy.maxRetries), isTrue);
      });

      test('returns true above maxRetries', () {
        expect(RetryPolicy.shouldAbandon(10), isTrue);
      });
    });

    group('nextRetryAt', () {
      test('returns a future DateTime', () {
        final next = RetryPolicy.nextRetryAt(0);
        expect(next.isAfter(DateTime.now().toUtc()), isTrue);
      });

      test('delay grows with retry count', () {
        // Higher retry count should produce a later retry time on average.
        // We compare midpoints by calling multiple times and checking the
        // minimum of the higher count is after DateTime.now().
        final retryLow = RetryPolicy.nextRetryAt(0);
        final retryHigh = RetryPolicy.nextRetryAt(3);
        // retryHigh should be meaningfully later — base delay at n=3 is 240s
        // vs 30s at n=0, so even with ±20% jitter retryHigh > retryLow.
        expect(retryHigh.isAfter(retryLow), isTrue);
      });

      test('caps delay at 1 hour', () {
        // At n=10 the raw delay would be 30 × 2^10 = ~30720s >> 3600s.
        final next = RetryPolicy.nextRetryAt(10);
        final maxPossible = DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1, minutes: 15)); // +15 min headroom
        expect(next.isBefore(maxPossible), isTrue);
      });
    });
  });
}
