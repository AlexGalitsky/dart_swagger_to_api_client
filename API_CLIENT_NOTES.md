## API Client Generator Design Notes (`dart_swagger_to_api_client`)

This document describes the proposed architecture and public API for a separate package
`dart_swagger_to_api_client`, which will build on top of `dart_swagger_to_models`.

The idea is to keep **model generation** and **API client generation** as separate concerns:

- `dart_swagger_to_models` — generates null-safe Dart models from Swagger/OpenAPI specs.
- `dart_swagger_to_api_client` — generates a type-safe HTTP client on top of those models.

---

### 1. Purpose and Scope

- Generate a **type-safe API client** from an OpenAPI/Swagger specification:
  - strongly typed methods per endpoint;
  - HTTP handling (on the first iteration via `package:http`, later via pluggable adapters);
  - reuse of configuration: `baseUrl`, default headers, auth, timeouts.
- The package **depends on** `dart_swagger_to_models`, but does not duplicate model logic.
- Configuration file is similar in spirit to `dart_swagger_to_models.yaml`, but specific to API client concerns.

---

### 2. Package Structure (proposed)

In the new repository/folder `dart_swagger_to_api_client`:

- `pubspec.yaml`
  - `name: dart_swagger_to_api_client`
  - Dependencies:
    - `dart_swagger_to_models: ^0.6.0`
    - `http: ^1.6.0` (or later via adapters, e.g. `dio`)
    - `yaml`, `path`, `args` – for config and CLI.

- `bin/`
  - `dart_swagger_to_api_client.dart`
    - CLI entry point with options:
      - `--input` / `-i` — path to OpenAPI/Swagger spec (YAML/JSON),
      - `--config` / `-c` — path to `dart_swagger_to_api_client.yaml`,
      - `--output-dir` — where to put generated client code,
      - `--http-client` — HTTP strategy: `http`, `dio`, `custom`,
      - `--dry-run` — show what would be generated without writing files,
      - (later) `--watch`, `--interactive` similar to the models package.

- `lib/`
  - `dart_swagger_to_api_client.dart`
    - Public facade exporting configuration and generation API.

  - `src/config/`
    - `config.dart`
      - `ApiClientConfig` – base URL, headers, timeout, auth, HTTP adapter.
      - `AuthConfig` – API key / bearer token configuration.
    - `config_loader.dart`
      - Loads and parses `dart_swagger_to_api_client.yaml`.

  - `src/core/`
    - `spec_loader.dart`
      - Reads and parses OpenAPI/Swagger specs (can reuse patterns from the models package).
    - `client_generator.dart`
      - Core logic: analyzes endpoints and generates Dart files for the client.
    - `http_client_adapter.dart`
      - Abstraction over different HTTP implementations.

  - `src/generators/`
    - `api_client_class_generator.dart`
      - Generates the main `ApiClient` and per-resource classes (`UsersApi`, `OrdersApi`, ...).
    - `endpoint_method_generator.dart`
      - Generates individual endpoint methods: `getUser`, `createOrder`, `listUsers`, etc.

- `example/`
  - Minimal project that:
    - runs `dart_swagger_to_models` to generate models;
    - runs `dart_swagger_to_api_client` to generate the client;
    - performs at least one example API call.

---

### 3. Core Dart Types (in the API client package)

#### 3.1 Configuration and HTTP abstraction

```dart
/// High-level configuration for generated client.
class ApiClientConfig {
  final Uri baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final AuthConfig? auth;
  final HttpClientAdapter httpClientAdapter;

  const ApiClientConfig({
    required this.baseUrl,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
    this.auth,
    HttpClientAdapter? httpClientAdapter,
  }) : httpClientAdapter = httpClientAdapter ?? HttpHttpClientAdapter();
}

class AuthConfig {
  final String? apiKeyHeader;
  final String? apiKeyQuery;
  final String? bearerToken;

  const AuthConfig({
    this.apiKeyHeader,
    this.apiKeyQuery,
    this.bearerToken,
  });
}

/// Abstraction over concrete HTTP implementation (http, dio, custom).
abstract class HttpClientAdapter {
  Future<HttpResponse> send(HttpRequest request);
}

class HttpRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Object? body; // encoded JSON or null

  HttpRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
  });
}

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

#### 3.2 High-level generator API

```dart
/// High-level API for generating API clients from OpenAPI/Swagger specs.
class ApiClientGenerator {
  /// Generates API client Dart files into [outputDir].
  ///
  /// - [inputSpecPath]: path to OpenAPI/Swagger spec (yaml/json)
  /// - [outputDir]: directory where client code will be written
  /// - [config]: optional configuration (base URL, auth, HTTP adapter hints)
  /// - [projectDir]: project root, to resolve relative paths if needed
  static Future<void> generateClient({
    required String inputSpecPath,
    required String outputDir,
    ApiClientConfig? config,
    String? projectDir,
  });
}
```

---

### 4. Shape of the Generated Client Code

An example of what the user of the generated client might see:

```dart
import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';
import 'package:my_app/models/user.dart';

/// Main entry point for working with API.
class ApiClient {
  final ApiClientConfig _config;

  ApiClient(this._config);

  UsersApi get users => UsersApi(_config);
  OrdersApi get orders => OrdersApi(_config);
}

class UsersApi {
  final ApiClientConfig _config;

  UsersApi(this._config);

  Future<User> getUser({required String id}) async {
    final request = HttpRequest(
      method: 'GET',
      url: _config.baseUrl.replace(path: '/users/$id'),
      headers: _config.defaultHeaders,
    );

    final response = await _config.httpClientAdapter.send(request);
    // handle status codes, errors, etc.
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(json);
  }

  Future<List<User>> listUsers() async {
    // ...
  }
}
```

---

### 5. CLI Interface (proposed)

Executable: `bin/dart_swagger_to_api_client.dart`

Example usage:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml
```

Key options:

- `--input` / `-i`: path to spec.
- `--output-dir`: where to put generated client code.
- `--config` / `-c`: path to the YAML configuration file.
- `--http-client`: `http` (default), `dio`, `custom`.
- `--verbose` / `-v`, `--quiet` / `-q`.
- (future) `--watch`, `--interactive`.

---

### 6. Configuration File Draft (`dart_swagger_to_api_client.yaml`)

```yaml
# Path to OpenAPI/Swagger spec (optional if passed via CLI)
input: swagger/api.yaml

# Where to put generated client code
outputDir: lib/api_client

client:
  baseUrl: https://api.example.com
  timeoutMs: 30000

  # Default headers for all requests
  headers:
    User-Agent: my-app/1.0.0

  auth:
    # Either API key or bearer token (or both if needed)
    apiKeyHeader: X-API-Key
    apiKeyQuery: api_key
    bearerTokenEnv: API_BEARER_TOKEN

http:
  # http | dio | custom
  adapter: http
  # For custom: name of a Dart type implementing HttpClientAdapter
  customAdapterType: MyCustomHttpClientAdapter
```

---

### 7. Relationship to `ROADMAP.ru.md` (0.9.2)

This document describes the initial design for **"0.9.2 Генерация API клиента (экспериментально)"**
and can be used as a reference when implementing the new package
`dart_swagger_to_api_client` in a separate repository or folder.

