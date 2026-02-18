import 'package:dart_swagger_to_api_client/src/generators/endpoint_method_generator.dart';
import 'package:dart_swagger_to_api_client/src/models/models_resolver.dart';
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

    test('uses model type for requestBody when schema has \$ref', () async {
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
                      '\$ref': '#/components/schemas/User',
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
                        '\$ref': '#/components/schemas/User',
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
            },
          },
        },
      };

      final generatorWithModels = EndpointMethodGenerator(
        modelsResolver: _FakeModelsResolver(),
      );

      final result = await generatorWithModels.generateDefaultApiMethods(spec);
      final code = result.methods;

      expect(code, contains('Future<User> createUser({'));
      expect(code, contains('required User body'));
      expect(code, contains('final bodyJson = jsonEncode(body.toJson());'));
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

    test('generates POST method with text/plain content type', () async {
      final spec = <String, dynamic>{
        'paths': {
          '/text': {
            'post': {
              'operationId': 'sendText',
              'requestBody': {
                'content': {
                  'text/plain': {
                    'schema': {
                      'type': 'string',
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

      expect(code, contains('Future<Map<String, dynamic>> sendText({'));
      expect(code, contains('required String body'));
      expect(code, contains("headers['Content-Type'] = 'text/plain'"));
      expect(code, isNot(contains('jsonEncode')));
    });

    test('generates POST method with text/html content type', () async {
      final spec = <String, dynamic>{
        'paths': {
          '/html': {
            'post': {
              'operationId': 'sendHtml',
              'requestBody': {
                'content': {
                  'text/html': {
                    'schema': {
                      'type': 'string',
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

      expect(code, contains('Future<Map<String, dynamic>> sendHtml({'));
      expect(code, contains('required String body'));
      expect(code, contains("headers['Content-Type'] = 'text/html'"));
      expect(code, isNot(contains('jsonEncode')));
    });

    test('generates POST method with application/xml content type', () async {
      final spec = <String, dynamic>{
        'paths': {
          '/xml': {
            'post': {
              'operationId': 'sendXml',
              'requestBody': {
                'content': {
                  'application/xml': {
                    'schema': {
                      'type': 'string',
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

      expect(code, contains('Future<Map<String, dynamic>> sendXml({'));
      expect(code, contains('required String body'));
      expect(code, contains("headers['Content-Type'] = 'application/xml'"));
      expect(code, isNot(contains('jsonEncode')));
    });

    test('generates POST method with multiple content types (selects first by priority)', () async {
      final spec = <String, dynamic>{
        'paths': {
          '/multi': {
            'post': {
              'operationId': 'sendMulti',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                    },
                  },
                  'text/plain': {
                    'schema': {
                      'type': 'string',
                    },
                  },
                  'application/xml': {
                    'schema': {
                      'type': 'string',
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

      // Should select multipart/form-data > form-urlencoded > json > text/plain > text/html > xml
      // Since we have json, text/plain, and xml, json should be selected (third priority)
      expect(code, contains('Future<Map<String, dynamic>> sendMulti({'));
      expect(code, contains('required Map<String, dynamic> body'));
      expect(code, contains("headers['Content-Type'] = 'application/json'"));
      expect(code, contains('jsonEncode'));
    });

    test('generates POST method with multiple content types (multipart priority)', () async {
      final spec = <String, dynamic>{
        'paths': {
          '/multi': {
            'post': {
              'operationId': 'sendMulti',
              'requestBody': {
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                    },
                  },
                  'multipart/form-data': {
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

      // Should select multipart/form-data (highest priority)
      expect(code, contains('Future<Map<String, dynamic>> sendMulti({'));
      expect(code, contains('required Map<String, dynamic> body'));
      // multipart doesn't set Content-Type header (adapter handles it)
      expect(code, isNot(contains("headers['Content-Type'] = 'multipart/form-data'")));
    });
  });
}

class _FakeModelsResolver implements ModelsResolver {
  const _FakeModelsResolver();

  @override
  Future<String?> resolveRefToType(String ref) async {
    if (ref.endsWith('/User')) {
      return 'User';
    }
    return null;
  }

  @override
  Future<String?> getImportPath(String typeName) async => null;

  @override
  Future<bool> isModelType(String typeName) async => typeName == 'User';
}
