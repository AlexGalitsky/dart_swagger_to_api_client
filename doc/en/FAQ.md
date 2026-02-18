# Frequently Asked Questions (FAQ)

Common questions and answers about `dart_swagger_to_api_client`.

## General

### What is dart_swagger_to_api_client?

`dart_swagger_to_api_client` is a code generator that creates type-safe HTTP API clients from OpenAPI/Swagger specifications. It works with `dart_swagger_to_models` to generate a complete stack: models + API client.

### How does it differ from dart_swagger_to_models?

- `dart_swagger_to_models`: Generates Dart model classes from OpenAPI schemas
- `dart_swagger_to_api_client`: Generates HTTP client code that uses those models

They are separate packages that work together.

### What OpenAPI versions are supported?

- OpenAPI 3.0.0
- OpenAPI 3.1.0
- Swagger 2.0 (basic support)

## Generation

### Why are some endpoints missing from the generated client?

Endpoints without `operationId` are skipped. Add `operationId` to all operations in your OpenAPI spec:

```yaml
paths:
  /users:
    get:
      operationId: getUsers  # Required!
      responses:
        '200':
          description: OK
```

### How do I generate models and client together?

1. Generate models first:
```bash
dart run dart_swagger_to_models:dart_swagger_to_models \
  --input swagger/api.yaml \
  --output-dir lib/models
```

2. Then generate client:
```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client
```

The client generator will automatically detect and use the generated models.

### Can I use the client without generating models?

Yes! The client will use `Map<String, dynamic>` for request/response bodies when models are not available.

## Configuration

### How do I use different configurations for dev/staging/prod?

Use environment profiles in your config file:

```yaml
# dart_swagger_to_api_client.yaml
environments:
  dev:
    baseUrl: https://dev-api.example.com
  prod:
    baseUrl: https://api.example.com
```

Then use the `--env` flag:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --config dart_swagger_to_api_client.yaml \
  --env prod
```

### How do I use bearer token from environment variables?

```yaml
client:
  auth:
    bearerTokenEnv: API_BEARER_TOKEN
```

The token will be read from the `API_BEARER_TOKEN` environment variable at runtime.

## HTTP Adapters

### Which HTTP adapter should I use?

- **`http`** (default): Simple, lightweight, good for most cases
- **`dio`**: More features (interceptors, transformers), better for complex scenarios
- **Custom**: For special requirements

### How do I use Dio adapter?

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

### Can I use a custom HTTP client?

Yes! Implement `HttpClientAdapter`:

```dart
class MyCustomAdapter implements HttpClientAdapter {
  @override
  Future<HttpResponse> send(HttpRequest request) async {
    // Your implementation
  }
}
```

## Middleware

### How do I add logging?

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  requestInterceptors: [
    LoggingInterceptor.console(),
  ],
  responseInterceptors: [
    LoggingInterceptor.console(),
  ],
);
```

### How do I add retries?

```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  responseInterceptors: [
    RetryInterceptor(
      maxRetries: 3,
      retryableStatusCodes: {500, 502, 503, 504},
    ),
  ],
);
```

### Can I create custom middleware?

Yes! Implement `RequestInterceptor` or `ResponseInterceptor`:

```dart
class MyMiddleware implements RequestInterceptor {
  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    // Modify request
    return request;
  }
}
```

## Errors

### What exceptions can be thrown?

- `ApiClientException`: Base exception for all client errors
- `ApiServerException`: Server errors (5xx status codes)
- `ApiAuthException`: Authentication errors (401, 403)
- `TimeoutException`: Request timeout errors

### How do I handle errors?

```dart
try {
  final user = await client.defaultApi.getUser(userId: '123');
} on ApiAuthException catch (e) {
  // Handle auth errors
} on ApiServerException catch (e) {
  // Handle server errors
} on TimeoutException catch (e) {
  // Handle timeouts
}
```

## Models Integration

### How does model integration work?

1. Generate models with `dart_swagger_to_models`
2. The client generator scans for `dart_swagger_to_models.yaml`
3. If found, it uses `FileBasedModelsResolver` to resolve `$ref` to model types
4. Generated methods return model types instead of `Map<String, dynamic>`

### What if models are not found?

The client will use `Map<String, dynamic>` for request/response bodies. This is fine for simple use cases.

## Watch Mode

### How does watch mode work?

Watch mode monitors the spec and config files for changes and automatically regenerates the client:

```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --watch
```

### Can I use watch mode with remote URLs?

No, watch mode only works with local files. Use CI/CD for remote specs.

## CI/CD

### How do I set up automatic regeneration?

See `ci/README.md` for detailed instructions. Templates are available for:
- GitHub Actions
- GitLab CI

### Can I regenerate on schedule?

Yes! Use the scheduled workflow templates in `.github/workflows/`.

## State Management

### How do I use with Riverpod?

See `example/riverpod_integration_example.dart` for complete examples.

### How do I use with BLoC?

See `example/bloc_integration_example.dart` for complete examples.

## Troubleshooting

### Generated code has errors

1. Check that your OpenAPI spec is valid
2. Ensure all operations have `operationId`
3. Check for unsupported features (see warnings with `--verbose`)

### Models are not being used

1. Ensure `dart_swagger_to_models.yaml` exists
2. Check that models were generated in the expected directory
3. Verify the `outputDir` in models config matches actual location

### Watch mode not working

1. Ensure you're using a local file path, not a URL
2. Check file permissions
3. Try running without watch mode first

## Getting Help

- Check [Troubleshooting Guide](doc/en/TROUBLESHOOTING.md)
- See [Usage Guide](doc/en/USAGE.md)
- Open an issue on [GitHub](https://github.com/AlexGalitsky/dart_swagger_to_api_client/issues)
