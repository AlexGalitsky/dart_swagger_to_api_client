# Troubleshooting Guide

Common issues and solutions when using `dart_swagger_to_api_client`.

## Generation Issues

### No endpoints generated

**Symptoms:** Generated `api_client.dart` has no methods in `DefaultApi` class.

**Possible causes:**
1. Missing `operationId` in operations
2. Unsupported HTTP methods
3. Spec validation errors

**Solutions:**
1. Add `operationId` to all operations:
```yaml
paths:
  /users:
    get:
      operationId: getUsers  # Required!
```

2. Check supported HTTP methods: GET, POST, PUT, DELETE, PATCH

3. Run with `--verbose` to see validation warnings:
```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --input swagger/api.yaml \
  --output-dir lib/api_client \
  --verbose
```

### Models not being used

**Symptoms:** Generated methods return `Map<String, dynamic>` instead of model types.

**Possible causes:**
1. Models not generated yet
2. `dart_swagger_to_models.yaml` not found
3. Incorrect `outputDir` in models config

**Solutions:**
1. Generate models first:
```bash
dart run dart_swagger_to_models:dart_swagger_to_models \
  --input swagger/api.yaml \
  --output-dir lib/models
```

2. Ensure `dart_swagger_to_models.yaml` exists in project root:
```yaml
outputDir: lib/models
```

3. Verify the `outputDir` in models config matches where models were generated

### Invalid OpenAPI spec

**Symptoms:** Generation fails with validation errors.

**Solutions:**
1. Validate your spec using online tools (e.g., Swagger Editor)
2. Check for required fields: `openapi`, `info`, `paths`
3. Ensure all `$ref` targets exist

## Runtime Issues

### Authentication errors

**Symptoms:** `ApiAuthException` thrown on requests.

**Solutions:**
1. Check `AuthConfig` is set correctly:
```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  auth: AuthConfig(
    bearerToken: 'your-token',
  ),
);
```

2. If using `bearerTokenEnv`, ensure environment variable is set:
```bash
export API_BEARER_TOKEN=your-token
```

3. Verify token is valid and not expired

### Timeout errors

**Symptoms:** `TimeoutException` thrown on requests.

**Solutions:**
1. Increase timeout:
```dart
final config = ApiClientConfig(
  baseUrl: Uri.parse('https://api.example.com'),
  timeout: Duration(seconds: 60),  // Increase from default 30s
);
```

2. Check network connectivity
3. Verify API server is responding

### Server errors

**Symptoms:** `ApiServerException` thrown with 5xx status codes.

**Solutions:**
1. Check API server status
2. Verify request format matches API expectations
3. Use retry middleware for transient errors:
```dart
responseInterceptors: [
  RetryInterceptor(
    maxRetries: 3,
    retryableStatusCodes: {500, 502, 503, 504},
  ),
],
```

## Configuration Issues

### Config file not found

**Symptoms:** Warnings about missing config file.

**Solutions:**
1. Create `dart_swagger_to_api_client.yaml` in project root
2. Or specify path explicitly:
```bash
dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
  --config path/to/config.yaml
```

### Environment profile not found

**Symptoms:** Warning about missing environment profile.

**Solutions:**
1. Check profile name matches config:
```yaml
environments:
  dev:  # Use 'dev', not 'development'
    baseUrl: https://dev-api.example.com
```

2. Verify profile is defined in config file

### Config values not applied

**Symptoms:** Generated code doesn't match config.

**Solutions:**
1. Remember priority: CLI arguments > Config > Defaults
2. CLI arguments override config values
3. Check config file syntax (YAML indentation matters)

## Watch Mode Issues

### Watch mode not triggering

**Symptoms:** Changes to spec file don't trigger regeneration.

**Solutions:**
1. Ensure you're using a local file path, not URL
2. Check file permissions
3. Verify file is being saved (some editors require explicit save)

### Multiple regenerations

**Symptoms:** Client regenerates multiple times for single change.

**Solutions:**
- This is normal due to debounce (500ms). Multiple file system events can trigger multiple regenerations.
- The debounce prevents excessive regenerations but may not catch all edge cases.

## Middleware Issues

### Middleware not executing

**Symptoms:** Middleware interceptors not being called.

**Solutions:**
1. Verify middleware is added to correct list:
```dart
requestInterceptors: [/* request middleware */],
responseInterceptors: [/* response middleware */],
```

2. Check middleware implements correct interface:
```dart
class MyMiddleware implements RequestInterceptor {
  @override
  Future<HttpRequest> onRequest(HttpRequest request) async {
    // Implementation
  }
}
```

### Retry not working

**Symptoms:** Requests not retrying on errors.

**Solutions:**
1. Ensure `RetryInterceptor` is in `responseInterceptors`:
```dart
responseInterceptors: [
  RetryInterceptor(maxRetries: 3),
],
```

2. Check error is in `retryableStatusCodes` or `retryableErrors`
3. Verify `maxRetries` is greater than 0

### Circuit breaker always open

**Symptoms:** Circuit breaker blocks all requests.

**Solutions:**
1. Check `failureThreshold` is not too low
2. Verify `resetTimeout` allows circuit to recover
3. Check circuit breaker state:
```dart
print('Circuit state: ${circuitBreaker.state}');
print('Failure count: ${circuitBreaker.failureCount}');
```

## CI/CD Issues

### Workflow not triggering

**Symptoms:** GitHub Actions workflow doesn't run.

**Solutions:**
1. Check workflow file is in `.github/workflows/`
2. Verify `paths` match your spec file location:
```yaml
on:
  push:
    paths:
      - 'swagger/**'  # Adjust to match your structure
```

3. Ensure workflow file has correct YAML syntax

### Permission errors

**Symptoms:** Workflow fails with permission errors.

**Solutions:**
1. Check repository settings → Actions → General
2. Enable "Read and write permissions" for workflows
3. Ensure `GITHUB_TOKEN` has necessary permissions

### Changes not committed

**Symptoms:** Workflow runs but doesn't commit changes.

**Solutions:**
1. Verify git user is configured:
```yaml
git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
```

2. Check workflow has write permissions
3. Verify files are actually being generated

## Getting More Help

1. Check [FAQ](doc/en/FAQ.md) for common questions
2. See [Usage Guide](doc/en/USAGE.md) for detailed documentation
3. Review [Developer Guide](doc/en/DEVELOPERS.md) for implementation details
4. Open an issue on [GitHub](https://github.com/AlexGalitsky/dart_swagger_to_api_client/issues) with:
   - OpenAPI spec (if possible)
   - Error messages
   - Steps to reproduce
   - Expected vs actual behavior
