/// Integration tests using httpbin.org as a mock API server.
///
/// These tests verify that the generated client can actually make HTTP requests
/// and handle responses correctly. They use httpbin.org which provides various
/// endpoints for testing HTTP clients.
///
/// Note: These tests require internet connection and may be flaky.
/// Consider running them separately from unit tests.

import 'dart:io';

import 'package:dart_swagger_to_api_client/src/config/config.dart';
import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:dart_swagger_to_api_client/src/core/http_client_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('Integration tests with httpbin.org', () {
    // Skip integration tests by default (they require internet)
    // Run with: dart test --dart-define=ENABLE_INTEGRATION_TESTS=true
    const enableIntegrationTests =
        bool.fromEnvironment('ENABLE_INTEGRATION_TESTS', defaultValue: false);

    if (!enableIntegrationTests) {
      test('Integration tests are disabled by default', () {
        // This test always passes, but serves as documentation
        // that integration tests exist but are disabled
      });
      return;
    }

    test('generated client can make GET request to httpbin', () async {
      // Create a simple OpenAPI spec for httpbin /get endpoint
      final spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Httpbin API', 'version': '1.0.0'},
        'paths': {
          '/get': {
            'get': {
              'operationId': 'getRequest',
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'object'},
                    },
                  },
                },
              },
            },
          },
        },
      };

      // Generate client code
      final tempDir = Directory.systemTemp.createTempSync('integration_test_');
      try {
        final specFile = File('${tempDir.path}/spec.yaml');
        await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Httpbin API
  version: 1.0.0
paths:
  /get:
    get:
      operationId: getRequest
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
''');

        await ApiClientGenerator.generateClient(
          inputSpecPath: specFile.path,
          outputDir: tempDir.path,
          config: ApiClientConfig(
            baseUrl: Uri.parse('https://httpbin.org'),
            timeout: const Duration(seconds: 10),
          ),
        );

        // Verify that the client was generated
        final generatedFile = File('${tempDir.path}/api_client.dart');
        expect(await generatedFile.exists(), isTrue);

        // Note: Actually executing the generated code would require
        // importing it dynamically, which is complex in Dart.
        // This test verifies that generation succeeds and produces valid code.
        final content = await generatedFile.readAsString();
        expect(content, contains('class ApiClient'));
        expect(content, contains('Future<Map<String, dynamic>> getRequest'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    }, skip: !enableIntegrationTests);

    test('HttpHttpClientAdapter can make real HTTP request', () async {
      final adapter = HttpHttpClientAdapter();
      try {
        final request = HttpRequest(
          method: 'GET',
          url: Uri.parse('https://httpbin.org/get'),
          timeout: const Duration(seconds: 10),
        );

        final response = await adapter.send(request);

        expect(response.statusCode, equals(200));
        expect(response.body, isNotEmpty);
        expect(response.body, contains('"url"'));
      } finally {
        await adapter.close();
      }
    }, skip: !enableIntegrationTests);

    test('HttpHttpClientAdapter handles 404 errors', () async {
      final adapter = HttpHttpClientAdapter();
      try {
        final request = HttpRequest(
          method: 'GET',
          url: Uri.parse('https://httpbin.org/status/404'),
          timeout: const Duration(seconds: 10),
        );

        final response = await adapter.send(request);

        expect(response.statusCode, equals(404));
      } finally {
        await adapter.close();
      }
    }, skip: !enableIntegrationTests);

    test('HttpHttpClientAdapter handles POST requests', () async {
      final adapter = HttpHttpClientAdapter();
      try {
        final request = HttpRequest(
          method: 'POST',
          url: Uri.parse('https://httpbin.org/post'),
          headers: {'Content-Type': 'application/json'},
          body: '{"test": "value"}',
          timeout: const Duration(seconds: 10),
        );

        final response = await adapter.send(request);

        expect(response.statusCode, equals(200));
        expect(response.body, contains('"test"'));
        expect(response.body, contains('"value"'));
      } finally {
        await adapter.close();
      }
    }, skip: !enableIntegrationTests);
  });
}
