/// High-level configuration for generated API clients.
///
/// This layer is intentionally small and stable: it is used both by the
/// code generator and by the generated clients at runtime.

import 'package:http/http.dart' as http;

import '../core/http_client_adapter.dart';

/// Authentication options for the generated client.
///
/// At v0.1 we support simple API key and bearer token scenarios.
class AuthConfig {
  /// Header name for API key, e.g. `X-API-Key`.
  final String? apiKeyHeader;

  /// Query parameter name for API key, e.g. `api_key`.
  final String? apiKeyQuery;

  /// Static bearer token value.
  ///
  /// Future versions may support indirection via env/secure storage,
  /// but for v0.1 a plain string is enough.
  final String? bearerToken;

  const AuthConfig({
    this.apiKeyHeader,
    this.apiKeyQuery,
    this.bearerToken,
  });
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

  ApiClientConfig({
    required this.baseUrl,
    Map<String, String>? defaultHeaders,
    Duration? timeout,
    this.auth,
    HttpClientAdapter? httpClientAdapter,
    this.httpClient,
  })  : defaultHeaders = Map.unmodifiable(defaultHeaders ?? const {}),
        timeout = timeout ?? const Duration(seconds: 30),
        httpClientAdapter =
            httpClientAdapter ?? HttpHttpClientAdapter(httpClient: httpClient);
}

