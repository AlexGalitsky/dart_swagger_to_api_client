# Developer Guide

This document explains how the project is structured and how to work with the codebase as a contributor.

## Table of Contents

1. [Repository Structure](#repository-structure)
2. [Architecture Overview](#architecture-overview)
3. [Development Workflow](#development-workflow)
4. [Code Organization](#code-organization)
5. [Testing](#testing)
6. [Adding New Features](#adding-new-features)
7. [Coding Standards](#coding-standards)
8. [Contributing Guidelines](#contributing-guidelines)

## Repository Structure

```
dart_swagger_to_api_client/
├── bin/
│   └── dart_swagger_to_api_client.dart    # CLI entry point
├── lib/
│   ├── dart_swagger_to_api_client.dart    # Public API facade
│   └── src/
│       ├── config/                        # Configuration
│       │   ├── config.dart                # ApiClientConfig, AuthConfig
│       │   └── config_loader.dart         # YAML config loader
│       ├── core/                          # Core functionality
│       │   ├── client_generator.dart      # Main generator orchestrator
│       │   ├── spec_loader.dart           # OpenAPI spec loader
│       │   ├── spec_validator.dart        # Spec validation
│       │   ├── http_client_adapter.dart   # HTTP abstraction
│       │   ├── dio_http_client_adapter.dart # Dio adapter
│       │   ├── errors.dart                # Exception types
│       │   ├── middleware.dart            # Middleware interfaces
│       │   └── middleware/                # Middleware implementations
│       │       ├── logging_middleware.dart
│       │       ├── retry_middleware.dart
│       │       ├── rate_limit_middleware.dart
│       │       ├── circuit_breaker_middleware.dart
│       │       └── transformer_middleware.dart
│       ├── generators/                    # Code generators
│       │   ├── api_client_class_generator.dart  # ApiClient class
│       │   └── endpoint_method_generator.dart   # Endpoint methods
│       └── models/                        # Models integration
│           ├── models_resolver.dart        # Resolver interface
│           ├── models_config.dart         # Models config DTOs
│           ├── models_config_loader.dart   # Load models config
│           └── file_based_models_resolver.dart  # File-based resolver
├── test/                                  # Test suites
├── example/                               # Usage examples
├── doc/                                   # Documentation
│   ├── en/                                # English docs
│   └── ru/                                # Russian docs
└── ci/                                    # CI/CD templates
```

## Architecture Overview

### Core Components

1. **Spec Loading** (`spec_loader.dart`)
   - Loads OpenAPI/Swagger specs from YAML/JSON files
   - Returns `Map<String, dynamic>`

2. **Spec Validation** (`spec_validator.dart`)
   - Validates spec structure
   - Checks for required fields (`paths`, `operationId`)
   - Reports warnings for unsupported features
   - Returns `List<ValidationIssue>`

3. **Client Generation** (`client_generator.dart`)
   - Orchestrates the generation process
   - Loads models config and creates resolver
   - Calls generators and writes output

4. **Code Generators**
   - `ApiClientClassGenerator`: Generates `ApiClient` and `DefaultApi` classes
   - `EndpointMethodGenerator`: Generates individual endpoint methods

5. **HTTP Abstraction** (`http_client_adapter.dart`)
   - `HttpClientAdapter` interface
   - `HttpRequest` and `HttpResponse` models
   - Implementations: `HttpHttpClientAdapter`, `DioHttpClientAdapter`

6. **Middleware System** (`middleware.dart`)
   - `RequestInterceptor` and `ResponseInterceptor` interfaces
   - `MiddlewareHttpClientAdapter` for chaining middleware
   - Built-in middleware: logging, retry, rate limiting, circuit breaker, transformers

7. **Models Integration** (`models/`)
   - `ModelsResolver` interface for resolving `$ref` to Dart types
   - `FileBasedModelsResolver` scans generated model files
   - `NoOpModelsResolver` as fallback

### Data Flow

```
OpenAPI Spec (YAML/JSON)
    ↓
SpecLoader.load()
    ↓
SpecValidator.validate()
    ↓
ModelsConfigLoader.load() → ModelsResolver
    ↓
EndpointMethodGenerator.generateDefaultApiMethods()
    ↓
ApiClientClassGenerator.generate()
    ↓
api_client.dart (generated)
```

## Development Workflow

### Setup

1. Clone the repository:
```bash
git clone https://github.com/AlexGalitsky/dart_swagger_to_api_client.git
cd dart_swagger_to_api_client
```

2. Install dependencies:
```bash
dart pub get
```

3. Run tests:
```bash
dart test
```

### Running Analysis

```bash
dart analyze
```

### Running Tests

```bash
# All tests
dart test

# Specific test file
dart test test/endpoint_method_generator_test.dart

# With verbose output
dart test --reporter=expanded
```

### Testing Generated Code

1. Generate client from example spec:
```bash
dart run bin/dart_swagger_to_api_client.dart \
  --input example/swagger/api.yaml \
  --output-dir example/generated
```

2. Check generated code:
```bash
cat example/generated/api_client.dart
```

## Code Organization

### Configuration Layer (`lib/src/config/`)

- **`config.dart`**: Core configuration classes
  - `ApiClientConfig`: Main client configuration
  - `AuthConfig`: Authentication settings
  - `EnvironmentProfile`: Environment-specific configs

- **`config_loader.dart`**: YAML configuration loader
  - Parses `dart_swagger_to_api_client.yaml`
  - Merges base config with environment profiles
  - Handles CLI argument overrides

### Core Layer (`lib/src/core/`)

- **`client_generator.dart`**: Main orchestrator
  - Entry point: `ApiClientGenerator.generateClient()`
  - Coordinates spec loading, validation, and generation
  - Manages models resolver initialization

- **`spec_loader.dart`**: Spec file loading
  - Supports YAML and JSON formats
  - Handles file paths and URLs (for future)

- **`spec_validator.dart`**: Spec validation
  - Validates OpenAPI structure
  - Checks for required fields
  - Reports warnings for unsupported features

- **`http_client_adapter.dart`**: HTTP abstraction
  - `HttpClientAdapter` interface
  - `HttpRequest` and `HttpResponse` models
  - `HttpHttpClientAdapter` implementation

- **`dio_http_client_adapter.dart`**: Dio adapter
  - `DioHttpClientAdapter` implementation
  - Maps Dio types to adapter interface

- **`errors.dart`**: Exception types
  - `ApiClientException`: Base exception
  - `ApiServerException`: Server errors (5xx)
  - `ApiAuthException`: Auth errors (401, 403)
  - `TimeoutException`: Timeout errors

- **`middleware.dart`**: Middleware system
  - `RequestInterceptor` and `ResponseInterceptor` interfaces
  - `MiddlewareHttpClientAdapter` implementation

### Generators Layer (`lib/src/generators/`)

- **`api_client_class_generator.dart`**: Generates main client class
  - `ApiClient` class with `defaultApi` getter
  - `DefaultApi` class with endpoint methods
  - `close()` and `withHeaders()` methods

- **`endpoint_method_generator.dart`**: Generates endpoint methods
  - Parses OpenAPI paths and operations
  - Generates method signatures with parameters
  - Handles request bodies and responses
  - Integrates with models resolver

### Models Layer (`lib/src/models/`)

- **`models_resolver.dart`**: Resolver interface
  - `ModelsResolver` abstract class
  - `NoOpModelsResolver` fallback implementation

- **`models_config.dart`**: Models config DTOs
  - `ModelsConfig`: Configuration from `dart_swagger_to_models.yaml`
  - `SchemaOverride`: Schema-specific overrides

- **`models_config_loader.dart`**: Loads models config
  - Scans for `dart_swagger_to_models.yaml`
  - Parses configuration

- **`file_based_models_resolver.dart`**: File-based resolver
  - Scans generated model files
  - Maps schema names to Dart class names
  - Resolves `$ref` to import paths

## Testing

### Test Structure

Tests are organized by topic:

- `api_client_generator_test.dart`: Integration tests for full generation
- `endpoint_method_generator_test.dart`: Unit tests for method generation
- `spec_validator_test.dart`: Validation tests
- `config_loader_test.dart`: Configuration loading tests
- `http_client_adapter_test.dart`: HTTP adapter tests
- `middleware_*_test.dart`: Middleware tests
- `integration_test.dart`: End-to-end tests (optional, requires internet)
- `regression_test.dart`: Regression tests
- `edge_cases_test.dart`: Edge case tests

### Running Tests

```bash
# All tests
dart test

# Specific suite
dart test test/endpoint_method_generator_test.dart

# With coverage (requires coverage package)
dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

### Writing Tests

1. Follow existing test patterns
2. Use descriptive test names
3. Test both success and error cases
4. Mock external dependencies when possible
5. Use `setUp` and `tearDown` for common setup

Example:

```dart
test('generates GET method with path parameters', () async {
  final generator = EndpointMethodGenerator();
  final spec = {
    'paths': {
      '/users/{id}': {
        'get': {
          'operationId': 'getUser',
          'parameters': [
            {'name': 'id', 'in': 'path', 'required': true, 'schema': {'type': 'string'}},
          ],
          'responses': {'200': {'description': 'OK'}},
        },
      },
    },
  };

  final result = await generator.generateDefaultApiMethods(spec);
  
  expect(result.methods, contains('getUser'));
  expect(result.methods, contains('required String id'));
});
```

## Adding New Features

### Step-by-Step Process

1. **Plan the feature**
   - Check `doc/ROADMAP.ru.md` for planned features
   - Create an issue or discuss in PR
   - Design the API and architecture

2. **Implement the feature**
   - Create a feature branch
   - Write code following coding standards
   - Add tests
   - Update documentation

3. **Test thoroughly**
   - Run all existing tests
   - Add new tests for the feature
   - Test edge cases

4. **Update documentation**
   - Update README if needed
   - Add usage examples
   - Update USAGE.md
   - Update CONTEXT.md if architecture changes

5. **Submit PR**
   - Write clear PR description
   - Reference related issues
   - Ensure CI passes

### Example: Adding a New Middleware

1. Create middleware file:
```dart
// lib/src/core/middleware/my_middleware.dart
class MyMiddleware implements RequestInterceptor {
  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    // Implementation
  }
}
```

2. Export in public API:
```dart
// lib/dart_swagger_to_api_client.dart
export 'src/core/middleware/my_middleware.dart';
```

3. Add tests:
```dart
// test/my_middleware_test.dart
test('MyMiddleware modifies requests correctly', () {
  // Test implementation
});
```

4. Add to master test file:
```dart
// test/dart_swagger_to_api_client_test.dart
import 'my_middleware_test.dart' as my_middleware_test;
// ...
my_middleware_test.main();
```

5. Add example:
```dart
// example/my_middleware_example.dart
// Usage example
```

## Coding Standards

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `dart format` before committing
- Follow existing code patterns

### Naming Conventions

- Classes: `PascalCase` (e.g., `ApiClientConfig`)
- Methods/functions: `camelCase` (e.g., `generateClient`)
- Private members: `_leadingUnderscore` (e.g., `_modelsResolver`)
- Constants: `lowerCamelCase` or `SCREAMING_SNAKE_CASE` (e.g., `maxRetries`)

### Documentation

- Document all public APIs
- Use DartDoc comments (`///`)
- Include examples in documentation
- Document parameters and return values

### Error Handling

- Use specific exception types (`ApiClientException`, `ApiServerException`)
- Provide clear error messages
- Include context in error messages

### Testing

- Aim for high test coverage
- Test both success and error paths
- Use descriptive test names
- Group related tests

## Contributing Guidelines

### Before Contributing

1. Check existing issues and PRs
2. Discuss major changes in an issue first
3. Follow the coding standards
4. Write tests for new features

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Update documentation
6. Run tests and analysis
7. Submit PR with clear description

### Commit Messages

Follow conventional commits:

```
feat: add circuit breaker middleware
fix: correct timeout handling in HttpHttpClientAdapter
docs: update README with new features
test: add tests for rate limiting
refactor: simplify endpoint method generation
```

### Code Review

- Be respectful and constructive
- Review for correctness, style, and tests
- Suggest improvements
- Approve when satisfied

## Key Design Decisions

### Separation of Concerns

- **Models** (`dart_swagger_to_models`) and **Client** (`dart_swagger_to_api_client`) are separate packages
- Models resolver allows loose coupling
- HTTP abstraction allows pluggable implementations

### Middleware System

- Request/Response interceptors for flexibility
- Chain of responsibility pattern
- Built-in middleware for common use cases

### Configuration

- YAML config files for declarative setup
- Environment profiles for different deployments
- CLI arguments override config values

### Error Handling

- Specific exception types for different error categories
- Clear error messages with context
- Proper exception propagation

## Common Tasks

### Adding a New HTTP Adapter

1. Implement `HttpClientAdapter` interface
2. Map adapter-specific types to `HttpRequest`/`HttpResponse`
3. Export in public API
4. Add tests
5. Update documentation

### Adding a New Middleware

1. Implement `RequestInterceptor` or `ResponseInterceptor`
2. Export in public API
3. Add tests
4. Add example
5. Update documentation

### Modifying Generated Code Format

1. Update `ApiClientClassGenerator` or `EndpointMethodGenerator`
2. Update tests to match new format
3. Test with various OpenAPI specs
4. Update documentation

## Resources

- [Dart Style Guide](https://dart.dev/guides/language/effective-dart)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Testing in Dart](https://dart.dev/guides/testing)
