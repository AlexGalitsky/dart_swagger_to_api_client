/// Example demonstrating error handling with dart_swagger_to_api_client.
///
/// This example shows:
/// - Handling different types of API errors
/// - Retry logic for transient failures
/// - Proper error messages and status codes
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
///    dart run example/error_handling_example.dart
///    ```

import 'dart:io';

import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

// Import the generated client
import 'generated/api_client.dart';

/// Retries a function with exponential backoff.
Future<T> retryWithBackoff<T>({
  required Future<T> Function() operation,
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int attempt = 0;
  Duration delay = initialDelay;

  while (attempt < maxRetries) {
    try {
      return await operation();
    } on ApiServerException catch (e) {
      // Retry on server errors (5xx)
      attempt++;
      if (attempt >= maxRetries) {
        rethrow;
      }
      print('Server error (attempt $attempt/$maxRetries): ${e.message}');
      print('Retrying in ${delay.inSeconds} seconds...');
      await Future.delayed(delay);
      delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
    } catch (e) {
      // Retry on timeout or other transient errors
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        print('Timeout (attempt $attempt/$maxRetries): $e');
        print('Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2);
      } else {
        rethrow;
      }
    }
    // Don't retry on client errors (4xx) or auth errors
  }
  throw StateError('Max retries exceeded');
}

Future<void> main() async {
  final config = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    timeout: const Duration(seconds: 10),
  );

  final client = ApiClient(config);

  try {
    // Example 1: Basic error handling
    print('=== Example 1: Basic Error Handling ===\n');
    try {
      final users = await client.defaultApi.getUsers();
      print('Success: $users');
    } on ApiAuthException catch (e) {
      print('❌ Authentication Error:');
      print('   Message: ${e.message}');
      print('   Status Code: ${e.statusCode}');
      print('   Action: Check your credentials');
    } on ApiServerException catch (e) {
      print('❌ Server Error:');
      print('   Message: ${e.message}');
      print('   Status Code: ${e.statusCode}');
      print('   Action: Retry later or contact support');
    } on ApiClientException catch (e) {
      print('❌ Client Error:');
      print('   Message: ${e.message}');
      print('   Status Code: ${e.statusCode}');
      print('   Action: Check your request parameters');
    } catch (e) {
      // Handle timeout and other errors
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        print('❌ Timeout Error:');
        print('   Message: $e');
        print('   Action: Check your network connection or increase timeout');
      } else {
        rethrow;
      }
    }

    print('\n');

    // Example 2: Retry logic for transient failures
    print('=== Example 2: Retry Logic ===\n');
    try {
      final users = await retryWithBackoff(
        operation: () => client.defaultApi.getUsers(),
        maxRetries: 3,
      );
      print('✅ Success after retries: $users');
    } on ApiServerException catch (e) {
      print('❌ Failed after retries: ${e.message}');
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        print('❌ Timeout after retries: $e');
      } else {
        rethrow;
      }
    }

    print('\n');

    // Example 3: Error handling with scoped client
    print('=== Example 3: Error Handling with Scoped Client ===\n');
    final scopedClient = client.withHeaders({
      'X-Request-ID': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    try {
      final users = await scopedClient.defaultApi.getUsers();
      print('✅ Success with scoped client: $users');
    } on ApiAuthException catch (e) {
      print('❌ Authentication failed: ${e.message}');
      print('   Request ID was included in headers for debugging');
    } catch (e) {
      print('❌ Error: $e');
    }

    print('\n');

    // Example 4: Handling specific status codes
    print('=== Example 4: Handling Specific Status Codes ===\n');
    try {
      final users = await client.defaultApi.getUsers();
      print('✅ Success: $users');
    } on ApiServerException catch (e) {
      // Handle server errors first (they are more specific)
      switch (e.statusCode) {
        case 500:
          print('❌ Internal Server Error (500): Server encountered an error');
          break;
        case 502:
          print('❌ Bad Gateway (502): Upstream server error');
          break;
        case 503:
          print('❌ Service Unavailable (503): Service temporarily unavailable');
          break;
        default:
          print('❌ Server Error (${e.statusCode}): ${e.message}');
      }
    } on ApiClientException catch (e) {
      // Handle client errors (4xx, except auth which is handled separately)
      switch (e.statusCode) {
        case 400:
          print('❌ Bad Request (400): Invalid request parameters');
          break;
        case 404:
          print('❌ Not Found (404): Resource does not exist');
          break;
        case 429:
          print('❌ Too Many Requests (429): Rate limit exceeded');
          print('   Action: Implement rate limiting or wait before retrying');
          break;
        default:
          print('❌ Client Error (${e.statusCode}): ${e.message}');
      }
      switch (e.statusCode) {
        case 500:
          print('❌ Internal Server Error (500): Server encountered an error');
          break;
        case 502:
          print('❌ Bad Gateway (502): Upstream server error');
          break;
        case 503:
          print('❌ Service Unavailable (503): Service temporarily unavailable');
          break;
        default:
          print('❌ Server Error (${e.statusCode}): ${e.message}');
      }
    }

  } catch (e, stackTrace) {
    // Catch-all for unexpected errors
    print('❌ Unexpected Error:');
    print('   Type: ${e.runtimeType}');
    print('   Message: $e');
    print('   Stack Trace: $stackTrace');
    exitCode = 1;
  } finally {
    await client.close();
    print('\n✅ Client closed. Resources freed.');
  }
}
