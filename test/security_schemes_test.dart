import 'dart:convert';
import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:dart_swagger_to_api_client/src/core/security_schemes_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Security schemes support', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dart_swagger_to_api_client_security_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('API Key authentication', () {
      test('generates method with API key in header', () async {
        final specFile = File('${tempDir.path}/spec.json');
        final outputDir = Directory('${tempDir.path}/generated');

        final spec = {
          'openapi': '3.0.0',
          'info': {
            'title': 'Test API',
            'version': '1.0.0',
          },
          'components': {
            'securitySchemes': {
              'apiKeyAuth': {
                'type': 'apiKey',
                'in': 'header',
                'name': 'X-API-Key',
              },
            },
          },
          'paths': {
            '/users': {
              'get': {
                'operationId': 'getUsers',
                'security': [
                  {'apiKeyAuth': []},
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

        expect(content, contains('getUsers'));
        expect(content, contains('apiKeyHeader'));
        expect(content, contains('apiKey'));
      });

      test('generates method with API key in query', () async {
        final specFile = File('${tempDir.path}/spec.json');
        final outputDir = Directory('${tempDir.path}/generated');

        final spec = {
          'openapi': '3.0.0',
          'info': {
            'title': 'Test API',
            'version': '1.0.0',
          },
          'components': {
            'securitySchemes': {
              'apiKeyAuth': {
                'type': 'apiKey',
                'in': 'query',
                'name': 'api_key',
              },
            },
          },
          'paths': {
            '/users': {
              'get': {
                'operationId': 'getUsers',
                'security': [
                  {'apiKeyAuth': []},
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

        expect(content, contains('getUsers'));
        expect(content, contains("'api_key'"));
      });

      test('generates method with API key in cookie', () async {
        final specFile = File('${tempDir.path}/spec.json');
        final outputDir = Directory('${tempDir.path}/generated');

        final spec = {
          'openapi': '3.0.0',
          'info': {
            'title': 'Test API',
            'version': '1.0.0',
          },
          'components': {
            'securitySchemes': {
              'apiKeyAuth': {
                'type': 'apiKey',
                'in': 'cookie',
                'name': 'sessionId',
              },
            },
          },
          'paths': {
            '/users': {
              'get': {
                'operationId': 'getUsers',
                'security': [
                  {'apiKeyAuth': []},
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

        expect(content, contains('getUsers'));
        expect(content, contains('apiKeyCookie'));
        expect(content, contains('Cookie'));
      });
    });

    group('HTTP Basic authentication', () {
      test('generates method with HTTP Basic auth', () async {
        final specFile = File('${tempDir.path}/spec.json');
        final outputDir = Directory('${tempDir.path}/generated');

        final spec = {
          'openapi': '3.0.0',
          'info': {
            'title': 'Test API',
            'version': '1.0.0',
          },
          'components': {
            'securitySchemes': {
              'basicAuth': {
                'type': 'http',
                'scheme': 'basic',
              },
            },
          },
          'paths': {
            '/users': {
              'get': {
                'operationId': 'getUsers',
                'security': [
                  {'basicAuth': []},
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

        expect(content, contains('getUsers'));
        expect(content, contains('resolveBasicAuthUsername'));
        expect(content, contains('resolveBasicAuthPassword'));
        expect(content, contains('base64Encode'));
        expect(content, contains('Basic'));
        expect(content, contains('dart:convert'));
      });
    });

    group('HTTP Bearer authentication', () {
      test('generates method with HTTP Bearer auth', () async {
        final specFile = File('${tempDir.path}/spec.json');
        final outputDir = Directory('${tempDir.path}/generated');

        final spec = {
          'openapi': '3.0.0',
          'info': {
            'title': 'Test API',
            'version': '1.0.0',
          },
          'components': {
            'securitySchemes': {
              'bearerAuth': {
                'type': 'http',
                'scheme': 'bearer',
                'bearerFormat': 'JWT',
              },
            },
          },
          'paths': {
            '/users': {
              'get': {
                'operationId': 'getUsers',
                'security': [
                  {'bearerAuth': []},
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

        expect(content, contains('getUsers'));
        expect(content, contains('resolveBearerToken'));
        expect(content, contains('Bearer'));
      });
    });

    group('OAuth2 authentication', () {
      test('generates method with OAuth2', () async {
        final specFile = File('${tempDir.path}/spec.json');
        final outputDir = Directory('${tempDir.path}/generated');

        final spec = {
          'openapi': '3.0.0',
          'info': {
            'title': 'Test API',
            'version': '1.0.0',
          },
          'components': {
            'securitySchemes': {
              'oauth2': {
                'type': 'oauth2',
                'flows': {
                  'clientCredentials': {
                    'tokenUrl': 'https://api.example.com/oauth/token',
                    'scopes': {
                      'read': 'Read access',
                      'write': 'Write access',
                    },
                  },
                },
              },
            },
          },
          'paths': {
            '/users': {
              'get': {
                'operationId': 'getUsers',
                'security': [
                  {'oauth2': ['read']},
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

        expect(content, contains('getUsers'));
        expect(content, contains('resolveOAuth2AccessToken'));
        expect(content, contains('Bearer'));
      });
    });

    group('OpenID Connect authentication', () {
      test('generates method with OpenID Connect', () async {
        final specFile = File('${tempDir.path}/spec.json');
        final outputDir = Directory('${tempDir.path}/generated');

        final spec = {
          'openapi': '3.0.0',
          'info': {
            'title': 'Test API',
            'version': '1.0.0',
          },
          'components': {
            'securitySchemes': {
              'openId': {
                'type': 'openIdConnect',
                'openIdConnectUrl': 'https://api.example.com/.well-known/openid-configuration',
              },
            },
          },
          'paths': {
            '/users': {
              'get': {
                'operationId': 'getUsers',
                'security': [
                  {'openId': ['openid', 'profile']},
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

        expect(content, contains('getUsers'));
        expect(content, contains('resolveOpenIdConnectToken'));
        expect(content, contains('Bearer'));
      });
    });

    group('Operation-level security', () {
      test('operation security overrides global security', () async {
        final specFile = File('${tempDir.path}/spec.json');
        final outputDir = Directory('${tempDir.path}/generated');

        final spec = {
          'openapi': '3.0.0',
          'info': {
            'title': 'Test API',
            'version': '1.0.0',
          },
          'components': {
            'securitySchemes': {
              'apiKeyAuth': {
                'type': 'apiKey',
                'in': 'header',
                'name': 'X-API-Key',
              },
              'bearerAuth': {
                'type': 'http',
                'scheme': 'bearer',
              },
            },
          },
          'security': [
            {'apiKeyAuth': []},
          ],
          'paths': {
            '/users': {
              'get': {
                'operationId': 'getUsers',
                'security': [
                  {'bearerAuth': []},
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

        expect(content, contains('getUsers'));
        // Should use bearer auth (operation-level), not API key (global)
        expect(content, contains('resolveBearerToken'));
        expect(content, isNot(contains('apiKeyHeader')), reason: 'Should not use global API key auth');
      });
    });

    group('SecuritySchemesParser', () {
      test('parses OpenAPI 3.0 security schemes', () {
        final spec = {
          'openapi': '3.0.0',
          'components': {
            'securitySchemes': {
              'apiKey': {
                'type': 'apiKey',
                'in': 'header',
                'name': 'X-API-Key',
              },
            },
          },
        };

        final schemes = SecuritySchemesParser.parseOpenApi3(spec);
        expect(schemes, hasLength(1));
        expect(schemes.containsKey('apiKey'), isTrue);
        expect(SecuritySchemesParser.getSchemeType(schemes['apiKey']!), 'apiKey');
        expect(SecuritySchemesParser.getApiKeyLocation(schemes['apiKey']!), 'header');
        expect(SecuritySchemesParser.getApiKeyName(schemes['apiKey']!), 'X-API-Key');
      });

      test('parses Swagger 2.0 security definitions', () {
        final spec = {
          'swagger': '2.0',
          'securityDefinitions': {
            'apiKey': {
              'type': 'apiKey',
              'in': 'header',
              'name': 'X-API-Key',
            },
          },
        };

        final schemes = SecuritySchemesParser.parseSwagger2(spec);
        expect(schemes, hasLength(1));
        expect(schemes.containsKey('apiKey'), isTrue);
      });

      test('parses operation security requirements', () {
        final operation = {
          'operationId': 'getUsers',
          'security': [
            {
              'apiKeyAuth': ['read'],
              'bearerAuth': [],
            },
          ],
        };

        final security = SecuritySchemesParser.parseOperationSecurity(operation);
        expect(security, hasLength(1));
        expect(security.first.containsKey('apiKeyAuth'), isTrue);
        expect(security.first.containsKey('bearerAuth'), isTrue);
        expect(security.first['apiKeyAuth'], ['read']);
        expect(security.first['bearerAuth'], isEmpty);
      });

      test('parses global security requirements', () {
        final spec = {
          'openapi': '3.0.0',
          'security': [
            {
              'apiKeyAuth': [],
            },
          ],
        };

        final security = SecuritySchemesParser.parseGlobalSecurity(spec);
        expect(security, hasLength(1));
        expect(security.first.containsKey('apiKeyAuth'), isTrue);
      });
    });
  });
}
