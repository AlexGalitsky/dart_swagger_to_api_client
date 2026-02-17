import 'package:dart_swagger_to_api_client/src/generators/endpoint_method_generator.dart';
import 'package:test/test.dart';

void main() {
  group('EndpointMethodGenerator', () {
    final generator = EndpointMethodGenerator();

    test('generates simple GET without params', () async {
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

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(
        code,
        contains('Future<List<Map<String, dynamic>>> getUsers({}) async'),
      );
      expect(code, contains("const _rawPath = '/users';"));
      expect(code, contains("final _path = '/users';"));
    });

    test('generates GET with path and query params', () async {
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

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(code, contains('Future<Map<String, dynamic>> getUser({'));
      expect(code, contains('required String id'));
      expect(code, contains('num? page'));
      expect(code, contains("const _rawPath = '/users/{id}';"));
      expect(code, contains("final _path = '/users/\${id}';"));
      expect(code, contains("queryParameters['page'] = page.toString();"));
    });

    test('generates Future<void> for 204 responses', () async {
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

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(code, contains('Future<void> ping({}) async'));
      expect(code, isNot(contains('jsonDecode(')));
      expect(code, contains('return;'));
    });

    test('generates POST method with requestBody', () async {
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

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(code, contains('Future<Map<String, dynamic>> createUser({'));
      expect(code, contains('required Map<String, dynamic> body'));
      expect(code, contains("/// Generated from POST /users"));
      expect(code, contains("method: 'POST'"));
      expect(code, contains('final bodyJson = jsonEncode(body);'));
      expect(code, contains('body: bodyJson,'));
    });

    test('generates PUT method with requestBody and path params', () async {
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

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(code, contains('Future<Map<String, dynamic>> updateUser({'));
      expect(code, contains('required String id'));
      expect(code, contains('required Map<String, dynamic> body'));
      expect(code, contains("/// Generated from PUT /users/{id}"));
      expect(code, contains("method: 'PUT'"));
      expect(code, contains('final bodyJson = jsonEncode(body);'));
    });

    test('generates POST method with application/x-www-form-urlencoded', () async {
      final spec = <String, dynamic>{
        'paths': {
          '/login': {
            'post': {
              'operationId': 'login',
              'requestBody': {
                'content': {
                  'application/x-www-form-urlencoded': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'username': {'type': 'string'},
                        'password': {'type': 'string'},
                      },
                    },
                  },
                },
              },
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'object'},
                    },
                  },
                },
              },
            },
          },
        },
      };

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(
        code,
        contains('Future<Map<String, dynamic>> login({'),
      );
      expect(code, contains('required Map<String, String> body'));
      expect(code, contains("headers['Content-Type'] = 'application/x-www-form-urlencoded'"));
      expect(code, contains('Uri.encodeComponent'));
      expect(code, contains('.join(\'&\')'));
    });

    test('generates DELETE method without requestBody', () async {
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

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(code, contains('Future<void> deleteUser({'));
      expect(code, contains('required String id'));
      expect(code, isNot(contains('required Map<String, dynamic> body')));
      expect(code, contains("/// Generated from DELETE /users/{id}"));
      expect(code, contains("method: 'DELETE'"));
      expect(code, isNot(contains('jsonEncode(body)')));
    });

    test('generates GET with header parameters', () async {
      final spec = <String, dynamic>{
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'parameters': [
                {
                  'name': 'X-Request-ID',
                  'in': 'header',
                  'required': true,
                  'schema': {'type': 'string'},
                },
                {
                  'name': 'X-Client-Version',
                  'in': 'header',
                  'required': false,
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'object'},
                    },
                  },
                },
              },
            },
          },
        },
      };

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(code, contains('Future<Map<String, dynamic>> getUsers({'));
      expect(code, contains('required String xRequestId'));
      expect(code, contains('String? xClientVersion'));
      expect(code, contains("headers['X-Request-ID'] = xRequestId.toString();"));
      expect(code, contains("if (xClientVersion != null) {"));
      expect(code, contains("headers['X-Client-Version'] = xClientVersion!.toString();"));
    });

    test('generates GET with cookie parameters', () async {
      final spec = <String, dynamic>{
        'paths': {
          '/users': {
            'get': {
              'operationId': 'getUsers',
              'parameters': [
                {
                  'name': 'sessionId',
                  'in': 'cookie',
                  'required': true,
                  'schema': {'type': 'string'},
                },
                {
                  'name': 'csrfToken',
                  'in': 'cookie',
                  'required': false,
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'object'},
                    },
                  },
                },
              },
            },
          },
        },
      };

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(code, contains('Future<Map<String, dynamic>> getUsers({'));
      expect(code, contains('required String sessionid')); // camelCase conversion
      expect(code, contains('String? csrftoken')); // camelCase conversion
      expect(code, contains("headers['Cookie']"));
      expect(code, contains("cookieParts.add('sessionId=")); // Original name in cookie
      expect(code, contains('Uri.encodeComponent'));
      expect(code, contains(".join('; ')"));
    });

    test('generates method with header and cookie parameters together', () async {
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
                  'name': 'X-Request-ID',
                  'in': 'header',
                  'required': true,
                  'schema': {'type': 'string'},
                },
                {
                  'name': 'sessionId',
                  'in': 'cookie',
                  'required': true,
                  'schema': {'type': 'string'},
                },
              ],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {'type': 'object'},
                    },
                  },
                },
              },
            },
          },
        },
      };

      final result = await generator.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(code, contains('Future<Map<String, dynamic>> getUser({'));
      expect(code, contains('required String id'));
      expect(code, contains('required String xRequestId'));
      expect(code, contains('required String sessionid')); // camelCase conversion
      expect(code, contains("headers['X-Request-ID']"));
      expect(code, contains("headers['Cookie']"));
    });
  });
}

