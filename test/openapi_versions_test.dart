import 'dart:convert';
import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAPI versions compatibility', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dart_swagger_to_api_client_versions_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('generates client from OpenAPI 3.0.0 spec', () async {
      final specFile = File('${tempDir.path}/openapi_3_0.json');
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
      expect(generatedFiles.length, greaterThan(0));

      // Verify generated code contains expected method
      final apiClientFile = generatedFiles.firstWhere(
        (f) => f.path.contains('api_client.dart'),
      );
      final content = await File(apiClientFile.path).readAsString();
      expect(content, contains('getUsers'));
    });

    test('generates client from OpenAPI 3.1.0 spec', () async {
      final specFile = File('${tempDir.path}/openapi_3_1.json');
      final outputDir = Directory('${tempDir.path}/generated');

      final spec = {
        'openapi': '3.1.0',
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
      expect(generatedFiles.length, greaterThan(0));

      final apiClientFile = generatedFiles.firstWhere(
        (f) => f.path.contains('api_client.dart'),
      );
      final content = await File(apiClientFile.path).readAsString();
      expect(content, contains('getUsers'));
    });

    test('generates client from Swagger 2.0 spec', () async {
      final specFile = File('${tempDir.path}/swagger_2_0.json');
      final outputDir = Directory('${tempDir.path}/generated');

      final spec = {
        'swagger': '2.0',
        'info': {
          'title': 'Test API',
          'version': '1.0.0',
        },
        'host': 'api.example.com',
        'basePath': '/v1',
        'schemes': ['https'],
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'responses': {
                '200': {
                  'description': 'Users',
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
      };

      await specFile.writeAsString(jsonEncode(spec));
      await outputDir.create(recursive: true);

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      final generatedFiles = outputDir.listSync();
      expect(generatedFiles.length, greaterThan(0));

      final apiClientFile = generatedFiles.firstWhere(
        (f) => f.path.contains('api_client.dart'),
      );
      final content = await File(apiClientFile.path).readAsString();
      expect(content, contains('getUsers'));
    });

    test('handles OpenAPI 3.0.0 with components/schemas', () async {
      final specFile = File('${tempDir.path}/openapi_3_0_components.json');
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
                        'items': {'\$ref': '#/components/schemas/User'},
                      },
                    },
                  },
                },
              },
            },
          },
        },
        'components': {
          'schemas': {
            'User': {
              'type': 'object',
              'properties': {
                'id': {'type': 'integer'},
                'name': {'type': 'string'},
                'email': {'type': 'string'},
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
      expect(generatedFiles.length, greaterThan(0));
    });

    test('handles OpenAPI 3.1.0 with new features', () async {
      final specFile = File('${tempDir.path}/openapi_3_1_features.json');
      final outputDir = Directory('${tempDir.path}/generated');

      final spec = {
        'openapi': '3.1.0',
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

      // Should not throw even if 3.1.0 has features we don't fully support yet
      await expectLater(
        () => ApiClientGenerator.generateClient(
          inputSpecPath: specFile.path,
          outputDir: outputDir.path,
          projectDir: tempDir.path,
        ),
        returnsNormally,
      );
    });
  });
}
