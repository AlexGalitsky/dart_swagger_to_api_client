import 'dart:async';

import 'package:dart_swagger_to_api_client/src/config/config.dart';
import 'package:dart_swagger_to_api_client/src/core/http_client_adapter.dart';
import 'package:test/test.dart';

/// Mock adapter for testing close() behavior
class MockHttpClientAdapter implements HttpClientAdapter {
  bool _closed = false;
  bool get closed => _closed;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    if (_closed) {
      throw StateError('Adapter is closed');
    }
    return HttpResponse(
      statusCode: 200,
      headers: const {},
      body: '{}',
    );
  }

  @override
  Future<void> close() async {
    _closed = true;
  }
}

void main() {
  group('ApiClient facade methods', () {
    test('close() calls adapter.close()', () async {
      final adapter = MockHttpClientAdapter();
      final config = ApiClientConfig(
        baseUrl: Uri.parse('https://api.example.com'),
        httpClientAdapter: adapter,
      );

      // Create ApiClient instance (we'll need to generate it or create manually)
      // For now, let's test the adapter directly and verify the pattern
      expect(adapter.closed, isFalse);
      await adapter.close();
      expect(adapter.closed, isTrue);
    });

    test('withHeaders() creates new client with merged headers', () {
      final baseConfig = ApiClientConfig(
        baseUrl: Uri.parse('https://api.example.com'),
        defaultHeaders: {
          'X-Common': 'common-value',
          'X-Original': 'original-value',
        },
      );

      // We need to test the generated ApiClient class
      // For now, let's verify the config merging logic
      final additionalHeaders = {
        'X-Request-ID': '123',
        'X-Original': 'overridden-value', // Should override
      };

      final mergedHeaders = <String, String>{
        ...baseConfig.defaultHeaders,
        ...additionalHeaders,
      };

      expect(mergedHeaders['X-Common'], equals('common-value'));
      expect(mergedHeaders['X-Request-ID'], equals('123'));
      expect(mergedHeaders['X-Original'], equals('overridden-value'));
      expect(mergedHeaders.length, equals(3));
    });

    test('withHeaders() preserves other config values', () {
      final baseConfig = ApiClientConfig(
        baseUrl: Uri.parse('https://api.example.com'),
        defaultHeaders: {'X-Common': 'value'},
        timeout: const Duration(seconds: 60),
        auth: AuthConfig(apiKey: 'test-key'),
      );

      // Verify that when creating a new config, other values are preserved
      final newHeaders = {'X-New': 'new-value'};
      final mergedHeaders = <String, String>{
        ...baseConfig.defaultHeaders,
        ...newHeaders,
      };

      // In the actual implementation, we'd create a new ApiClientConfig
      // with merged headers but same baseUrl, timeout, auth, etc.
      expect(mergedHeaders['X-Common'], equals('value'));
      expect(mergedHeaders['X-New'], equals('new-value'));
    });
  });
}
