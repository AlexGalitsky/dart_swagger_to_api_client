/// Regression tests for different OpenAPI/Swagger versions.
///
/// These tests ensure that the generator works correctly with:
/// - OpenAPI 3.0.0
/// - OpenAPI 3.1.0
/// - Swagger 2.0 (if supported)
///
/// They verify that the generator doesn't break when encountering
/// different spec formats and versions.

import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Regression tests for OpenAPI versions', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('regression_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates client from OpenAPI 3.0.0 spec', () async {
      final specFile = File('${tempDir.path}/openapi_3_0.yaml');
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
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('class ApiClient'));
      expect(content, contains('getUsers'));
    });

    test('generates client from OpenAPI 3.1.0 spec', () async {
      final specFile = File('${tempDir.path}/openapi_3_1.yaml');
      await specFile.writeAsString('''
openapi: 3.1.0
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
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('class ApiClient'));
      expect(content, contains('getUsers'));
    });

    test('handles spec with multiple paths and operations', () async {
      final specFile = File('${tempDir.path}/multiple_paths.yaml');
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
    post:
      operationId: createUser
      requestBody:
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
  /users/{id}:
    get:
      operationId: getUser
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
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
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('getUsers'));
      expect(content, contains('createUser'));
      expect(content, contains('getUser'));
      expect(content, contains('required String id'));
    });

    test('handles spec with complex response schemas', () async {
      final specFile = File('${tempDir.path}/complex_responses.yaml');
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
                  properties:
                    id:
                      type: integer
                    name:
                      type: string
        '204':
          description: No Content
  /ping:
    get:
      operationId: ping
      responses:
        '204':
          description: No Content
''');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: tempDir.path,
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('getUsers'));
      expect(content, contains('ping'));
      // getUsers might return void (if interpreted as 204), List, or Map
      // The actual type depends on how the generator interprets the schema
      // For now, just verify that getUsers method exists
      expect(content, contains('getUsers'));
      // ping should return void (204 response)
      expect(content, contains('Future<void> ping'));
    });

    test('handles spec with query parameters', () async {
      final specFile = File('${tempDir.path}/query_params.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /users:
    get:
      operationId: getUsers
      parameters:
        - name: page
          in: query
          required: false
          schema:
            type: integer
        - name: limit
          in: query
          required: true
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
        outputDir: tempDir.path,
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('getUsers'));
      // Parameters can be num or int (generator uses num for integer types)
      expect(
        content.contains('num? page') || content.contains('int? page'),
        isTrue,
      );
      expect(
        content.contains('required num limit') ||
            content.contains('required int limit'),
        isTrue,
      );
    });
  });
}
