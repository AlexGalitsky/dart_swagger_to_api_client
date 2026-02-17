import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ApiClientGenerator integration', () {
    late Directory tempDir;
    late Directory specDir;
    late Directory outputDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('api_client_test_');
      specDir = Directory(p.join(tempDir.path, 'spec'));
      outputDir = Directory(p.join(tempDir.path, 'generated'));
      specDir.createSync(recursive: true);
      outputDir.createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates api_client.dart from simple OpenAPI spec', () async {
      // Write a minimal OpenAPI spec.
      final specFile = File(p.join(specDir.path, 'api.yaml'));
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
                type: array
                items:
                  type: object
''');

      // Generate client.
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        config: null,
        projectDir: tempDir.path,
      );

      // Verify output file exists.
      final outputFile = File(p.join(outputDir.path, 'api_client.dart'));
      expect(outputFile.existsSync(), isTrue);

      // Read and verify content.
      final content = await outputFile.readAsString();
      expect(content, contains('class ApiClient'));
      expect(content, contains('class DefaultApi'));
      expect(content, contains('Future<List<Map<String, dynamic>>> getUsers'));
      expect(content, contains('package:dart_swagger_to_api_client/dart_swagger_to_api_client.dart'));
      expect(content, contains('ApiClientConfig'));
      expect(content, contains('HttpRequest'));
      expect(content, contains('jsonDecode'));
    });

    test('generates api_client.dart with path and query parameters', () async {
      final specFile = File(p.join(specDir.path, 'api.yaml'));
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /users/{id}:
    get:
      operationId: getUser
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: page
          in: query
          schema:
            type: integer
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
        outputDir: outputDir.path,
        config: null,
        projectDir: tempDir.path,
      );

      final outputFile = File(p.join(outputDir.path, 'api_client.dart'));
      final content = await outputFile.readAsString();
      expect(content, contains('Future<Map<String, dynamic>> getUser({required String id, num? page})'));
      expect(content, contains("final _path = '/users/\${id}';"));
      expect(content, contains("queryParameters['page'] = page.toString();"));
    });

    test('generates Future<void> for 204 No Content responses', () async {
      final specFile = File(p.join(specDir.path, 'api.yaml'));
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /ping:
    get:
      operationId: ping
      responses:
        '204':
          description: No Content
''');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        config: null,
        projectDir: tempDir.path,
      );

      final outputFile = File(p.join(outputDir.path, 'api_client.dart'));
      final content = await outputFile.readAsString();
      expect(content, contains('Future<void> ping'));
      expect(content, contains('return;'));
      expect(content, isNot(contains('jsonDecode')));
    });

    test('creates output directory if it does not exist', () async {
      final nonExistentDir = Directory(p.join(tempDir.path, 'new_output'));
      expect(nonExistentDir.existsSync(), isFalse);

      final specFile = File(p.join(specDir.path, 'api.yaml'));
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
        outputDir: nonExistentDir.path,
        config: null,
        projectDir: tempDir.path,
      );

      expect(nonExistentDir.existsSync(), isTrue);
      final outputFile = File(p.join(nonExistentDir.path, 'api_client.dart'));
      expect(outputFile.existsSync(), isTrue);
    });

    test('throws StateError when spec has no paths section', () async {
      final specFile = File(p.join(specDir.path, 'api.yaml'));
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
''');

      expect(
        () => ApiClientGenerator.generateClient(
          inputSpecPath: specFile.path,
          outputDir: outputDir.path,
          config: null,
          projectDir: tempDir.path,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('validation failed'),
            contains('paths'),
          ),
        )),
      );
    });

    test('handles spec with no suitable endpoints gracefully', () async {
      final specFile = File(p.join(specDir.path, 'api.yaml'));
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /users:
    post:
      operationId: createUser
      responses:
        '201':
          description: Created
''');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        config: null,
        projectDir: tempDir.path,
      );

      final outputFile = File(p.join(outputDir.path, 'api_client.dart'));
      final content = await outputFile.readAsString();
      expect(content, contains('class ApiClient'));
      expect(content, contains('class DefaultApi'));
      expect(content, contains('No suitable GET endpoints'));
      expect(content, isNot(contains('createUser')));
    });

    test('generates POST method with requestBody', () async {
      final specFile = File(p.join(specDir.path, 'api.yaml'));
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /users:
    post:
      operationId: createUser
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema:
                type: object
''');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        config: null,
        projectDir: tempDir.path,
      );

      final outputFile = File(p.join(outputDir.path, 'api_client.dart'));
      final content = await outputFile.readAsString();
      expect(content, contains('Future<Map<String, dynamic>> createUser({'));
      expect(content, contains('required Map<String, dynamic> body'));
      expect(content, contains("/// Generated from POST /users"));
      expect(content, contains("method: 'POST'"));
      expect(content, contains('final bodyJson = jsonEncode(body);'));
      expect(content, contains('body: bodyJson,'));
    });
  });
}
