/// Example demonstrating authentication with dart_swagger_to_api_client.
///
/// This example shows different authentication methods:
/// - Bearer token authentication
/// - API key in header
/// - API key in query parameter
/// - Bearer token from environment variable
///
/// To run this example:
/// 1. Generate the API client first:
///    ```bash
///    dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
///      --input example/swagger/api.yaml \
///      --output-dir example/generated
///    ```
/// 2. Set environment variables (optional):
///    ```bash
///    export API_BEARER_TOKEN=your-token-here
///    export API_KEY=your-api-key-here
///    ```
/// 3. Then run this file:
///    ```bash
///    dart run example/auth_example.dart
///    ```

import 'dart:io';

import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

// Import the generated client
import 'generated/api_client.dart';

Future<void> main() async {
  print('=== Authentication Examples ===\n');

  // Example 1: Bearer token authentication
  print('1. Bearer Token Authentication');
  print('-' * 40);
  final bearerConfig = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    auth: AuthConfig(
      bearerToken: 'your-bearer-token-here',
    ),
  );
  final bearerClient = ApiClient(bearerConfig);
  try {
    // The generated client will automatically add:
    // Authorization: Bearer your-bearer-token-here
    print('Bearer token configured. Requests will include Authorization header.');
    // await bearerClient.defaultApi.getUsers();
  } finally {
    await bearerClient.close();
  }

  print('\n');

  // Example 2: API key in header
  print('2. API Key in Header');
  print('-' * 40);
  final apiKeyHeaderConfig = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    auth: AuthConfig(
      apiKeyHeader: 'X-API-Key',
      apiKey: Platform.environment['API_KEY'] ?? 'your-api-key-here',
    ),
  );
  final apiKeyHeaderClient = ApiClient(apiKeyHeaderConfig);
  try {
    // The generated client will automatically add:
    // X-API-Key: your-api-key-here
    print('API key in header configured. Requests will include X-API-Key header.');
    // await apiKeyHeaderClient.defaultApi.getUsers();
  } finally {
    await apiKeyHeaderClient.close();
  }

  print('\n');

  // Example 3: API key in query parameter
  print('3. API Key in Query Parameter');
  print('-' * 40);
  final apiKeyQueryConfig = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    auth: AuthConfig(
      apiKeyQuery: 'api_key',
      apiKey: Platform.environment['API_KEY'] ?? 'your-api-key-here',
    ),
  );
  final apiKeyQueryClient = ApiClient(apiKeyQueryConfig);
  try {
    // The generated client will automatically add:
    // ?api_key=your-api-key-here
    print('API key in query parameter configured. Requests will include api_key query param.');
    // await apiKeyQueryClient.defaultApi.getUsers();
  } finally {
    await apiKeyQueryClient.close();
  }

  print('\n');

  // Example 4: Bearer token from environment variable
  print('4. Bearer Token from Environment Variable');
  print('-' * 40);
  final envTokenConfig = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    auth: AuthConfig(
      bearerTokenEnv: 'API_BEARER_TOKEN',
    ),
  );
  final envTokenClient = ApiClient(envTokenConfig);
  try {
    // The generated client will read the token from environment variable
    // at runtime using resolveBearerToken()
    final token = envTokenConfig.auth?.resolveBearerToken();
    if (token != null) {
      print('Bearer token read from environment variable: ${token.substring(0, 10)}...');
    } else {
      print('Warning: API_BEARER_TOKEN environment variable not set.');
      print('Set it with: export API_BEARER_TOKEN=your-token-here');
    }
    // await envTokenClient.defaultApi.getUsers();
  } finally {
    await envTokenClient.close();
  }

  print('\n');

  // Example 5: Combined authentication (bearer token + API key)
  print('5. Combined Authentication (Bearer Token + API Key)');
  print('-' * 40);
  final combinedConfig = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    auth: AuthConfig(
      bearerToken: 'your-bearer-token',
      apiKeyHeader: 'X-API-Key',
      apiKey: 'your-api-key',
    ),
  );
  final combinedClient = ApiClient(combinedConfig);
  try {
    // The generated client will include both:
    // Authorization: Bearer your-bearer-token
    // X-API-Key: your-api-key
    print('Combined authentication configured.');
    print('Requests will include both Authorization header and X-API-Key header.');
    // await combinedClient.defaultApi.getUsers();
  } finally {
    await combinedClient.close();
  }

  print('\n=== Examples Complete ===');
  print('\nNote: These examples show configuration only.');
  print('Uncomment the API calls to make actual requests.');
}
