import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Pagination pattern detection', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pagination_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('detects pagination with page and limit parameters', () async {
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
      parameters:
        - name: page
          in: query
          required: false
          schema:
            type: integer
        - name: limit
          in: query
          required: false
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
      expect(content, contains('This endpoint supports pagination via query parameters.'));
    });

    test('detects pagination with offset and per_page parameters', () async {
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
      parameters:
        - name: offset
          in: query
          required: false
          schema:
            type: integer
        - name: per_page
          in: query
          required: false
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
      expect(content, contains('This endpoint supports pagination via query parameters.'));
    });

    test('detects pagination with page and page_size parameters', () async {
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
      parameters:
        - name: page
          in: query
          required: false
          schema:
            type: integer
        - name: page_size
          in: query
          required: false
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
      expect(content, contains('This endpoint supports pagination via query parameters.'));
    });

    test('does not detect pagination when only page parameter is present', () async {
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
      parameters:
        - name: page
          in: query
          required: false
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
      expect(content, isNot(contains('This endpoint supports pagination')));
    });

    test('does not detect pagination when only limit parameter is present', () async {
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
      parameters:
        - name: limit
          in: query
          required: false
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
      expect(content, isNot(contains('This endpoint supports pagination')));
    });
  });
}
