/// Tests for edge cases and error scenarios.
///
/// These tests verify that the generator handles edge cases correctly:
/// - Empty specs
/// - Specs with no valid endpoints
/// - Invalid parameter types
/// - Missing required fields
/// - Malformed specs

import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Edge cases and error scenarios', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('edge_cases_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('handles spec with no paths gracefully', () async {
      final specFile = File('${tempDir.path}/no_paths.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths: {}
''');

      // Empty paths should generate a warning, but generation should succeed
      // with an empty client (no methods)
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: tempDir.path,
        onWarning: (msg) {
          // Warnings are expected for empty paths
        },
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('class ApiClient'));
      expect(content, contains('class DefaultApi'));
      // Should not have any API methods in DefaultApi (only facade methods in ApiClient)
      // Check that DefaultApi class doesn't have Future methods (except facade methods)
      final defaultApiStart = content.indexOf('class DefaultApi');
      final defaultApiEnd = content.lastIndexOf('}', content.lastIndexOf('}') - 1);
      final defaultApiContent = content.substring(
        defaultApiStart,
        defaultApiEnd > defaultApiStart ? defaultApiEnd : content.length,
      );
      // Should not have any Future methods in DefaultApi (only comment about no endpoints)
      expect(
        defaultApiContent.contains('No suitable') ||
            !defaultApiContent.contains('Future<'),
        isTrue,
      );
    });

    test('handles spec with paths but no valid operations', () async {
      final specFile = File('${tempDir.path}/no_operations.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /users:
    get:
      # Missing operationId
      responses:
        '200':
          description: OK
''');

      // Should generate empty client (no methods)
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: tempDir.path,
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      expect(content, contains('class ApiClient'));
      expect(content, contains('class DefaultApi'));
      // Should not have any methods (just a comment)
      expect(
        content.contains('No suitable') || !content.contains('Future<'),
        isTrue,
      );
    });

    test('handles spec with unsupported HTTP methods', () async {
      final specFile = File('${tempDir.path}/unsupported_methods.yaml');
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
    options:
      operationId: optionsUsers
      responses:
        '200':
          description: OK
    head:
      operationId: headUsers
      responses:
        '200':
          description: OK
''');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: tempDir.path,
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      // Should only generate GET method
      expect(content, contains('getUsers'));
      expect(content, isNot(contains('optionsUsers')));
      expect(content, isNot(contains('headUsers')));
    });

    test('handles spec with path parameters without type', () async {
      final specFile = File('${tempDir.path}/invalid_params.yaml');
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
          # Missing schema
      responses:
        '200':
          description: OK
          content:
            application/json:
              schema:
                type: object
''');

      // Should skip this endpoint (path param without type)
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: tempDir.path,
      );

      final generatedFile = File('${tempDir.path}/api_client.dart');
      expect(await generatedFile.exists(), isTrue);

      final content = await generatedFile.readAsString();
      // Should not generate getUser (invalid parameter)
      expect(content, isNot(contains('getUser')));
    });

    test('handles spec with very long operationId', () async {
      final specFile = File('${tempDir.path}/long_operation_id.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /users:
    get:
      operationId: getUsersWithVeryLongOperationIdThatShouldStillWork
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
      // Should generate method with sanitized name
      expect(content, contains('getUsersWithVeryLongOperationIdThatShouldStillWork'));
    });

    test('handles spec with special characters in path', () async {
      final specFile = File('${tempDir.path}/special_chars.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /users/{user-id}:
    get:
      operationId: getUser
      parameters:
        - name: user-id
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
      // Should handle special characters in parameter names
      expect(content, contains('getUser'));
      // Parameter name should be sanitized (either userId or user-id)
      expect(
        content.contains('userId') || content.contains('user-id'),
        isTrue,
      );
    });
  });
}
