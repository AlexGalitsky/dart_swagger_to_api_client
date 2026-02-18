import 'dart:async';

import '../http_client_adapter.dart';
import '../middleware.dart';

/// Request transformer function type.
///
/// Transforms a request before it is sent.
/// Can modify headers, URL, body, or any other request properties.
typedef RequestTransformer = Future<HttpRequest> Function(HttpRequest request);

/// Response transformer function type.
///
/// Transforms a response after it is received.
/// Can modify status code, headers, body, or any other response properties.
typedef ResponseTransformer = Future<HttpResponse> Function(HttpResponse response);

/// Request interceptor that applies custom transformations to requests.
///
/// Example:
/// ```dart
/// final transformer = TransformerInterceptor(
///   requestTransformer: (request) async {
///     // Add custom header
///     final newHeaders = Map<String, String>.from(request.headers);
///     newHeaders['X-Custom-Header'] = 'value';
///     return HttpRequest(
///       method: request.method,
///       url: request.url,
///       headers: newHeaders,
///       body: request.body,
///       timeout: request.timeout,
///     );
///   },
/// );
/// ```
class TransformerInterceptor implements RequestInterceptor, ResponseInterceptor {
  /// Optional request transformer function.
  final RequestTransformer? requestTransformer;

  /// Optional response transformer function.
  final ResponseTransformer? responseTransformer;

  TransformerInterceptor({
    this.requestTransformer,
    this.responseTransformer,
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    if (requestTransformer != null) {
      return await requestTransformer!(request);
    }
    return request;
  }

  @override
  Future<HttpResponse> onResponse(HttpResponse response) async {
    if (responseTransformer != null) {
      return await responseTransformer!(response);
    }
    return response;
  }

  @override
  Future<HttpResponse> onError(Object error, HttpRequest request) async {
    // Transformers don't handle errors, just rethrow
    throw error;
  }
}

/// Helper class for common request transformations.
class RequestTransformers {
  /// Adds headers to the request.
  static RequestTransformer addHeaders(Map<String, String> headers) {
    return (request) async {
      final newHeaders = Map<String, String>.from(request.headers);
      newHeaders.addAll(headers);
      return HttpRequest(
        method: request.method,
        url: request.url,
        headers: newHeaders,
        body: request.body,
        timeout: request.timeout,
      );
    };
  }

  /// Modifies the URL (e.g., adds query parameters, changes path).
  static RequestTransformer modifyUrl(Uri Function(Uri url) modifier) {
    return (request) async {
      final newUrl = modifier(request.url);
      return HttpRequest(
        method: request.method,
        url: newUrl,
        headers: request.headers,
        body: request.body,
        timeout: request.timeout,
      );
    };
  }

  /// Transforms the request body.
  static RequestTransformer transformBody(Object? Function(Object? body) transformer) {
    return (request) async {
      final newBody = transformer(request.body);
      return HttpRequest(
        method: request.method,
        url: request.url,
        headers: request.headers,
        body: newBody,
        timeout: request.timeout,
      );
    };
  }
}

/// Helper class for common response transformations.
class ResponseTransformers {
  /// Modifies response headers.
  static ResponseTransformer modifyHeaders(
    Map<String, String> Function(Map<String, String> headers) modifier,
  ) {
    return (response) async {
      final newHeaders = modifier(Map<String, String>.from(response.headers));
      return HttpResponse(
        statusCode: response.statusCode,
        headers: newHeaders,
        body: response.body,
      );
    };
  }

  /// Transforms the response body.
  static ResponseTransformer transformBody(String Function(String body) transformer) {
    return (response) async {
      final newBody = transformer(response.body);
      return HttpResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: newBody,
      );
    };
  }

  /// Normalizes status codes (e.g., maps 201 to 200).
  static ResponseTransformer normalizeStatusCodes(
    Map<int, int> statusCodeMap,
  ) {
    return (response) async {
      final newStatusCode = statusCodeMap[response.statusCode] ?? response.statusCode;
      return HttpResponse(
        statusCode: newStatusCode,
        headers: response.headers,
        body: response.body,
      );
    };
  }
}
