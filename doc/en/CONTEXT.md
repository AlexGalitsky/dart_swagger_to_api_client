# LLM Context — dart_swagger_to_api_client

This file is optimized for neural network / LLM tools to quickly restore project context.

## What This Project Does

- **CLI tool** that **generates type-safe HTTP API clients** from **OpenAPI/Swagger (2.0 / 3.x)** specifications
- **Input**: OpenAPI/Swagger spec (YAML/JSON file)
- **Output**: Generated Dart code with `ApiClient` class and endpoint methods
- **Works with**: `dart_swagger_to_models` for complete stack (models + client)
- **Key feature**: Type-safe API calls with automatic model integration

## Core Architecture

### Package Structure

```
lib/
├── dart_swagger_to_api_client.dart      # Public API facade
└── src/
    ├── config/                          # Configuration
    │   ├── config.dart                  # ApiClientConfig, AuthConfig
    │   └── config_loader.dart           # YAML config loader
    ├── core/                            # Core functionality
    │   ├── client_generator.dart        # Main orchestrator
    │   ├── spec_loader.dart             # OpenAPI spec loader
    │   ├── spec_validator.dart          # Spec validation
    │   ├── http_client_adapter.dart     # HTTP abstraction
    │   ├── dio_http_client_adapter.dart # Dio adapter
    │   ├── errors.dart                  # Exception types
    │   ├── middleware.dart              # Middleware interfaces
    │   └── middleware/                  # Middleware implementations
    ├── generators/                      # Code generators
    │   ├── api_client_class_generator.dart
    │   └── endpoint_method_generator.dart
    └── models/                          # Models integration
        ├── models_resolver.dart
        ├── models_config.dart
        ├── models_config_loader.dart
        └── file_based_models_resolver.dart
```

### Key Components

1. **`ApiClientGenerator`** (`lib/src/core/client_generator.dart`)
   - Entry point: `ApiClientGenerator.generateClient()`
   - Orchestrates: spec loading → validation → models resolution → code generation
   - Returns: Generated `api_client.dart` file

2. **`SpecLoader`** (`lib/src/core/spec_loader.dart`)
   - Loads YAML/JSON OpenAPI specs
   - Returns `Map<String, dynamic>`

3. **`SpecValidator`** (`lib/src/core/spec_validator.dart`)
   - Validates spec structure
   - Checks for `paths`, `operationId`
   - Reports warnings for unsupported features
   - Returns `List<ValidationIssue>`

4. **`EndpointMethodGenerator`** (`lib/src/generators/endpoint_method_generator.dart`)
   - Parses OpenAPI `paths` and `operations`
   - Generates method signatures with parameters (path, query, header, cookie)
   - Handles request bodies (JSON, form-urlencoded, multipart, text/plain, text/html, XML)
   - Classifies response types (void, Map, List, Model)
   - Uses `ModelsResolver` to resolve `$ref` to Dart types
   - Returns: `({String methods, Set<String> imports})`

5. **`ApiClientClassGenerator`** (`lib/src/generators/api_client_class_generator.dart`)
   - Generates `ApiClient` class with `defaultApi` getter
   - Generates `DefaultApi` class with endpoint methods
   - Adds `close()` and `withHeaders()` methods
   - Includes model imports

6. **`HttpClientAdapter`** (`lib/src/core/http_client_adapter.dart`)
   - Abstract interface for HTTP implementations
   - Implementations: `HttpHttpClientAdapter` (http), `DioHttpClientAdapter` (dio)
   - Models: `HttpRequest`, `HttpResponse`

7. **Middleware System** (`lib/src/core/middleware.dart`)
   - `RequestInterceptor`: Modify requests before sending
   - `ResponseInterceptor`: Handle responses and errors
   - `MiddlewareHttpClientAdapter`: Chains middleware
   - Built-in: Logging, Retry, RateLimit, CircuitBreaker, Transformer

8. **Models Integration** (`lib/src/models/`)
   - `ModelsResolver`: Interface for resolving `$ref` → Dart types
   - `FileBasedModelsResolver`: Scans generated model files
   - `NoOpModelsResolver`: Fallback (returns `Map<String, dynamic>`)

## Generation Flow

```
1. Load OpenAPI spec (YAML/JSON)
   ↓ SpecLoader.load()
   
2. Validate spec
   ↓ SpecValidator.validate()
   
3. Load models config (if exists)
   ↓ ModelsConfigLoader.load()
   
4. Initialize models resolver
   ↓ FileBasedModelsResolver or NoOpModelsResolver
   
5. Generate endpoint methods
   ↓ EndpointMethodGenerator.generateDefaultApiMethods()
   - Parses paths and operations
   - Resolves $ref to model types
   - Generates method signatures
   - Classifies response types
   
6. Generate ApiClient class
   ↓ ApiClientClassGenerator.generate()
   - Creates ApiClient and DefaultApi classes
   - Inserts endpoint methods
   - Adds imports
   
7. Write to file
   ↓ api_client.dart
```

## Key Data Structures

### ApiClientConfig

```dart
class ApiClientConfig {
  final Uri baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final AuthConfig? auth;
  final HttpClientAdapter httpClientAdapter;
  final List<RequestInterceptor> requestInterceptors;
  final List<ResponseInterceptor> responseInterceptors;
}
```

### AuthConfig

```dart
class AuthConfig {
  final String? apiKeyHeader;
  final String? apiKeyQuery;
  final String? apiKey;
  final String? bearerToken;
  final String? bearerTokenEnv;  // Environment variable name
}
```

### HttpRequest / HttpResponse

```dart
class HttpRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Object? body;  // Can be String, Map, File, List<int>
  final Duration? timeout;
}

class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;
}
```

## Generation Rules

### Method Generation

- **Operation ID**: Required. Operations without `operationId` are skipped
- **HTTP Methods**: Supports GET, POST, PUT, DELETE, PATCH
- **Parameters**: 
  - `path`: Required parameters in method signature
  - `query`: Optional parameters
  - `header`: Added to request headers
  - `cookie`: Added to Cookie header
- **Request Body**:
  - `application/json`: Serialized to JSON string (type: `Map<String, dynamic>` or model)
  - `application/x-www-form-urlencoded`: Serialized to query string (type: `Map<String, String>`)
  - `multipart/form-data`: Handled as `Map<String, dynamic>` with File/List<int>
  - `text/plain`: Passed as string (type: `String`)
  - `text/html`: Passed as string (type: `String`)
  - `application/xml`: Passed as string for simple types or serialized for complex (type: `String` or `Map<String, dynamic>`)
  - Support for multiple content types with automatic priority-based selection
- **Response Types**:
  - `204 No Content` → `Future<void>` or `Future<ApiResponse<void?>>` (if headers present)
  - Empty content → `Future<void>` or `Future<ApiResponse<void?>>` (if headers present)
  - Object schema → `Future<Map<String, dynamic>>` or `Future<ModelType>` or `Future<ApiResponse<...>>` (if headers present)
  - Array schema → `Future<List<Map<String, dynamic>>>` or `Future<List<ModelType>>` or `Future<ApiResponse<...>>` (if headers present)
- **Response headers**:
  - Automatic parsing of headers from OpenAPI spec (`responses[statusCode].headers`)
  - Generation of `ApiResponse<T>` wrapper when headers are defined in spec
  - Access to headers via `response.headers` (Map<String, String>)
  - Support for required and optional headers (nullable types)

### Model Resolution

- If `dart_swagger_to_models.yaml` exists:
  - `FileBasedModelsResolver` scans model files
  - Maps schema names to Dart class names
  - Resolves `$ref` to import paths
- Otherwise:
  - `NoOpModelsResolver` returns `Map<String, dynamic>`

### Type Classification

```dart
class _ResponseTypeInfo {
  final bool voidResponse;
  final bool mapResponse;
  final bool listResponse;
  final String? modelResponse;
  final String? listModelResponse;
}
```

## Configuration

### YAML Config File

```yaml
input: swagger/api.yaml
outputDir: lib/api_client

client:
  baseUrl: https://api.example.com
  headers:
    User-Agent: my-app/1.0.0
  timeout: 30000
  auth:
    bearerTokenEnv: API_BEARER_TOKEN

http:
  adapter: http  # or 'dio', 'custom'
  customAdapterType: MyCustomAdapter

environments:
  dev:
    baseUrl: https://dev-api.example.com
  prod:
    baseUrl: https://api.example.com
```

### CLI Arguments

- `--input` / `-i`: Spec path (required)
- `--output-dir`: Output directory (required)
- `--config` / `-c`: Config file path
- `--env`: Environment profile name
- `--watch` / `-w`: Watch mode
- `--verbose` / `-v`: Verbose output
- `--quiet` / `-q`: Quiet mode

## Middleware System

### Request Interceptors

- Applied in order before sending request
- Can modify: headers, URL, body, timeout
- Examples: RateLimit, Logging, Transformer

### Response Interceptors

- Applied in reverse order after receiving response
- Can modify: response, throw exceptions
- Examples: Retry, CircuitBreaker, Logging, Transformer

### Error Handling

- Request interceptors can throw exceptions (handled by response interceptors)
- Response interceptors can handle errors via `onError()` method
- RetryInterceptor throws `RetryableException` to signal retry

## Testing

### Test Organization

- `api_client_generator_test.dart`: Full generation cycle
- `endpoint_method_generator_test.dart`: Method generation
- `spec_validator_test.dart`: Validation logic
- `config_loader_test.dart`: Config loading
- `http_client_adapter_test.dart`: HTTP adapter tests
- `middleware_*_test.dart`: Middleware tests
- `integration_test.dart`: End-to-end (optional)
- `regression_test.dart`: Regression tests
- `edge_cases_test.dart`: Edge cases

### Running Tests

```bash
dart test
```

## Common Commands

### Generate Client

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

### With Config

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

### Watch Mode

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --watch
```

## Key Design Decisions

1. **Separation from Models**: Models and client are separate packages for flexibility
2. **HTTP Abstraction**: Pluggable adapters allow different HTTP implementations
3. **Middleware Chain**: Request/Response interceptors for extensibility
4. **Loose Coupling**: Models resolver allows optional model integration
5. **Configuration Priority**: CLI > Config > Defaults

## When Modifying This Project

### Adding New HTTP Adapter

1. Implement `HttpClientAdapter` interface
2. Map adapter types to `HttpRequest`/`HttpResponse`
3. Export in `lib/dart_swagger_to_api_client.dart`
4. Add tests
5. Update documentation

### Adding New Middleware

1. Implement `RequestInterceptor` or `ResponseInterceptor`
2. Export in public API
3. Add tests
4. Add example
5. Update documentation

### Modifying Generation Logic

1. Update `EndpointMethodGenerator` or `ApiClientClassGenerator`
2. Update tests to match new output
3. Test with various OpenAPI specs
4. Update documentation

### Changing Response Type Logic

1. Update `_classifyResponseType()` in `EndpointMethodGenerator`
2. Update `_ResponseTypeInfo` class
3. Update tests that assert on return types
4. Update documentation

## Current Status

- ✅ v0.1-v0.8 completed
- ✅ All major features implemented
- ✅ Comprehensive test suite (173+ tests)
- ✅ Full documentation
- ✅ CI/CD templates
- ✅ State management examples

## Related Files

- `API_CLIENT_NOTES.md`: Original design document
- `doc/ROADMAP.ru.md`: Development roadmap
- `README.md`: User-facing documentation
- `doc/en/USAGE.md`: Detailed usage guide
- `doc/en/DEVELOPERS.md`: Developer guide
