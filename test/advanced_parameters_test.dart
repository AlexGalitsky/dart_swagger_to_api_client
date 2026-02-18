import 'dart:convert';
import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Advanced parameters support', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dart_swagger_to_api_client_advanced_params_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('Array parameters', () {
      test('generates method with array query parameter (form, explode)', () async {
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
                'parameters': [
                  {
                    'name': 'ids',
                    'in': 'query',
                    'required': false,
                    'schema': {
                      'type': 'array',
                      'items': {'type': 'integer'},
                    },
                    'style': 'form',
                    'explode': true,
                  },
                ],
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

        // Check for array type (could be List<int> or List<num>)
        expect(content, anyOf(
          contains('List<int>? ids'),
          contains('List<num>? ids'),
        ));
        expect(content, contains('queryParametersAll'));
      });

      test('generates method with array query parameter (form, no explode)', () async {
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
                'parameters': [
                  {
                    'name': 'ids',
                    'in': 'query',
                    'required': false,
                    'schema': {
                      'type': 'array',
                      'items': {'type': 'integer'},
                    },
                    'style': 'form',
                    'explode': false,
                  },
                ],
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

        // Check for array type (could be List<int> or List<num>)
        expect(content, anyOf(
          contains('List<int>? ids'),
          contains('List<num>? ids'),
        ));
        expect(content, contains("join(',')"));
      });

      test('generates method with array query parameter (pipeDelimited)', () async {
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
                'parameters': [
                  {
                    'name': 'tags',
                    'in': 'query',
                    'required': false,
                    'schema': {
                      'type': 'array',
                      'items': {'type': 'string'},
                    },
                    'style': 'pipeDelimited',
                  },
                ],
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

        expect(content, contains('List<String>? tags'));
        expect(content, contains("join('|')"));
      });

      test('generates method with array query parameter (spaceDelimited)', () async {
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
                'parameters': [
                  {
                    'name': 'ids',
                    'in': 'query',
                    'required': false,
                    'schema': {
                      'type': 'array',
                      'items': {'type': 'integer'},
                    },
                    'style': 'spaceDelimited',
                  },
                ],
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

        // Check for array type (could be List<int> or List<num>)
        expect(content, anyOf(
          contains('List<int>? ids'),
          contains('List<num>? ids'),
        ));
        expect(content, contains("join(' ')"));
      });
    });

    group('Object parameters', () {
      test('generates method with object query parameter (form, explode)', () async {
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
                'parameters': [
                  {
                    'name': 'filter',
                    'in': 'query',
                    'required': false,
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'name': {'type': 'string'},
                        'age': {'type': 'integer'},
                      },
                    },
                    'style': 'form',
                    'explode': true,
                  },
                ],
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

        expect(content, contains('Map<String, dynamic>? filter'));
        expect(content, contains('forEach'));
      });

      test('generates method with object query parameter (deepObject)', () async {
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
                'parameters': [
                  {
                    'name': 'filter',
                    'in': 'query',
                    'required': false,
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'name': {'type': 'string'},
                        'age': {'type': 'integer'},
                      },
                    },
                    'style': 'deepObject',
                  },
                ],
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

        expect(content, contains('Map<String, dynamic>? filter'));
        expect(content, contains("'filter[\$key]'"));
      });
    });

    group('Path-level parameters', () {
      test('generates method with path-level parameters', () async {
        final specFile = File('${tempDir.path}/spec.json');
        final outputDir = Directory('${tempDir.path}/generated');

        final spec = {
          'openapi': '3.0.0',
          'info': {
            'title': 'Test API',
            'version': '1.0.0',
          },
          'paths': {
            '/users/{userId}/posts': {
              'parameters': [
                {
                  'name': 'userId',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'integer'},
                },
              ],
              'get': {
                'operationId': 'getUserPosts',
                'responses': {
                  '200': {
                    'description': 'Posts',
                    'content': {
                      'application/json': {
                        'schema': {
                          'type': 'array',
                          'items': {
                            'type': 'object',
                            'properties': {
                              'id': {'type': 'integer'},
                              'title': {'type': 'string'},
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

        expect(content, contains('getUserPosts'));
        // Check that userId parameter is present (could be int or num, camelCase is userid)
        expect(content, anyOf(
          contains('required int userid'),
          contains('required num userid'),
        ));
      });

      test('operation-level parameters override path-level parameters', () async {
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
              'parameters': [
                {
                  'name': 'id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'string'},
                },
              ],
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

        expect(content, contains('getUser'));
        // Operation-level parameter should override (integer, not string)
        // Check that id parameter is present (could be int or num, and camelCase)
        expect(content, anyOf(
          contains('required int id'),
          contains('required num id'),
        ));
      });
    });
  });
}
