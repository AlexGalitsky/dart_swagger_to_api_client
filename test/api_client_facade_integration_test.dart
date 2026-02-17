import 'dart:io';

import 'package:dart_swagger_to_api_client/src/config/config.dart';
import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:dart_swagger_to_api_client/src/core/http_client_adapter.dart';
import 'package:test/test.dart';

/// Mock adapter for testing
class TestHttpClientAdapter implements HttpClientAdapter {
  bool _closed = false;
  bool get closed => _closed;

  @override
  Future<HttpResponse> send(HttpRequest request) async {
    return HttpResponse(
      statusCode: 200,
      headers: const {},
      body: '{"test": "value"}',
    );
  }

  @override
  Future<void> close() async {
    _closed = true;
  }
}

void main() {
  group('ApiClient facade integration', () {
    late Directory tempDir;
    late TestHttpClientAdapter adapter;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('api_client_test_');
      adapter = TestHttpClientAdapter();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generated ApiClient has close() method', () async {
      final spec = {
        'openapi': '3.0.0',
        'info': {'title': 'Test API'},
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
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

      final specFile = File('${tempDir.path}/api.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
paths:
  /users:
    get:
      operationId: getUsers
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
          baseUrl: Uri.parse('https://api.example.com'),
          httpClientAdapter: adapter,
        ),
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('Future<void> close()'));
      expect(content, contains('await _config.httpClientAdapter.close()'));
    });

    test('generated ApiClient has withHeaders() method', () async {
      final specFile = File('${tempDir.path}/api.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
paths:
  /users:
    get:
      operationId: getUsers
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
          baseUrl: Uri.parse('https://api.example.com'),
          defaultHeaders: {'X-Common': 'value'},
        ),
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('ApiClient withHeaders'));
      expect(content, contains('Map<String, String> additionalHeaders'));
      expect(content, contains('mergedHeaders'));
      expect(content, contains('..._config.defaultHeaders'));
      expect(content, contains('...additionalHeaders'));
    });
  });
}
