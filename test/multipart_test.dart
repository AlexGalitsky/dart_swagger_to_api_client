import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Multipart/form-data support', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('multipart_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates method with multipart/form-data requestBody', () async {
      final specFile = File('${tempDir.path}/api.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /upload:
    post:
      operationId: uploadFile
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                file:
                  type: string
                  format: binary
                name:
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
      expect(content, contains('uploadFile'));
      expect(content, contains('Map<String, dynamic> body'));
      // Should not set Content-Type header (adapter will set it with boundary)
      expect(content, isNot(contains("headers['Content-Type'] = 'multipart/form-data'")));
    });

    test('validator accepts multipart/form-data as supported content type', () async {
      final specFile = File('${tempDir.path}/api.yaml');
      await specFile.writeAsString('''
openapi: 3.0.0
info:
  title: Test API
  version: 1.0.0
paths:
  /upload:
    post:
      operationId: uploadFile
      requestBody:
        content:
          multipart/form-data:
            schema:
              type: object
      responses:
        '200':
          description: OK
''');

      var warnings = <String>[];
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: tempDir.path,
        onWarning: (msg) => warnings.add(msg),
      );

      // Should not warn about unsupported content type
      expect(
        warnings.any((w) => w.contains('multipart/form-data') && w.contains('unsupported')),
        isFalse,
      );
    });
  });
}
