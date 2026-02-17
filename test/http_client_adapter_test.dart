import 'dart:async';

import 'package:dart_swagger_to_api_client/src/core/http_client_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('HttpHttpClientAdapter', () {
    test('passes timeout from HttpRequest to the underlying HTTP call', () async {
      final adapter = HttpHttpClientAdapter();
      
      // Create a request with a very short timeout
      final request = HttpRequest(
        method: 'GET',
        url: Uri.parse('https://httpbin.org/delay/10'), // This will take 10 seconds
        timeout: const Duration(milliseconds: 100), // But we timeout after 100ms
      );

      // Should throw TimeoutException
      expect(
        () => adapter.send(request),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('works without timeout when timeout is null', () async {
      final adapter = HttpHttpClientAdapter();
      
      // Create a request without timeout
      final request = HttpRequest(
        method: 'GET',
        url: Uri.parse('https://httpbin.org/get'),
        timeout: null,
      );

      // Should complete successfully (assuming network is available)
      final response = await adapter.send(request);
      expect(response.statusCode, equals(200));
    });

    test('includes timeout in request when specified', () {
      final request = HttpRequest(
        method: 'POST',
        url: Uri.parse('https://example.com/api'),
        timeout: const Duration(seconds: 5),
      );

      expect(request.timeout, equals(const Duration(seconds: 5)));
    });
  });
}
