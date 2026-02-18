# Usage Guide

Complete guide to using `dart_swagger_to_api_client` to generate type-safe HTTP clients from OpenAPI/Swagger specifications.

## Table of Contents

1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Configuration](#configuration)
4. [CLI Usage](#cli-usage)
5. [Generated Client Usage](#generated-client-usage)
6. [HTTP Adapters](#http-adapters)
7. [Authentication](#authentication)
8. [Middleware](#middleware)
9. [Environment Profiles](#environment-profiles)
10. [Watch Mode](#watch-mode)
11. [CI/CD Integration](#cicd-integration)
12. [State Management Integration](#state-management-integration)
13. [Troubleshooting](#troubleshooting)

## Installation

Add `dart_swagger_to_api_client` to your `pubspec.yaml`:

```yaml
dev_dependencies:
  dart_swagger_to_models: ^0.9.0
  dart_swagger_to_api_client: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Step 1: Generate Models

First, generate models using `dart_swagger_to_models`:

```bash
dart run dart_swagger_to_models:dart_swagger_to_models \
  --input swagger/api.yaml \
  --output-dir lib/models \
  --style json_serializable
```

### Step 2: Generate API Client

Generate the API client:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

### Step 3: Use the Client

```dart
import 'package:my_app/api_client/api_client.dart';
import 'package:my_app/models/user.dart';

final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    bearerToken: 'your-token-here',
  ),
);

final client = ApiClient(config);

try {
  final List<User> users = await client.defaultApi.getUsers();
  print('Users: $users');
} finally {
  await client.close();
}
```

## Configuration

### Configuration File

Create `dart_swagger_to_api_client.yaml` in your project root:

```yaml
input: swagger/api.yaml
outputDir: lib/api_client

client:
  baseUrl: https://api.example.com
  headers:
    User-Agent: my-app/1.0.0
  timeout: 30000  # milliseconds
  auth:
    bearerToken: your-token-here
    # or
    bearerTokenEnv: API_BEARER_TOKEN

http:
  adapter: http  # or 'dio', 'custom'
  customAdapterType: MyCustomAdapter  # if using custom

environments:
  dev:
    baseUrl: https://dev-api.example.com
    headers:
      X-Environment: dev
  prod:
    baseUrl: https://api.example.com
    auth:
      bearerTokenEnv: PROD_BEARER_TOKEN
```

### Using Configuration

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

## CLI Usage

### Basic Command

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

### All Options

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \          # Required: OpenAPI spec path
  --output-dir lib/api_client \       # Required: Output directory
  --config config.yaml \              # Optional: Config file
  --env prod \                        # Optional: Environment profile
  --watch \                           # Optional: Watch mode
  --verbose \                         # Optional: Verbose output
  --quiet                             # Optional: Quiet mode
```

### Option Details

| Option | Short | Required | Description |
|--------|-------|----------|-------------|
| `--input` | `-i` | Yes | Path to OpenAPI/Swagger spec (YAML or JSON) |
| `--output-dir` | - | Yes | Directory where client code will be generated |
| `--config` | `-c` | No | Path to configuration file |
| `--env` | - | No | Environment profile name (dev, staging, prod, etc.) |
| `--watch` | `-w` | No | Enable watch mode for auto-regeneration |
| `--verbose` | `-v` | No | Show detailed output including warnings |
| `--quiet` | `-q` | No | Show only errors, suppress warnings |
| `--help` | `-h` | No | Show usage information |

## Generated Client Usage

### Basic API Calls

```dart
final client = ApiClient(config);

// GET request
final users = await client.defaultApi.getUsers();

// GET with parameters
final user = await client.defaultApi.getUser(userId: '123');

// POST request
final newUser = await client.defaultApi.createUser(
  body: User(name: 'John', email: 'john@example.com'),
);

// PUT request
final updatedUser = await client.defaultApi.updateUser(
  userId: '123',
  body: User(name: 'Jane', email: 'jane@example.com'),
);

// DELETE request
await client.defaultApi.deleteUser(userId: '123');
```

### Response Types

The generator automatically determines response types:

- `Future<void>` — for 204 No Content responses
- `Future<Map<String, dynamic>>` — for object responses
- `Future<List<Map<String, dynamic>>>` — for array responses
- `Future<ModelType>` — when models are integrated
- `Future<List<ModelType>>` — for arrays of models

### Error Handling

```dart
try {
  final user = await client.defaultApi.getUser(userId: '123');
} on ApiAuthException catch (e) {
  // Handle authentication errors (401, 403)
  print('Auth error: ${e.message}');
} on ApiServerException catch (e) {
  // Handle server errors (5xx)
  print('Server error: ${e.message}');
} on TimeoutException catch (e) {
  // Handle timeouts
  print('Request timed out: ${e.message}');
} on ApiClientException catch (e) {
  // Handle other client errors
  print('Client error: ${e.message}');
}
```

### Working with response headers

When response headers are defined in the OpenAPI specification, methods return `ApiResponse<T>` instead of `T` directly:

```dart
// If headers are defined in the spec:
// responses:
//   '200':
//     headers:
//       ETag:
//         schema:
//           type: string
//       X-RateLimit-Limit:
//         schema:
//           type: integer
//           required: true

final response = await client.defaultApi.getUser(id: '123');
final user = response.data; // User or Map<String, dynamic>
final etag = response.headers['ETag']; // String?
final rateLimit = response.headers['X-RateLimit-Limit']; // String?

// If headers are not defined in the spec, method returns data directly:
final user = await client.defaultApi.getUser(id: '123'); // User or Map<String, dynamic>
```

`ApiResponse<T>` provides:
- `data`: Response body (typed data)
- `headers`: Map<String, String> with all response headers

### Resource Management

Always close the client when done:

```dart
final client = ApiClient(config);
try {
  // Use client
} finally {
  await client.close(); // Releases adapter resources
}
```

### Scoped Clients

Create clients with additional headers:

```dart
final baseClient = ApiClient(config);

final scopedClient = baseClient.withHeaders({
  'X-Request-ID': '123',
  'X-User-ID': 'user-456',
});

// All requests through scopedClient include these headers
final users = await scopedClient.defaultApi.getUsers();
```

## HTTP Adapters

### Default Adapter (package:http)

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  // Uses HttpHttpClientAdapter by default
);
```

### Dio Adapter

```dart
import 'package:dio/dio.dart';
import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

final dio = Dio();
final adapter = DioHttpClientAdapter(dio: dio);

final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  httpClientAdapter: adapter,
);
```

### Custom Adapter

```dart
class MyCustomAdapter implements HttpClientAdapter {
  @override
  Future<HttpResponse> send(HttpRequest request) async {
    // Your custom implementation
    // ...
  }

  @override
  Future<void> close() async {
    // Cleanup if needed
  }
}

final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  httpClientAdapter: MyCustomAdapter(),
);
```

## Authentication

### Bearer Token

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    bearerToken: 'your-token-here',
  ),
);
```

### Bearer Token from Environment

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    bearerTokenEnv: 'API_BEARER_TOKEN', // Reads from environment
  ),
);
```

### API Key in Header

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    apiKeyHeader: 'X-API-Key',
    apiKey: 'your-api-key',
  ),
);
```

### API Key in Query

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    apiKeyQuery: 'api_key',
    apiKey: 'your-api-key',
  ),
);
```

## Middleware

### Logging

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    LoggingInterceptor.console(
      logHeaders: true,
      logBody: false,
    ),
  ],
  responseInterceptors: [
    LoggingInterceptor.console(),
  ],
);
```

### Retries

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  responseInterceptors: [
    RetryInterceptor(
      maxRetries: 3,
      retryableStatusCodes: {500, 502, 503, 504},
      retryableErrors: {TimeoutException},
      baseDelayMs: 1000,
      maxDelayMs: 10000,
    ),
  ],
);
```

### Rate Limiting

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    RateLimitInterceptor(
      maxRequests: 100,
      window: Duration(minutes: 1),
    ),
  ],
);
```

### Circuit Breaker

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    CircuitBreakerInterceptor(
      failureThreshold: 5,
      timeout: Duration(seconds: 60),
      resetTimeout: Duration(seconds: 30),
    ),
  ],
  responseInterceptors: [
    CircuitBreakerInterceptor(
      failureThreshold: 5,
      timeout: Duration(seconds: 60),
      resetTimeout: Duration(seconds: 30),
    ),
  ],
);
```

### Request/Response Transformers

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    TransformerInterceptor(
      requestTransformer: RequestTransformers.addHeaders({
        'X-Request-ID': generateId(),
      }),
    ),
  ],
  responseInterceptors: [
    TransformerInterceptor(
      responseTransformer: ResponseTransformers.normalizeStatusCodes({
        201: 200,
        204: 200,
      }),
    ),
  ],
);
```

## Environment Profiles

### Configuration

```yaml
# dart_swagger_to_api_client.yaml
client:
  baseUrl: https://api.example.com
  headers:
    User-Agent: my-app/1.0.0

environments:
  dev:
    baseUrl: https://dev-api.example.com
    headers:
      X-Environment: dev
  staging:
    baseUrl: https://staging-api.example.com
    headers:
      X-Environment: staging
  prod:
    baseUrl: https://api.example.com
    auth:
      bearerTokenEnv: PROD_BEARER_TOKEN
```

### Usage

```bash
# Development
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --env dev

# Production
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

## Watch Mode

Automatically regenerate the client when the spec or config changes:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --watch
```

**Features:**
- Runs generation once at startup
- Watches spec and config files for changes
- Auto-reloads config when it changes
- Debounce: 500ms to prevent multiple regenerations
- Press `Ctrl+C` to stop

**Note:** Watch mode only works with local files, not URLs.

## CI/CD Integration

### GitHub Actions

Copy `.github/workflows/regenerate-client.yml` to your repository:

```yaml
# .github/workflows/regenerate-client.yml
name: Regenerate API Client

on:
  push:
    paths:
      - 'swagger/**'
```

### GitLab CI

Copy `.gitlab-ci.yml` to your repository root.

See `ci/README.md` for detailed setup instructions.

## State Management Integration

### Riverpod

See `example/riverpod_integration_example.dart` for complete examples:

- `Provider` and `FutureProvider` for simple cases
- `StateNotifier` for complex state management
- Error handling and loading states

### BLoC

See `example/bloc_integration_example.dart` for complete examples:

- Events and States definitions
- BLoC implementations
- Repository pattern
- Widget integration

## Troubleshooting

### Common Issues

**Issue: Models not found**

**Solution:** Ensure you've generated models first using `dart_swagger_to_models`, and that the `dart_swagger_to_models.yaml` config file exists.

**Issue: Missing operationId**

**Solution:** Add `operationId` to all operations in your OpenAPI spec. Operations without `operationId` are skipped.

**Issue: Unsupported content type**

**Solution:** Currently supported content types:
- `application/json` (request body: `Map<String, dynamic>` or model type)
- `application/x-www-form-urlencoded` (request body: `Map<String, String>`)
- `multipart/form-data` (request body: `Map<String, dynamic>` with File/List<int> support)
- `text/plain` (request body: `String`)
- `text/html` (request body: `String`)
- `application/xml` (request body: `String` for simple types, `Map<String, dynamic>` for complex types)
- Other custom content types (supported with basic handling)

When multiple content types are present in the spec, the type with the highest priority is automatically selected.

**Issue: Watch mode not working**

**Solution:** Ensure you're using a local file path, not a URL. Watch mode doesn't support remote URLs.

### Getting Help

- Check the [FAQ](doc/en/FAQ.md)
- See [Troubleshooting Guide](doc/en/TROUBLESHOOTING.md)
- Open an issue on [GitHub](https://github.com/AlexGalitsky/dart_swagger_to_api_client/issues)
