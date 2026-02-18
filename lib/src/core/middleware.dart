import 'dart:async';

import 'http_client_adapter.dart';
import 'middleware/retry_middleware.dart';

/// Interceptor for HTTP requests.
///
/// Request interceptors can modify requests before they are sent.
/// They are called in the order they are added to the middleware chain.
///
/// Example:
/// ```dart
/// class LoggingInterceptor implements RequestInterceptor {
///   @override
///   Future<HttpRequest> onRequest(HttpRequest request) async {
///     print('Sending ${request.method} ${request.url}');
///     return request;
///   }
/// }
/// ```
abstract class RequestInterceptor {
  /// Called before a request is sent.
  ///
  /// Can modify the request (e.g., add headers, change URL) or return it as-is.
  /// Must return a non-null [HttpRequest].
  Future<HttpRequest> onRequest(HttpRequest request);
}

/// Interceptor for HTTP responses.
///
/// Response interceptors can modify responses or handle errors.
/// They are called in reverse order (last added is called first).
///
/// Example:
/// ```dart
/// class ErrorInterceptor implements ResponseInterceptor {
///   @override
///   Future<HttpResponse> onResponse(HttpResponse response) async {
///     if (response.statusCode >= 400) {
///       throw ApiServerException('Server error: ${response.statusCode}');
///     }
///     return response;
///   }
/// }
/// ```
abstract class ResponseInterceptor {
  /// Called after a response is received.
  ///
  /// Can modify the response or throw an exception.
  /// Must return a non-null [HttpResponse].
  Future<HttpResponse> onResponse(HttpResponse response);

  /// Called when an error occurs during request/response processing.
  ///
  /// Can handle the error (e.g., retry, transform) or rethrow it.
  /// If this method returns normally, the error is considered handled.
  /// If it throws, the error propagates further.
  Future<HttpResponse> onError(Object error, HttpRequest request) async {
    // Default implementation: rethrow the error
    throw error;
  }
}

/// Wrapper around [HttpClientAdapter] that applies middleware interceptors.
///
/// This adapter chains request interceptors before sending the request
/// and response interceptors after receiving the response.
class MiddlewareHttpClientAdapter implements HttpClientAdapter {
  /// The underlying HTTP client adapter.
  final HttpClientAdapter _adapter;

  /// Request interceptors (applied in order).
  final List<RequestInterceptor> _requestInterceptors;

  /// Response interceptors (applied in reverse order).
  final List<ResponseInterceptor> _responseInterceptors;

  MiddlewareHttpClientAdapter(
    this._adapter, {
    List<RequestInterceptor>? requestInterceptors,
    List<ResponseInterceptor>? responseInterceptors,
  })  : _requestInterceptors = requestInterceptors ?? [],
        _responseInterceptors = responseInterceptors ?? [];

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    // Apply request interceptors in order
    HttpRequest processedRequest = request;
    for (final interceptor in _requestInterceptors) {
      processedRequest = await interceptor.onRequest(processedRequest);
    }

    // Send the request through the underlying adapter with retry logic
    HttpResponse? response;
    Object? lastError;
    
    while (true) {
      try {
        response = await _adapter.send(processedRequest);
        lastError = null;
        break; // Success, exit retry loop
      } catch (error) {
        lastError = error;
        
        // Apply error handlers in reverse order
        bool handled = false;
        for (var i = _responseInterceptors.length - 1; i >= 0; i--) {
          try {
            final result = await _responseInterceptors[i].onError(error, processedRequest);
            // Handler returned a response, use it
            response = result;
            handled = true;
            break;
          } catch (e) {
            // Handler threw, continue to next handler
            if (i == 0) {
              // Last handler threw, exit retry loop
              handled = false;
            }
          }
        }
        
        if (handled) {
          break; // Error was handled, exit retry loop
        }
        
        // Check if we should retry (RetryInterceptor will throw RetryableException)
        if (error is RetryableException) {
          // RetryableException thrown, continue loop to retry
          // (RetryInterceptor already handled the delay)
          continue;
        }
        
        // Not retryable, rethrow
        throw error;
      }
    }

    if (response == null) {
      if (lastError != null) {
        throw lastError;
      }
      throw StateError('No response and no error');
    }

    // Apply response interceptors in reverse order
    HttpResponse processedResponse = response;
    for (var i = _responseInterceptors.length - 1; i >= 0; i--) {
      processedResponse = await _responseInterceptors[i].onResponse(processedResponse);
    }

    return processedResponse;
  }

  @override
  Future<void> close() async {
    await _adapter.close();
  }
}
