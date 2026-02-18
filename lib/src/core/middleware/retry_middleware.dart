import 'dart:async';
import 'dart:math';

import '../http_client_adapter.dart';
import '../middleware.dart';

/// Response interceptor that retries failed requests.
///
/// Retries requests that fail with network errors or specific HTTP status codes.
/// Uses exponential backoff between retries.
///
/// Example:
/// ```dart
/// final retryInterceptor = RetryInterceptor(
///   maxRetries: 3,
///   retryableStatusCodes: {500, 502, 503, 504},
/// );
/// ```
class RetryInterceptor implements ResponseInterceptor {
  /// Maximum number of retry attempts.
  final int maxRetries;

  /// HTTP status codes that should trigger a retry.
  ///
  /// Default: `{500, 502, 503, 504}` (server errors).
  final Set<int> retryableStatusCodes;

  /// Network errors that should trigger a retry.
  ///
  /// Default: `{TimeoutException}`.
  final Set<Type> retryableErrors;

  /// Base delay for exponential backoff (in milliseconds).
  ///
  /// Default: 1000ms (1 second).
  final int baseDelayMs;

  /// Maximum delay between retries (in milliseconds).
  ///
  /// Default: 10000ms (10 seconds).
  final int maxDelayMs;

  /// Random number generator for jitter.
  final Random _random = Random();

  /// Current retry attempt counter (internal state).
  int _attempt = 0;

  RetryInterceptor({
    this.maxRetries = 3,
    Set<int>? retryableStatusCodes,
    Set<Type>? retryableErrors,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 10000,
  })  : retryableStatusCodes = retryableStatusCodes ?? {500, 502, 503, 504},
        retryableErrors = retryableErrors ?? {TimeoutException};

  @override
  Future<HttpResponse> onResponse(HttpResponse response) async {
    // Check if status code is retryable
    if (retryableStatusCodes.contains(response.statusCode) && _attempt < maxRetries) {
      _attempt++;

      // Calculate delay with exponential backoff and jitter
      final delayMs = min(
        baseDelayMs * pow(2, _attempt - 1).toInt(),
        maxDelayMs,
      );
      final jitter = _random.nextInt(200); // 0-200ms jitter
      final totalDelay = Duration(milliseconds: delayMs + jitter);

      // Wait before retrying
      await Future.delayed(totalDelay);

      // Signal that we want to retry
      throw RetryableException(
        'Server returned ${response.statusCode}, will retry (attempt $_attempt/$maxRetries)',
        response.statusCode,
      );
    }

    // Success or not retryable, reset attempt counter
    _attempt = 0;
    return response;
  }

  @override
  Future<HttpResponse> onError(Object error, HttpRequest request) async {
    // Don't retry RetryableException itself (to avoid infinite loops)
    if (error is RetryableException) {
      throw error;
    }

    // Check if error is retryable
    final isRetryable = retryableErrors.any((type) => error.runtimeType == type);

    if (isRetryable && _attempt < maxRetries) {
      _attempt++;

      // Calculate delay with exponential backoff and jitter
      final delayMs = min(
        baseDelayMs * pow(2, _attempt - 1).toInt(),
        maxDelayMs,
      );
      final jitter = _random.nextInt(200); // 0-200ms jitter
      final totalDelay = Duration(milliseconds: delayMs + jitter);

      // Wait before retrying
      await Future.delayed(totalDelay);

      // Signal that we want to retry by throwing a special exception
      throw RetryableException(
        'Network error occurred, will retry (attempt $_attempt/$maxRetries)',
        null,
      );
    }

    // Not retryable or max retries reached, reset counter and rethrow
    _attempt = 0;
    throw error;
  }
}

/// Exception thrown by [RetryInterceptor] to signal that a request should be retried.
///
/// This is an internal exception used by the retry middleware.
/// It should not be caught by application code.
class RetryableException implements Exception {
  final String message;
  final int? statusCode;

  RetryableException(this.message, this.statusCode);

  @override
  String toString() => message;
}
