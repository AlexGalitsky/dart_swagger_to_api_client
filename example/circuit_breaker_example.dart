/// Example demonstrating circuit breaker middleware usage.
///
/// Circuit breaker prevents cascading failures by temporarily blocking
/// requests to a service that is failing.

import 'package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart';

void main() {
  // Create circuit breaker with custom settings
  final circuitBreaker = CircuitBreakerInterceptor(
    failureThreshold: 5, // Open circuit after 5 failures
    timeout: Duration(seconds: 60), // Request timeout
    resetTimeout: Duration(seconds: 30), // Wait 30s before trying again
  );

  // Create API client config with circuit breaker
  final config = ApiClientConfig(
    baseUrl: Uri.parse('https://api.example.com'),
    responseInterceptors: [
      circuitBreaker, // Add circuit breaker to response interceptors
    ],
  );

  // Monitor circuit breaker state
  print('Circuit breaker state: ${circuitBreaker.state}');
  print('Failure count: ${circuitBreaker.failureCount}');

  // Use the client (assuming it's generated)
  // final client = ApiClient(config);
  // try {
  //   final users = await client.defaultApi.getUsers();
  //   print('Users: $users');
  // } catch (e) {
  //   if (e is ApiServerException && e.statusCode == 503) {
  //     print('Service unavailable (circuit breaker is open)');
  //   }
  // } finally {
  //   await client.close();
  // }

  print('Circuit breaker example configured successfully!');
}
