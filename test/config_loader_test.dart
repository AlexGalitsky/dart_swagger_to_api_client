import 'dart:io';

import 'package:dart_swagger_to_api_client/src/config/config_loader.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigLoader', () {
    test('loads basic fields from YAML', () async {
      final yaml = '''
input: swagger/api.yaml
outputDir: lib/api_client

client:
  baseUrl: https://api.example.com
  headers:
    User-Agent: my-app/1.0.0
  auth:
    apiKeyHeader: X-API-Key
    apiKeyQuery: api_key
    apiKey: secret
    bearerToken: token

      http:
        adapter: custom
        customAdapterType: MyCustomHttpClientAdapter
''';

      final file = File('test/tmp_config.yaml');
      await file.writeAsString(yaml);

      addTearDown(() async {
        if (await file.exists()) {
          await file.delete();
        }
      });

      final config = await ConfigLoader.load(file.path);

      expect(config, isNotNull);
      expect(config!.input, 'swagger/api.yaml');
      expect(config.outputDir, 'lib/api_client');
      expect(config.baseUrl.toString(), 'https://api.example.com');
      expect(config.headers['User-Agent'], 'my-app/1.0.0');
      expect(config.auth, isNotNull);
      expect(config.auth!.apiKeyHeader, 'X-API-Key');
      expect(config.auth!.apiKeyQuery, 'api_key');
      expect(config.auth!.apiKey, 'secret');
      expect(config.auth!.bearerToken, 'token');
      expect(config.httpAdapter, 'http');
      expect(config.customAdapterType, 'MyCustomHttpClientAdapter');
    });
  });
}

