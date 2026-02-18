# dart_swagger_to_api_client

[![Dart](https://img.shields.io/badge/Dart-3.11.0+-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> **Generate type-safe HTTP API clients from OpenAPI/Swagger specifications**

`dart_swagger_to_api_client` is a code generator that creates fully type-safe, production-ready HTTP clients for Dart and Flutter applications. It works seamlessly with `dart_swagger_to_models` to generate a complete stack: models + API client.

## ✨ Features

- 🎯 **Type-safe API calls** — Strongly typed methods generated from OpenAPI specs
- 🔄 **Multiple HTTP adapters** — Support for `http`, `dio`, and custom adapters
- 🛡️ **Middleware system** — Logging, retries, rate limiting, circuit breakers, and more
- 🔐 **Flexible authentication** — API keys, bearer tokens, environment variables
- 🌍 **Environment profiles** — Easy switching between dev/staging/prod
- 📦 **Model integration** — Automatic integration with `dart_swagger_to_models`
- ⚡ **Watch mode** — Auto-regenerate on spec changes
- 🚀 **CI/CD ready** — Templates for GitHub Actions and GitLab CI
- 📚 **State management** — Examples for Riverpod and BLoC

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  dart_swagger_to_models: ^0.9.0
  dart_swagger_to_api_client: ^1.0.0
```

### Basic Usage

1. **Generate models** (using `dart_swagger_to_models`):

```bash
dart run dart_swagger_to_models:dart_swagger_to_models \
  --input swagger/api.yaml \
  --output-dir lib/models \
  --style json_serializable
```

2. **Generate API client**:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

3. **Use in your code**:

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
  // Type-safe API call
  final List<User> users = await client.defaultApi.getUsers();
  print('Users: $users');
} finally {
  await client.close();
}
```

## 📖 Documentation

- **[Usage Guide](doc/en/USAGE.md)** — Complete usage documentation
- **[Developer Guide](doc/en/DEVELOPERS.md)** — Contributing and development
- **[Context for AI](doc/en/CONTEXT.md)** — Quick context restoration for AI assistants
- **[Roadmap](doc/ROADMAP.ru.md)** — Development roadmap (Russian)

## 🎯 Key Concepts

### HTTP Adapters

Choose your HTTP implementation:

```dart
// Default: package:http
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
);

// Dio adapter
import 'package:dio/dio.dart';
final dio = Dio();
final adapter = DioHttpClientAdapter(dio: dio);
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  httpClientAdapter: adapter,
);

// Custom adapter
class MyCustomAdapter implements HttpClientAdapter {
  @override
  Future<HttpResponse> send(HttpRequest request) async {
    // Your implementation
  }
}
```

### Middleware

Add powerful middleware to your client:

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    RateLimitInterceptor(maxRequests: 100, window: Duration(minutes: 1)),
    LoggingInterceptor.console(),
  ],
  responseInterceptors: [
    RetryInterceptor(maxRetries: 3),
    CircuitBreakerInterceptor(failureThreshold: 5),
  ],
);
```

### Environment Profiles

Configure different environments:

```yaml
# dart_swagger_to_api_client.yaml
client:
  baseUrl: https://api.example.com

environments:
  dev:
    baseUrl: https://dev-api.example.com
  prod:
    baseUrl: https://api.example.com
    auth:
      bearerTokenEnv: PROD_BEARER_TOKEN
```

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

## 📚 Examples

See the `example/` directory for complete examples:

- `complete_example.dart` — Full end-to-end example
- `auth_example.dart` — Authentication methods
- `error_handling_example.dart` — Error handling and retries
- `middleware_example.dart` — Middleware usage
- `circuit_breaker_example.dart` — Circuit breaker pattern
- `transformer_example.dart` — Request/response transformations
- `riverpod_integration_example.dart` — Riverpod integration
- `bloc_integration_example.dart` — BLoC integration

## 🛠️ CLI Options

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod \
  --watch \
  --verbose
```

**Options:**
- `--input` / `-i` — OpenAPI/Swagger spec path (required)
- `--output-dir` — Output directory (required)
- `--config` / `-c` — Configuration file path
- `--env` — Environment profile name
- `--watch` / `-w` — Watch mode for auto-regeneration
- `--verbose` / `-v` — Verbose output
- `--quiet` / `-q` — Quiet mode (errors only)
- `--help` / `-h` — Show help

## 🔄 Watch Mode

Automatically regenerate on spec changes:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --watch
```

## 🤖 CI/CD Integration

Ready-to-use templates for automatic regeneration:

- **GitHub Actions** — `.github/workflows/regenerate-client.yml`
- **GitLab CI** — `.gitlab-ci.yml`

See `ci/README.md` for setup instructions.

## 🎨 State Management Integration

Examples for popular state management solutions:

- **Riverpod** — `example/riverpod_integration_example.dart`
- **BLoC** — `example/bloc_integration_example.dart`

## 📋 Requirements

- Dart SDK: `^3.11.0`
- `dart_swagger_to_models` (for model generation)

## 🤝 Contributing

Contributions are welcome! Please see [DEVELOPERS.md](doc/en/DEVELOPERS.md) for guidelines.

## 📄 License

MIT License — see [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [`dart_swagger_to_models`](https://github.com/AlexGalitsky/dart_swagger_to_models) — Generate Dart models from OpenAPI specs

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/AlexGalitsky/dart_swagger_to_api_client/issues)
- **Documentation**: See `doc/` directory

---

**Made with ❤️ for the Dart/Flutter community**
