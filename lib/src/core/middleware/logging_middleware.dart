import 'dart:async';

import '../http_client_adapter.dart';
import '../middleware.dart';

/// Request interceptor that logs HTTP requests.
///
/// Example:
/// ```dart
/// final loggingInterceptor = LoggingInterceptor(
///   logRequest: (request) => print('→ ${request.method} ${request.url}'),
///   logResponse: (response) => print('← ${response.statusCode}'),
/// );
/// ```
class LoggingInterceptor implements RequestInterceptor, ResponseInterceptor {
  /// Callback for logging requests.
  ///
  /// If null, requests are not logged.
  final void Function(HttpRequest request)? logRequest;

  /// Callback for logging responses.
  ///
  /// If null, responses are not logged.
  final void Function(HttpResponse response)? logResponse;

  /// Callback for logging errors.
  ///
  /// If null, errors are not logged.
  final void Function(Object error, HttpRequest request)? logError;

  /// Whether to log request headers.
  final bool logHeaders;

  /// Whether to log request body.
  final bool logBody;

  LoggingInterceptor({
    this.logRequest,
    this.logResponse,
    this.logError,
    this.logHeaders = false,
    this.logBody = false,
  });

  /// Creates a simple console logger.
  ///
  /// Logs requests and responses to stdout.
  factory LoggingInterceptor.console({
    bool logHeaders = false,
    bool logBody = false,
  }) {
    return LoggingInterceptor(
      logRequest: (request) {
        final buffer = StringBuffer();
        buffer.write('→ ${request.method} ${request.url}');
        if (logHeaders && request.headers.isNotEmpty) {
          buffer.write('\n  Headers: ${request.headers}');
        }
        if (logBody && request.body != null) {
          buffer.write('\n  Body: ${request.body}');
        }
        print(buffer.toString());
      },
      logResponse: (response) {
        print('← ${response.statusCode} ${response.body.length} bytes');
      },
      logError: (error, request) {
        print('✗ Error: $error (${request.method} ${request.url})');
      },
      logHeaders: logHeaders,
      logBody: logBody,
    );
  }

  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    logRequest?.call(request);
    return request;
  }

  @override
  Future<HttpResponse> onResponse(HttpResponse response) async {
    logResponse?.call(response);
    return response;
  }

  @override
  Future<HttpResponse> onError(Object error, HttpRequest request) async {
    logError?.call(error, request);
    throw error;
  }
}
