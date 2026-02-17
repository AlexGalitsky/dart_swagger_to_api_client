import 'package:dart_swagger_to_api_client/src/generators/endpoint_method_generator.dart';
import 'package:test/test.dart';

void main() {
  group('EndpointMethodGenerator', () {
    final generator = EndpointMethodGenerator();

    test('generates simple GET without params', () {
      final spec = <String, dynamic>{
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
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

      final code = generator.generateDefaultApiMethods(spec);

      expect(
        code,
        contains('Future<List<Map<String, dynamic>>> getUsers({}) async'),
      );
      expect(code, contains("const _rawPath = '/users';"));
      expect(code, contains("final _path = '/users';"));
    });

    test('generates GET with path and query params', () {
      final spec = <String, dynamic>{
        'paths': {
          '/users/{id}': {
            'get': {
              'operationId': 'getUser',
              'parameters': [
                {
                  'name': 'id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'string'},
                },
                {
                  'name': 'page',
                  'in': 'query',
                  'schema': {'type': 'integer'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };

      final code = generator.generateDefaultApiMethods(spec);

      expect(code, contains('Future<Map<String, dynamic>> getUser({'));
      expect(code, contains('required String id'));
      expect(code, contains('num? page'));
      expect(code, contains("const _rawPath = '/users/{id}';"));
      expect(code, contains("final _path = '/users/\${id}';"));
      expect(code, contains("queryParameters['page'] = page.toString();"));
    });

    test('generates Future<void> for 204 responses', () {
      final spec = <String, dynamic>{
        'paths': {
          '/ping': {
            'get': {
              'operationId': 'ping',
              'responses': {
                '204': {
                  'description': 'No Content',
                },
              },
            },
          },
        },
      };

      final code = generator.generateDefaultApiMethods(spec);

      expect(code, contains('Future<void> ping({}) async'));
      expect(code, isNot(contains('jsonDecode(')));
      expect(code, contains('return;'));
    });

    test('generates POST method with requestBody', () {
      final spec = <String, dynamic>{
        'paths': {
          '/users': {
            'post': {
              'operationId': 'createUser',
              'requestBody': {
                'required': true,
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
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
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };

      final code = generator.generateDefaultApiMethods(spec);

      expect(code, contains('Future<Map<String, dynamic>> createUser({'));
      expect(code, contains('required Map<String, dynamic> body'));
      expect(code, contains("/// Generated from POST /users"));
      expect(code, contains("method: 'POST'"));
      expect(code, contains('final bodyJson = jsonEncode(body);'));
      expect(code, contains('body: bodyJson,'));
    });

    test('generates PUT method with requestBody and path params', () {
      final spec = <String, dynamic>{
        'paths': {
          '/users/{id}': {
            'put': {
              'operationId': 'updateUser',
              'parameters': [
                {
                  'name': 'id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'string'},
                },
              ],
              'requestBody': {
                'required': true,
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                    },
                  },
                },
              },
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'object',
                      },
                    },
                  },
                },
              },
            },
          },
        },
      };

      final code = generator.generateDefaultApiMethods(spec);

      expect(code, contains('Future<Map<String, dynamic>> updateUser({'));
      expect(code, contains('required String id'));
      expect(code, contains('required Map<String, dynamic> body'));
      expect(code, contains("/// Generated from PUT /users/{id}"));
      expect(code, contains("method: 'PUT'"));
      expect(code, contains('final bodyJson = jsonEncode(body);'));
    });

    test('generates DELETE method without requestBody', () {
      final spec = <String, dynamic>{
        'paths': {
          '/users/{id}': {
            'delete': {
              'operationId': 'deleteUser',
              'parameters': [
                {
                  'name': 'id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '204': {
                  'description': 'No Content',
                },
              },
            },
          },
        },
      };

      final code = generator.generateDefaultApiMethods(spec);

      expect(code, contains('Future<void> deleteUser({'));
      expect(code, contains('required String id'));
      expect(code, isNot(contains('required Map<String, dynamic> body')));
      expect(code, contains("/// Generated from DELETE /users/{id}"));
      expect(code, contains("method: 'DELETE'"));
      expect(code, isNot(contains('jsonEncode(body)')));
    });
  });
}

