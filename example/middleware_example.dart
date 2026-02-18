/// Example demonstrating middleware usage with API client.
///
/// This example shows how to use logging, retry, and rate limiting middleware
/// with the generated API client.

import 'dart:async';

import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

Future<void> main() async {
  // Example 1: Logging middleware
  final loggingInterceptor = LoggingInterceptor.console(
    logHeaders: true,
    logBody: false,
  );

  // Example 2: Retry middleware
  final retryInterceptor = RetryInterceptor(
    maxRetries: 3,
    retryableStatusCodes: {500, 502, 503, 504},
    retryableErrors: {TimeoutException},
    baseDelayMs: 1000,
    maxDelayMs: 10000,
  );

  // Example 3: Rate limiting middleware
  final rateLimitInterceptor = RateLimitInterceptor(
    maxRequests: 100,
    window: Duration(minutes: 1),
  );

  // Create API client config with middleware
  final config = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    auth: AuthConfig(
      bearerToken: 'your-token-here',
    ),
    requestInterceptors: [
      rateLimitInterceptor, // Apply rate limiting first
      loggingInterceptor, // Then logging
    ],
    responseInterceptors: [
      retryInterceptor, // Apply retry logic
      loggingInterceptor, // Then logging
    ],
  );

  // Use the client (assuming it's generated)
  // final client = ApiClient(config);
  // try {
  //   final users = await client.defaultApi.getUsers();
  //   print('Users: $users');
  // } finally {
  //   await client.close();
  // }

  print('Middleware example configured successfully!');
  print('Request interceptors: ${config.requestInterceptors.length}');
  print('Response interceptors: ${config.responseInterceptors.length}');
}
