import 'dart:io';

import 'package:dart_swagger_to_api_client/src/config/config_loader.dart';
import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Custom adapter support', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('custom_adapter_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates client with custom adapter documentation', () async {
      final specFile = File('${tempDir.path}/api.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
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
        customAdapterType: 'MyCustomHttpClientAdapter',
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('MyCustomHttpClientAdapter'));
      expect(content, contains('Custom HTTP adapter support'));
      expect(content, contains('implements HttpClientAdapter'));
      expect(content, contains('httpClientAdapter: customAdapter'));
    });

    test('generates client without custom adapter documentation when not specified', () async {
      final specFile = File('${tempDir.path}/api.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
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
        customAdapterType: null,
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, isNot(contains('Custom HTTP adapter support')));
      expect(content, isNot(contains('MyCustomHttpClientAdapter')));
    });

    test('loads custom adapter type from config file', () async {
      final configFile = File('${tempDir.path}/dart_swagger_to_api_client.yaml');
      await configFile.writeAsString('''
input: api.yaml
outputDir: generated

http:
  adapter: custom
  customAdapterType: MyCustomAdapter
''');

      final config = await ConfigLoader.load(configFile.path);
      expect(config, isNotNull);
      expect(config!.httpAdapter, equals('custom'));
      expect(config.customAdapterType, equals('MyCustomAdapter'));
    });

    test('generates client with custom adapter from config file', () async {
      final specFile = File('${tempDir.path}/api.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
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

      final configFile = File('${tempDir.path}/dart_swagger_to_api_client.yaml');
      await configFile.writeAsString('''
input: api.yaml
outputDir: generated

http:
  adapter: custom
  customAdapterType: MyCustomHttpClientAdapter
''');

      final fileConfig = await ConfigLoader.load(configFile.path);
      expect(fileConfig, isNotNull);
      expect(fileConfig!.httpAdapter, equals('custom'));
      expect(fileConfig.customAdapterType, equals('MyCustomHttpClientAdapter'));

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: tempDir.path,
        customAdapterType: fileConfig.customAdapterType,
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('MyCustomHttpClientAdapter'));
      expect(content, contains('Custom HTTP adapter support'));
    });

    test('handles empty customAdapterType gracefully', () async {
      final specFile = File('${tempDir.path}/api.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
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
        customAdapterType: '',
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      // Should not include custom adapter documentation for empty string
      expect(content, isNot(contains('Custom HTTP adapter support')));
    });
  });
}
