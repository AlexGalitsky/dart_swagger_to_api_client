import 'dart:async';

import '../errors.dart';
import '../http_client_adapter.dart';
import '../middleware.dart';

/// Circuit breaker states.
enum CircuitState {
  /// Circuit is closed (normal operation).
  closed,

  /// Circuit is open (requests are blocked).
  open,

  /// Circuit is half-open (testing if service recovered).
  halfOpen,
}

/// Interceptor that implements circuit breaker pattern.
///
/// Circuit breaker prevents cascading failures by temporarily blocking
/// requests to a service that is failing. It has three states:
///
/// - **Closed**: Normal operation, requests pass through
/// - **Open**: Service is failing, requests are blocked immediately
/// - **Half-Open**: Testing if service recovered, allowing limited requests
///
/// Example:
/// ```dart
/// final circuitBreaker = CircuitBreakerInterceptor(
///   failureThreshold: 5,
///   timeout: Duration(seconds: 60),
///   resetTimeout: Duration(seconds: 30),
/// );
/// ```
///
/// **Note**: Add this to both requestInterceptors (to block early) and
/// responseInterceptors (to track failures) for best results.
class CircuitBreakerInterceptor implements RequestInterceptor, ResponseInterceptor {
  /// Number of consecutive failures before opening the circuit.
  final int failureThreshold;

  /// Timeout for requests (used to detect failures).
  final Duration timeout;

  /// Time to wait before attempting to reset the circuit (half-open state).
  final Duration resetTimeout;

  /// Current circuit state.
  CircuitState _state = CircuitState.closed;

  /// Number of consecutive failures.
  int _failureCount = 0;

  /// Timestamp when circuit was opened.
  DateTime? _openedAt;

  /// Number of successful requests in half-open state.
  int _halfOpenSuccessCount = 0;

  /// Number of requests allowed in half-open state before closing.
  final int _halfOpenSuccessThreshold = 1;

  CircuitBreakerInterceptor({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 60),
    this.resetTimeout = const Duration(seconds: 30),
  });

  /// Current state of the circuit breaker.
  CircuitState get state => _state;

  /// Number of consecutive failures.
  int get failureCount => _failureCount;

  @override
  Future<HttpResponse> onResponse(HttpResponse response) async {
    // Check if response indicates failure
    final isFailure = response.statusCode >= 500;

    if (isFailure) {
      _handleFailure();
    } else {
      _handleSuccess();
    }

    // If circuit is open, throw exception
    if (_state == CircuitState.open) {
      throw ApiServerException(
        'Circuit breaker is open. Service is unavailable.',
        statusCode: 503,
      );
    }

    return response;
  }

  @override
  Future<HttpResponse> onError(Object error, HttpRequest request) async {
    _handleFailure();

    // If circuit is open, throw exception
    if (_state == CircuitState.open) {
      throw ApiServerException(
        'Circuit breaker is open. Service is unavailable.',
        statusCode: 503,
      );
    }

    // Rethrow original error
    throw error;
  }

  void _handleFailure() {
    _failureCount++;

    if (_state == CircuitState.closed) {
      if (_failureCount >= failureThreshold) {
        _openCircuit();
      }
    } else if (_state == CircuitState.halfOpen) {
      // Failure in half-open state, open circuit again
      _openCircuit();
    }
  }

  void _handleSuccess() {
    _failureCount = 0;

    if (_state == CircuitState.halfOpen) {
      _halfOpenSuccessCount++;
      if (_halfOpenSuccessCount >= _halfOpenSuccessThreshold) {
        _closeCircuit();
      }
    } else if (_state == CircuitState.open) {
      // Should not happen, but handle gracefully
      _closeCircuit();
    }
  }

  void _openCircuit() {
    _state = CircuitState.open;
    _openedAt = DateTime.now();
    _halfOpenSuccessCount = 0;
  }

  void _closeCircuit() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _openedAt = null;
    _halfOpenSuccessCount = 0;
  }

  /// Checks if circuit should transition from open to half-open.
  ///
  /// This should be called before making a request to check if
  /// the circuit should be tested (half-open state).
  void _checkReset() {
    if (_state == CircuitState.open && _openedAt != null) {
      final elapsed = DateTime.now().difference(_openedAt!);
      if (elapsed >= resetTimeout) {
        _state = CircuitState.halfOpen;
        _halfOpenSuccessCount = 0;
      }
    }
  }

  /// Called before request to check circuit state.
  ///
  /// This method implements RequestInterceptor interface to check
  /// if the circuit is open before making a request.
  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    _checkReset();

    if (_state == CircuitState.open) {
      throw ApiServerException(
        'Circuit breaker is open. Service is unavailable.',
        statusCode: 503,
      );
    }

    return request;
  }
}
