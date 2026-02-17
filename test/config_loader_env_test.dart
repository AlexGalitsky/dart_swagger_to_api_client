import 'dart:io';

import 'package:dart_swagger_to_api_client/src/config/config_loader.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigLoader environment profiles', () {
    test('loads environment profiles from YAML', () async {
      final yamlContent = '''
input: api.yaml
outputDir: lib/api_client

client:
  baseUrl: https://api.example.com
  headers:
    X-Default: default-value

environments:
  dev:
    baseUrl: https://dev-api.example.com
    headers:
      X-Environment: dev
  staging:
    baseUrl: https://staging-api.example.com
    headers:
      X-Environment: staging
  prod:
    baseUrl: https://api.example.com
    headers:
      X-Environment: prod
    auth:
      bearerTokenEnv: PROD_TOKEN
''';

      final tempFile = File('${Directory.systemTemp.path}/test_config_${DateTime.now().millisecondsSinceEpoch}.yaml');
      await tempFile.writeAsString(yamlContent);

      try {
        final config = await ConfigLoader.load(tempFile.path);
        expect(config, isNotNull);
        expect(config!.environments, hasLength(3));
        expect(config.environments.containsKey('dev'), isTrue);
        expect(config.environments.containsKey('staging'), isTrue);
        expect(config.environments.containsKey('prod'), isTrue);

        final devProfile = config.environments['dev']!;
        expect(devProfile.baseUrl?.toString(), equals('https://dev-api.example.com'));
        expect(devProfile.headers['X-Environment'], equals('dev'));

        final prodProfile = config.environments['prod']!;
        expect(prodProfile.baseUrl?.toString(), equals('https://api.example.com'));
        expect(prodProfile.auth?.bearerTokenEnv, equals('PROD_TOKEN'));
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('environment profile can override base config', () async {
      final yamlContent = '''
client:
  baseUrl: https://api.example.com
  headers:
    X-Default: default-value
  auth:
    apiKeyHeader: X-API-Key
    apiKey: default-key

environments:
  dev:
    baseUrl: https://dev-api.example.com
    headers:
      X-Environment: dev
    auth:
      apiKey: dev-key
''';

      final tempFile = File('${Directory.systemTemp.path}/test_config_${DateTime.now().millisecondsSinceEpoch}.yaml');
      await tempFile.writeAsString(yamlContent);

      try {
        final config = await ConfigLoader.load(tempFile.path);
        expect(config, isNotNull);

        final devProfile = config!.environments['dev']!;
        expect(devProfile.baseUrl?.toString(), equals('https://dev-api.example.com'));
        expect(devProfile.headers['X-Environment'], equals('dev'));
        expect(devProfile.auth?.apiKey, equals('dev-key'));
        // Note: profiles don't inherit auth from base config, they override it completely
        expect(devProfile.auth?.apiKeyHeader, isNull);
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('handles missing environments section gracefully', () async {
      final yamlContent = '''
input: api.yaml
outputDir: lib/api_client
''';

      final tempFile = File('${Directory.systemTemp.path}/test_config_${DateTime.now().millisecondsSinceEpoch}.yaml');
      await tempFile.writeAsString(yamlContent);

      try {
        final config = await ConfigLoader.load(tempFile.path);
        expect(config, isNotNull);
        expect(config!.environments, isEmpty);
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });
  });
}
