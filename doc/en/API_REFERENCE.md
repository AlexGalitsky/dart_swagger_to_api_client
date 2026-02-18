# API Reference

Complete API reference for `dart_swagger_to_api_client` package.

## Table of Contents

1. [Core Classes](#core-classes)
2. [Configuration](#configuration)
3. [HTTP Adapters](#http-adapters)
4. [Middleware](#middleware)
5. [Error Handling](#error-handling)
6. [Code Generation](#code-generation)

## Core Classes

### ApiClientGenerator

Main class for generating API clients from OpenAPI/Swagger specifications.

#### Methods

##### `generateClient`

```dart
static Future<void> generateClient({
  required String inputSpecPath,
  required String outputDir,
  ApiClientConfig? config,
  String? projectDir,
  void Function(String message)? onWarning,
  String? customAdapterType,
  bool enableCache = true,
})
```

Generates API client Dart files into the specified output directory.

**Parameters:**
- `inputSpecPath` (required): Path to OpenAPI/Swagger spec (YAML or JSON)
- `outputDir` (required): Directory where client code will be written
- `config`: Optional runtime configuration (base URL, auth, HTTP adapter hints)
- `projectDir`: Project root directory for resolving relative paths
- `onWarning`: Optional callback for warning messages
- `customAdapterType`: Optional custom adapter type name (for custom adapters)
- `enableCache`: Whether to enable spec parsing cache (default: `true`)

**Throws:**
- `GenerationException`: If spec loading, validation, or code generation fails
- `ConfigValidationException`: If configuration validation fails

**Example:**
```dart
await ApiClientGenerator.generateClient(
  inputSpecPath: 'swagger/api.yaml',
  outputDir: 'lib/api_client',
  projectDir: '.',
  onWarning: (msg) => print('Warning: $msg'),
);
```

## Configuration

### ApiClientConfig

Runtime configuration for the generated API client.

```dart
class ApiClientConfig {
  final Uri baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final AuthConfig? auth;
  final HttpClientAdapter httpClientAdapter;
  final List<RequestInterceptor> requestInterceptors;
  final List<ResponseInterceptor> responseInterceptors;

  ApiClientConfig({
    required this.baseUrl,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
    this.auth,
    HttpClientAdapter? httpClientAdapter,
    List<RequestInterceptor>? requestInterceptors,
    List<ResponseInterceptor>? responseInterceptors,
  });
}
```

**Properties:**
- `baseUrl`: Base URL for all API requests
- `defaultHeaders`: Default headers to include in all requests
- `timeout`: Request timeout duration (default: 30 seconds)
- `auth`: Authentication configuration
- `httpClientAdapter`: HTTP client adapter implementation
- `requestInterceptors`: List of request interceptors
- `responseInterceptors`: List of response interceptors

**Example:**
```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  defaultHeaders: {'User-Agent': 'my-app/1.0.0'},
  timeout: Duration(seconds: 60),
  auth: AuthConfig(bearerToken: 'token'),
);
```

### AuthConfig

Authentication configuration.

```dart
class AuthConfig {
  final String? apiKeyHeader;
  final String? apiKeyQuery;
  final String? apiKey;
  final String? bearerToken;
  final String? bearerTokenEnv;

  AuthConfig({
    this.apiKeyHeader,
    this.apiKeyQuery,
    this.apiKey,
    this.bearerToken,
    this.bearerTokenEnv,
  });

  String? resolveBearerToken();
}
```

**Properties:**
- `apiKeyHeader`: Header name for API key authentication
- `apiKeyQuery`: Query parameter name for API key authentication
- `apiKey`: API key value
- `bearerToken`: Bearer token value
- `bearerTokenEnv`: Environment variable name for bearer token

**Methods:**
- `resolveBearerToken()`: Returns bearer token from `bearerToken` or `bearerTokenEnv`

**Example:**
```dart
final auth = AuthConfig(
  bearerTokenEnv: 'API_TOKEN', // Reads from environment
);
```

### ApiGeneratorConfig

Generator-level configuration loaded from YAML file.

```dart
class ApiGeneratorConfig {
  final String? input;
  final String? outputDir;
  final Uri? baseUrl;
  final Map<String, String> headers;
  final AuthConfig? auth;
  final String? httpAdapter;
  final String? customAdapterType;
  final Map<String, EnvironmentProfile> environments;
}
```

**Properties:**
- `input`: Path to OpenAPI/Swagger spec
- `outputDir`: Output directory for generated code
- `baseUrl`: Default base URL
- `headers`: Default headers
- `auth`: Authentication settings
- `httpAdapter`: HTTP adapter name (`http`, `dio`, `custom`)
- `customAdapterType`: Custom adapter type name
- `environments`: Environment profiles

### EnvironmentProfile

Environment-specific configuration profile.

```dart
class EnvironmentProfile {
  final Uri? baseUrl;
  final Map<String, String> headers;
  final AuthConfig? auth;
}
```

## HTTP Adapters

### HttpClientAdapter

Abstract interface for HTTP client implementations.

```dart
abstract class HttpClientAdapter {
  Future<HttpResponse> send(HttpRequest request);
  Future<void> close();
}
```

**Methods:**
- `send(request)`: Sends an HTTP request and returns a response
- `close()`: Closes the adapter and releases resources

### HttpRequest

Represents an HTTP request.

```dart
class HttpRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Object? body;
  final Duration? timeout;

  HttpRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
    this.timeout,
  });
}
```

**Properties:**
- `method`: HTTP method (GET, POST, PUT, DELETE, PATCH)
- `url`: Request URL
- `headers`: Request headers
- `body`: Request body (String, Map, File, List<int>)
- `timeout`: Request timeout

### HttpResponse

Represents an HTTP response.

```dart
class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;

  HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });
}
```

**Properties:**
- `statusCode`: HTTP status code
- `headers`: Response headers
- `body`: Response body

### HttpHttpClientAdapter

Default HTTP adapter using `package:http`.

```dart
class HttpHttpClientAdapter implements HttpClientAdapter {
  HttpHttpClientAdapter({http.Client? client});

  @override
  Future<HttpResponse> send(HttpRequest request);

  @override
  Future<void> close();
}
```

### DioHttpClientAdapter

HTTP adapter using `package:dio`.

```dart
class DioHttpClientAdapter implements HttpClientAdapter {
  DioHttpClientAdapter({
    required Dio dio,
    bool ownsDio = false,
  });

  @override
  Future<HttpResponse> send(HttpRequest request);

  @override
  Future<void> close();
}
```

**Parameters:**
- `dio`: Dio instance to use
- `ownsDio`: Whether this adapter owns the Dio instance (for cleanup)

## Middleware

### RequestInterceptor

Interface for intercepting and modifying requests.

```dart
abstract class RequestInterceptor {
  Future<HttpRequest> onRequest(HttpRequest request);
}
```

**Methods:**
- `onRequest(request)`: Modifies the request before sending

### ResponseInterceptor

Interface for intercepting and handling responses.

```dart
abstract class ResponseInterceptor {
  Future<HttpResponse> onResponse(HttpResponse response);
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

**Methods:**
- `onResponse(response)`: Processes the response after receiving
- `onError(error, stackTrace)`: Handles errors

### LoggingInterceptor

Logs HTTP requests and responses.

```dart
class LoggingInterceptor implements RequestInterceptor, ResponseInterceptor {
  LoggingInterceptor.console({
    bool logHeaders = false,
    bool logBody = false,
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request);

  @override
  Future<HttpResponse> onResponse(HttpResponse response);

  @override
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

### RetryInterceptor

Retries failed requests with exponential backoff.

```dart
class RetryInterceptor implements ResponseInterceptor {
  RetryInterceptor({
    int maxRetries = 3,
    Set<int> retryableStatusCodes = const {500, 502, 503, 504},
    Set<Type> retryableErrors = const {TimeoutException},
    int baseDelayMs = 1000,
    int maxDelayMs = 10000,
  });

  @override
  Future<HttpResponse> onResponse(HttpResponse response);

  @override
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

**Properties:**
- `maxRetries`: Maximum number of retry attempts
- `retryableStatusCodes`: HTTP status codes that trigger retry
- `retryableErrors`: Exception types that trigger retry
- `baseDelayMs`: Base delay in milliseconds
- `maxDelayMs`: Maximum delay in milliseconds

### RateLimitInterceptor

Enforces rate limiting on requests.

```dart
class RateLimitInterceptor implements RequestInterceptor {
  RateLimitInterceptor({
    required int maxRequests,
    required Duration window,
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request);
}
```

**Properties:**
- `maxRequests`: Maximum number of requests allowed
- `window`: Time window for rate limiting

### CircuitBreakerInterceptor

Implements circuit breaker pattern.

```dart
class CircuitBreakerInterceptor implements RequestInterceptor, ResponseInterceptor {
  CircuitBreakerInterceptor({
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 60),
    Duration resetTimeout = const Duration(seconds: 30),
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request);

  @override
  Future<HttpResponse> onResponse(HttpResponse response);

  @override
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

**Properties:**
- `failureThreshold`: Number of failures before opening circuit
- `timeout`: Timeout for requests
- `resetTimeout`: Time to wait before attempting to close circuit

### TransformerInterceptor

Applies custom transformations to requests and responses.

```dart
class TransformerInterceptor implements RequestInterceptor, ResponseInterceptor {
  TransformerInterceptor({
    RequestTransformer? requestTransformer,
    ResponseTransformer? responseTransformer,
  });

  @override
  Future<HttpRequest> onRequest(HttpRequest request);

  @override
  Future<HttpResponse> onResponse(HttpResponse response);

  @override
  Future<void> onError(Object error, StackTrace stackTrace);
}
```

### RequestTransformers

Helper class for common request transformations.

```dart
class RequestTransformers {
  static RequestTransformer addHeaders(Map<String, String> headers);
  static RequestTransformer modifyUrl(Uri Function(Uri) transformer);
  static RequestTransformer transformBody(Object? Function(Object?) transformer);
}
```

### ResponseTransformers

Helper class for common response transformations.

```dart
class ResponseTransformers {
  static ResponseTransformer modifyHeaders(Map<String, String> Function(Map<String, String>) transformer);
  static ResponseTransformer transformBody(String Function(String) transformer);
  static ResponseTransformer normalizeStatusCodes(Map<int, int> statusCodeMap);
}
```

## Error Handling

### ApiClientException

Base exception for all API client errors.

```dart
class ApiClientException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? context;
  final Object? cause;

  ApiClientException(
    this.message, {
    this.statusCode,
    this.context,
    this.cause,
  });

  @override
  String toString();
}
```

### ApiServerException

Represents 5xx HTTP errors.

```dart
class ApiServerException extends ApiClientException {
  ApiServerException(
    super.message, {
    super.statusCode,
    super.context,
    super.cause,
  });
}
```

### ApiAuthException

Represents authentication/authorization errors (401/403).

```dart
class ApiAuthException extends ApiClientException {
  ApiAuthException(
    super.message, {
    super.statusCode,
    super.context,
    super.cause,
  });
}
```

### TimeoutException

Represents timeout errors.

```dart
class TimeoutException extends ApiClientException {
  TimeoutException(
    super.message,
    Duration timeout, {
    Map<String, dynamic>? context,
    super.cause,
  });
}
```

### GenerationException

Represents errors during code generation.

```dart
class GenerationException implements Exception {
  final String message;
  final String? path;
  final Map<String, dynamic>? context;
  final Object? cause;

  GenerationException(
    this.message, {
    this.path,
    this.context,
    this.cause,
  });

  @override
  String toString();
}
```

### ConfigValidationException

Represents configuration validation errors.

```dart
class ConfigValidationException implements Exception {
  final String message;
  final String? field;
  final Map<String, dynamic>? context;
  final Object? cause;

  ConfigValidationException(
    this.message, {
    this.field,
    this.context,
    this.cause,
  });

  @override
  String toString();
}
```

### CircuitBreakerOpenException

Thrown when circuit breaker is open.

```dart
class CircuitBreakerOpenException extends ApiClientException {
  CircuitBreakerOpenException(String message);
}
```

## Code Generation

### SpecLoader

Loads OpenAPI/Swagger specifications from files.

```dart
class SpecLoader {
  SpecLoader({SpecCache? cache});

  Future<Map<String, dynamic>> load(String inputPath);
}
```

**Methods:**
- `load(inputPath)`: Loads and parses spec file (YAML or JSON)

### SpecValidator

Validates OpenAPI/Swagger specifications.

```dart
class SpecValidator {
  static List<SpecIssue> validate(Map<String, dynamic> spec);
}
```

**Methods:**
- `validate(spec)`: Validates spec and returns list of issues

### SpecIssue

Represents a validation issue.

```dart
class SpecIssue {
  final IssueSeverity severity;
  final String message;
  final String path;

  SpecIssue({
    required this.severity,
    required this.message,
    required this.path,
  });
}
```

### IssueSeverity

Validation issue severity.

```dart
enum IssueSeverity {
  error,
  warning,
}
```

### SpecCache

Caches parsed OpenAPI specifications.

```dart
class SpecCache {
  SpecCache({required String cacheDir});

  Future<Map<String, dynamic>?> getCachedSpec(String specPath);
  Future<void> cacheSpec(String specPath, Map<String, dynamic> spec);
  Future<void> clear();
}
```

### ConfigValidator

Validates generator configuration.

```dart
class ConfigValidator {
  static void validate(ApiGeneratorConfig config);
}
```

**Methods:**
- `validate(config)`: Validates configuration and throws `ConfigValidationException` on failure

### ModelsResolver

Interface for resolving OpenAPI `$ref` to Dart model types.

```dart
abstract class ModelsResolver {
  Future<String?> resolveRefToType(String ref);
  Future<String?> getImportPath(String typeName);
  Future<bool> isModelType(String typeName);
}
```

### FileBasedModelsResolver

File-based implementation of `ModelsResolver`.

```dart
class FileBasedModelsResolver implements ModelsResolver {
  FileBasedModelsResolver({
    required String projectDir,
    ModelsConfig? modelsConfig,
  });

  @override
  Future<String?> resolveRefToType(String ref);

  @override
  Future<String?> getImportPath(String typeName);

  @override
  Future<bool> isModelType(String typeName);
}
```

### NoOpModelsResolver

No-op implementation that returns `Map<String, dynamic>`.

```dart
class NoOpModelsResolver implements ModelsResolver {
  const NoOpModelsResolver();

  @override
  Future<String?> resolveRefToType(String ref) => Future.value(null);

  @override
  Future<String?> getImportPath(String typeName) => Future.value(null);

  @override
  Future<bool> isModelType(String typeName) => Future.value(false);
}
```

## Generated Client API

### ApiClient

Main client class generated from OpenAPI spec.

```dart
class ApiClient {
  final ApiClientConfig _config;

  ApiClient(this._config);

  DefaultApi get defaultApi => DefaultApi(_config);

  Future<void> close();
  ApiClient withHeaders(Map<String, String> headers);
}
```

**Methods:**
- `close()`: Closes the client and releases resources
- `withHeaders(headers)`: Creates a new client with merged headers

### DefaultApi

Generated API class containing endpoint methods.

```dart
class DefaultApi {
  final ApiClientConfig _config;

  DefaultApi(this._config);

  // Generated methods based on OpenAPI spec
  Future<ReturnType> methodName({...parameters}) async {
    // Generated implementation
  }
}
```

Methods are generated based on OpenAPI spec `operationId` values.

## Type Definitions

### RequestTransformer

```dart
typedef RequestTransformer = Future<HttpRequest> Function(HttpRequest request);
```

### ResponseTransformer

```dart
typedef ResponseTransformer = Future<HttpResponse> Function(HttpResponse response);
```
