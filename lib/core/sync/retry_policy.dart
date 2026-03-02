import 'dart:math';

abstract final class RetryPolicy {
  static const int maxRetries = 5;
  static const Duration _base = Duration(seconds: 30);
  static const double _multiplier = 2.0;
  static const Duration _max = Duration(hours: 1);

  static DateTime nextRetryAt(int retryCount) {
    final rawSeconds =
        (_base.inSeconds * pow(_multiplier, retryCount)).toInt();
    final clampedSeconds = rawSeconds.clamp(0, _max.inSeconds);
    // ±20 % jitter to avoid thundering herd
    final jitter =
        (clampedSeconds * 0.2 * (Random().nextDouble() - 0.5)).toInt();
    return DateTime.now()
        .toUtc()
        .add(Duration(seconds: clampedSeconds + jitter));
  }

  static bool shouldAbandon(int retryCount) => retryCount >= maxRetries;
}
