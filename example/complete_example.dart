/// Complete example demonstrating end-to-end usage of dart_swagger_to_api_client.
///
/// This example shows:
/// - Setting up configuration with authentication
/// - Using the generated API client
/// - Error handling
/// - Resource management (closing the client)
///
/// To run this example:
/// 1. Generate the API client first:
///    ```bash
///    dart run dart_swagger_to_api_client:dart_swagger_to_api_client \
///      --input example/swagger/api.yaml \
///      --output-dir example/generated
///    ```
/// 2. Then run this file:
///    ```bash
///    dart run example/complete_example.dart
///    ```

import 'dart:io';

import 'dart:async';

import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

// Import the generated client
// In a real project, this would be:
// import 'package:my_app/api_client/api_client.dart';
import 'generated/api_client.dart';

Future<void> main() async {
  // 1. Configure the API client with authentication
  final config = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    defaultHeaders: {
      'User-Agent': 'my-app/1.0.0',
      'Accept': 'application/json',
    },
    timeout: const Duration(seconds: 30),
    auth: AuthConfig(
      // Option 1: Direct bearer token
      bearerToken: Platform.environment['API_BEARER_TOKEN'],
      // Option 2: API key in header
      // apiKeyHeader: 'X-API-Key',
      // apiKey: Platform.environment['API_KEY'],
      // Option 3: API key in query parameter
      // apiKeyQuery: 'api_key',
      // apiKey: Platform.environment['API_KEY'],
    ),
  );

  // 2. Create the API client
  final client = ApiClient(config);

  try {
    // 3. Make API calls
    print('Fetching users...');
    final users = await client.defaultApi.getUsers();
    print('Users received: $users');

    // 4. Using scoped client with additional headers
    final scopedClient = client.withHeaders({
      'X-Request-ID': DateTime.now().millisecondsSinceEpoch.toString(),
      'X-Client-Version': '1.0.0',
    });
    print('\nUsing scoped client with request ID...');
    final usersWithId = await scopedClient.defaultApi.getUsers();
    print('Users received with scoped client: $usersWithId');

  } on ApiAuthException catch (e) {
    // Handle authentication errors (401, 403)
    print('Authentication failed: ${e.message}');
    print('Status code: ${e.statusCode}');
    print('Please check your API credentials.');
    exitCode = 1;
  } on ApiServerException catch (e) {
    // Handle server errors (5xx)
    print('Server error: ${e.message}');
    print('Status code: ${e.statusCode}');
    print('The server encountered an error. Please try again later.');
    exitCode = 1;
  } on ApiClientException catch (e) {
    // Handle client errors (4xx, except auth)
    print('Client error: ${e.message}');
    print('Status code: ${e.statusCode}');
    print('Please check your request parameters.');
    exitCode = 1;
  } catch (e, stackTrace) {
    // Handle timeout and other unexpected errors
    if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
      print('Request timed out: $e');
      print('The request took too long. Please check your network connection.');
    } else {
      print('Unexpected error: $e');
      print('Stack trace: $stackTrace');
    }
    exitCode = 1;
  } finally {
    // 5. Always close the client to free resources
    await client.close();
    print('\nClient closed. Resources freed.');
  }
}
