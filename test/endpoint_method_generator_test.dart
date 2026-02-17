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
  });
}

