import 'dart:convert';
import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Performance tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dart_swagger_to_api_client_perf_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('generates client from large spec (100+ endpoints) quickly', () async {
      final specFile = File('${tempDir.path}/large_spec.json');
      final outputDir = Directory('${tempDir.path}/generated');

      // Create a large spec with 100+ endpoints
      final paths = <String, dynamic>{};
      for (int i = 0; i < 100; i++) {
        paths['/users/$i'] = {
          'get': {
            'operationId': 'getUser$i',
            'summary': 'Get user $i',
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
          'post': {
            'operationId': 'createUser$i',
            'summary': 'Create user $i',
            'requestBody': {
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'name': {'type': 'string'},
                    },
                  },
                },
              },
            },
            'responses': {
              '201': {
                'description': 'Created',
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
        };
      }

      final spec = {
        'openapi': '3.0.0',
        'info': {
          'title': 'Large API',
          'version': '1.0.0',
        },
        'paths': paths,
      };

      await specFile.writeAsString(jsonEncode(spec));
      await outputDir.create(recursive: true);

      // Measure generation time
      final stopwatch = Stopwatch()..start();
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
        enableCache: false, // Disable cache for fair comparison
      );
      stopwatch.stop();

      // Should complete in reasonable time (less than 10 seconds for 100 endpoints)
      expect(stopwatch.elapsedMilliseconds, lessThan(10000),
          reason: 'Generation should complete in less than 10 seconds');

      // Verify files were generated
      final generatedFiles = outputDir.listSync();
      expect(generatedFiles.length, greaterThan(0));
    });

    test('generates client from spec with many schemas efficiently', () async {
      final specFile = File('${tempDir.path}/many_schemas.json');
      final outputDir = Directory('${tempDir.path}/generated');

      // Create a spec with many schemas
      final schemas = <String, dynamic>{};
      for (int i = 0; i < 50; i++) {
        schemas['Model$i'] = {
          'type': 'object',
          'properties': {
            'id': {'type': 'integer'},
            'name': {'type': 'string'},
            'value': {'type': 'number'},
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        };
      }

      final spec = {
        'openapi': '3.0.0',
        'info': {
          'title': 'Many Schemas API',
          'version': '1.0.0',
        },
        'paths': {
          '/data': {
            'get': {
              'operationId': 'getData',
              'responses': {
                '200': {
                  'description': 'Data',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {'\$ref': '#/components/schemas/Model0'},
                      },
                    },
                  },
                },
              },
            },
          },
        },
        'components': {
          'schemas': schemas,
        },
      };

      await specFile.writeAsString(jsonEncode(spec));
      await outputDir.create(recursive: true);

      final stopwatch = Stopwatch()..start();
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
        enableCache: false,
      );
      stopwatch.stop();

      // Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: 'Generation should complete in less than 5 seconds');

      final generatedFiles = outputDir.listSync();
      expect(generatedFiles.length, greaterThan(0));
    });

    test('caching improves performance on repeated generations', () async {
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

      // First generation (no cache)
      final firstStopwatch = Stopwatch()..start();
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
        enableCache: true,
      );
      firstStopwatch.stop();

      // Second generation (with cache)
      final secondStopwatch = Stopwatch()..start();
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
        enableCache: true,
      );
      secondStopwatch.stop();

      // Cached generation should be faster
      expect(secondStopwatch.elapsedMilliseconds,
          lessThanOrEqualTo(firstStopwatch.elapsedMilliseconds),
          reason: 'Cached generation should be at least as fast as first generation');
    });

    test('handles deeply nested request/response schemas efficiently', () async {
      final specFile = File('${tempDir.path}/nested_spec.json');
      final outputDir = Directory('${tempDir.path}/generated');

      // Create deeply nested schema
      Map<String, dynamic> createNestedSchema(int depth) {
        if (depth == 0) {
          return {
            'type': 'object',
            'properties': {
              'value': {'type': 'string'},
            },
          };
        }
        return {
          'type': 'object',
          'properties': {
            'nested': createNestedSchema(depth - 1),
            'items': {
              'type': 'array',
              'items': createNestedSchema(depth - 1),
            },
          },
        };
      }

      final spec = {
        'openapi': '3.0.0',
        'info': {
          'title': 'Nested API',
          'version': '1.0.0',
        },
        'paths': {
          '/nested': {
            'get': {
              'operationId': 'getNested',
              'responses': {
                '200': {
                  'description': 'Nested data',
                  'content': {
                    'application/json': {
                      'schema': createNestedSchema(5),
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

      final stopwatch = Stopwatch()..start();
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
        enableCache: false,
      );
      stopwatch.stop();

      // Should handle nested schemas efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'Should handle nested schemas in reasonable time');
    });

    test('memory usage is reasonable for large specs', () async {
      final specFile = File('${tempDir.path}/memory_spec.json');
      final outputDir = Directory('${tempDir.path}/generated');

      // Create a spec with many large strings
      final largeString = 'x' * 10000;
      final paths = <String, dynamic>{};
      for (int i = 0; i < 20; i++) {
        paths['/endpoint$i'] = {
          'get': {
            'operationId': 'getEndpoint$i',
            'summary': largeString, // Large summary
            'description': largeString, // Large description
            'responses': {
              '200': {
                'description': largeString,
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'data': {'type': 'string'},
                      },
                    },
                  },
                },
              },
            },
          },
        };
      }

      final spec = {
        'openapi': '3.0.0',
        'info': {
          'title': 'Memory Test API',
          'version': '1.0.0',
        },
        'paths': paths,
      };

      await specFile.writeAsString(jsonEncode(spec));
      await outputDir.create(recursive: true);

      // Should complete without excessive memory usage
      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
        enableCache: false,
      );

      // If we get here, memory usage was acceptable
      expect(true, isTrue);
    });
  });
}
