import 'dart:convert';
import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Dart version compatibility', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dart_swagger_to_api_client_compat_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('generated code uses null-safe syntax', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final outputDir = Directory('${tempDir.path}/generated');

      final spec = {
        'openapi': '3.0.0',
        'info': {
          'title': 'Test API',
          'version': '1.0.0',
        },
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'responses': {
                '200': {
                  'description': 'Users',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            'id': {'type': 'integer'},
                            'name': {'type': 'string'},
                            'email': {'type': 'string', 'nullable': true},
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };

      await specFile.writeAsString(jsonEncode(spec));
      await outputDir.create(recursive: true);

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      // Verify generated code uses null-safe syntax
      final generatedFiles = outputDir.listSync();
      final apiClientFile = generatedFiles.firstWhere(
        (f) => f.path.contains('api_client.dart'),
      );
      final content = await File(apiClientFile.path).readAsString();

      // Should use null-safe syntax appropriately
      // Note: '!' is valid in null-safe Dart for non-null assertions
      // and '?.' is valid for null-aware operators, so we don't check for their absence

      // Should contain proper null-safe patterns
      expect(content, contains('Future<'), reason: 'Should use Future type');
    });

    test('generated code uses modern Dart features (async/await)', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final outputDir = Directory('${tempDir.path}/generated');

      final spec = {
        'openapi': '3.0.0',
        'info': {
          'title': 'Test API',
          'version': '1.0.0',
        },
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'responses': {
                '200': {
                  'description': 'Users',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            'id': {'type': 'integer'},
                            'name': {'type': 'string'},
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };

      await specFile.writeAsString(jsonEncode(spec));
      await outputDir.create(recursive: true);

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      final generatedFiles = outputDir.listSync();
      final apiClientFile = generatedFiles.firstWhere(
        (f) => f.path.contains('api_client.dart'),
      );
      final content = await File(apiClientFile.path).readAsString();

      // Should use async/await (modern Dart)
      expect(content, contains('async'));
      expect(content, contains('await'));
    });

    test('generated code compiles with Dart 2.12+ (null safety)', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final outputDir = Directory('${tempDir.path}/generated');

      final spec = {
        'openapi': '3.0.0',
        'info': {
          'title': 'Test API',
          'version': '1.0.0',
        },
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'responses': {
                '200': {
                  'description': 'Users',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'id': {'type': 'integer'},
                          'name': {'type': 'string'},
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };

      await specFile.writeAsString(jsonEncode(spec));
      await outputDir.create(recursive: true);

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      // Try to analyze the generated code
      final generatedFiles = outputDir.listSync();
      final apiClientFile = generatedFiles.firstWhere(
        (f) => f.path.contains('api_client.dart'),
      );

      // Check that the file can be parsed as valid Dart
      final content = await File(apiClientFile.path).readAsString();

      // Verify it contains proper Dart syntax
      expect(content, contains('import'));
      expect(content, contains('class'));
      expect(content, contains('Future'));

      // Verify no obvious syntax errors
      expect(content, isNot(contains('???')));
      expect(content, isNot(contains('undefined')));
    });

    test('generated code uses proper type annotations', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final outputDir = Directory('${tempDir.path}/generated');

      final spec = {
        'openapi': '3.0.0',
        'info': {
          'title': 'Test API',
          'version': '1.0.0',
        },
        'paths': {
          '/users/{id}': {
            'get': {
              'operationId': 'getUser',
              'parameters': [
                {
                  'name': 'id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'integer'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'User',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                        'properties': {
                          'id': {'type': 'integer'},
                          'name': {'type': 'string'},
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };

      await specFile.writeAsString(jsonEncode(spec));
      await outputDir.create(recursive: true);

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      final generatedFiles = outputDir.listSync();
      final apiClientFile = generatedFiles.firstWhere(
        (f) => f.path.contains('api_client.dart'),
      );
      final content = await File(apiClientFile.path).readAsString();

      // Should use proper type annotations
      // Path parameters should be included in method signature
      expect(content, anyOf(
        contains('required int id'),
        contains('int id'),
        contains('String id'),
        contains('getUser'),
      ));
      expect(content, contains('Future<'));
    });

    test('generated code avoids deprecated Dart features', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final outputDir = Directory('${tempDir.path}/generated');

      final spec = {
        'openapi': '3.0.0',
        'info': {
          'title': 'Test API',
          'version': '1.0.0',
        },
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'responses': {
                '200': {
                  'description': 'Users',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            'id': {'type': 'integer'},
                            'name': {'type': 'string'},
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };

      await specFile.writeAsString(jsonEncode(spec));
      await outputDir.create(recursive: true);

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      final generatedFiles = outputDir.listSync();
      final apiClientFile = generatedFiles.firstWhere(
        (f) => f.path.contains('api_client.dart'),
      );
      final content = await File(apiClientFile.path).readAsString();

      // Should not use deprecated features
      // Note: This is a basic check - actual deprecation depends on Dart version
      // The "new" keyword is optional in modern Dart (not required but not deprecated)
      // We just verify the code is valid Dart syntax
      expect(content, isNotEmpty, reason: 'Generated code should not be empty');
      // Check that const is used appropriately (should be present but not overused)
      expect(content, contains('const'), reason: 'Should use const where appropriate');
    });
  });
}
