import 'dart:async';

import '../http_client_adapter.dart';
import '../middleware.dart';

/// Request interceptor that implements rate limiting.
///
/// Limits the number of requests per time window to prevent exceeding API rate limits.
///
/// Example:
/// ```dart
/// final rateLimitInterceptor = RateLimitInterceptor(
///   maxRequests: 100,
///   window: Duration(minutes: 1),
/// );
/// ```
class RateLimitInterceptor implements RequestInterceptor {
  /// Maximum number of requests allowed in the time window.
  final int maxRequests;

  /// Time window for rate limiting.
  final Duration window;

  /// Queue of request timestamps.
  final List<DateTime> _requestTimestamps = [];

  /// Lock for thread-safe access to request timestamps.
  Completer<void> _lock = Completer<void>()..complete();

  RateLimitInterceptor({
    required this.maxRequests,
    required this.window,
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    // Wait for lock
    await _lock.future;
    final newLock = Completer<void>();
    _lock = newLock;

    try {
      final now = DateTime.now();
      final cutoff = now.subtract(window);

      // Remove old timestamps outside the window
      _requestTimestamps.removeWhere((timestamp) => timestamp.isBefore(cutoff));

      // Check if we've exceeded the rate limit
      if (_requestTimestamps.length >= maxRequests) {
        // Calculate how long to wait
        final oldestTimestamp = _requestTimestamps.first;
        final elapsed = now.difference(oldestTimestamp);
        final waitTime = window - elapsed;
        
        if (waitTime.inMilliseconds > 0) {
          await Future.delayed(waitTime);
          
          // Remove the oldest timestamp after waiting
          _requestTimestamps.removeAt(0);
        }
      }

      // Add current request timestamp
      _requestTimestamps.add(now);
    } finally {
      // Release lock
      newLock.complete();
    }

    return request;
  }
}
