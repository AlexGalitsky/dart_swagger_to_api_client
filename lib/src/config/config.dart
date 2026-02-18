/// High-level configuration for generated API clients.
///
/// This layer is intentionally small and stable: it is used both by the
/// code generator and by the generated clients at runtime.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../core/http_client_adapter.dart';
import '../core/middleware.dart';

/// Authentication options for the generated client.
///
/// At v0.1 we support simple API key and bearer token scenarios.
class AuthConfig {
  /// Header name for API key, e.g. `X-API-Key`.
  final String? apiKeyHeader;

  /// Query parameter name for API key, e.g. `api_key`.
  final String? apiKeyQuery;

  /// Static API key value.
  ///
  /// In real applications you might want to inject this from secure storage
  /// or environment variables instead of hard-coding it.
  final String? apiKey;

  /// Static bearer token value.
  ///
  /// If both [bearerToken] and [bearerTokenEnv] are provided,
  /// [bearerToken] takes precedence.
  final String? bearerToken;

  /// Environment variable name for bearer token.
  ///
  /// The token will be read from the environment variable at runtime.
  /// If the variable is not set, authentication will fail.
  final String? bearerTokenEnv;

  const AuthConfig({
    this.apiKeyHeader,
    this.apiKeyQuery,
    this.apiKey,
    this.bearerToken,
    this.bearerTokenEnv,
  });

  /// Resolves the bearer token value.
  ///
  /// Returns [bearerToken] if set, otherwise reads from [bearerTokenEnv]
  /// environment variable. Returns `null` if neither is set or if
  /// [bearerTokenEnv] is set but the environment variable is not found.
  String? resolveBearerToken() {
    if (bearerToken != null) {
      return bearerToken;
    }
    if (bearerTokenEnv != null) {
      return _getEnv(bearerTokenEnv!);
    }
    return null;
  }

  /// Gets environment variable value.
  ///
  /// This is a separate method to allow for easier testing.
  @visibleForTesting
  static String? _getEnv(String name) {
    return Platform.environment[name];
  }
}

/// High-level configuration for a generated API client.
class ApiClientConfig {
  /// Base URL for the API, e.g. `https://api.example.com`.
  final Uri baseUrl;

  /// Default headers applied to every request.
  final Map<String, String> defaultHeaders;

  /// Request timeout.
  final Duration timeout;

  /// Authentication configuration.
  final AuthConfig? auth;

  /// HTTP implementation adapter.
  final HttpClientAdapter httpClientAdapter;

  /// Optional low-level HTTP client for the default `http` adapter.
  ///
  /// This is mostly here so that generated code can optionally share a
  /// single underlying `http.Client` instance across multiple API clients.
  final http.Client? httpClient;

  /// Request interceptors (applied in order before sending requests).
  final List<RequestInterceptor> requestInterceptors;

  /// Response interceptors (applied in reverse order after receiving responses).
  final List<ResponseInterceptor> responseInterceptors;

  ApiClientConfig({
    required this.baseUrl,
    Map<String, String>? defaultHeaders,
    Duration? timeout,
    this.auth,
    HttpClientAdapter? httpClientAdapter,
    this.httpClient,
    List<RequestInterceptor>? requestInterceptors,
    List<ResponseInterceptor>? responseInterceptors,
  })  : defaultHeaders = Map.unmodifiable(defaultHeaders ?? const {}),
        timeout = timeout ?? const Duration(seconds: 30),
        requestInterceptors = requestInterceptors ?? const [],
        responseInterceptors = responseInterceptors ?? const [],
        httpClientAdapter = _wrapWithMiddleware(
          httpClientAdapter ?? HttpHttpClientAdapter(httpClient: httpClient),
          requestInterceptors ?? const [],
          responseInterceptors ?? const [],
        );

  /// Wraps the adapter with middleware if interceptors are provided.
  static HttpClientAdapter _wrapWithMiddleware(
    HttpClientAdapter adapter,
    List<RequestInterceptor> requestInterceptors,
    List<ResponseInterceptor> responseInterceptors,
  ) {
    if (requestInterceptors.isEmpty && responseInterceptors.isEmpty) {
      return adapter;
    }
    return MiddlewareHttpClientAdapter(
      adapter,
      requestInterceptors: requestInterceptors,
      responseInterceptors: responseInterceptors,
    );
  }
}

