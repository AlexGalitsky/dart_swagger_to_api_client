import 'dart:convert';
import 'dart:io';

import 'package:dart_swagger_to_api_client/src/core/client_generator.dart';
import 'package:dart_swagger_to_api_client/src/config/config_loader.dart';
import 'package:test/test.dart';

void main() {
  group('Configuration integration tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('dart_swagger_to_api_client_config_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('generates client with basic config', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final configFile = File('${tempDir.path}/dart_swagger_to_api_client.yaml');
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

      final config = '''
input: ${specFile.path}
outputDir: ${outputDir.path}
client:
  baseUrl: https://api.example.com
  headers:
    User-Agent: my-app/1.0.0
  auth:
    bearerToken: test-token
http:
  adapter: http
''';

      await specFile.writeAsString(jsonEncode(spec));
      await configFile.writeAsString(config);
      await outputDir.create(recursive: true);

      final loadedConfig = await ConfigLoader.load(configFile.path);
      expect(loadedConfig, isNotNull);
      expect(loadedConfig!.baseUrl, isNotNull);
      expect(loadedConfig.baseUrl!.toString(), 'https://api.example.com');
      expect(loadedConfig.headers['User-Agent'], 'my-app/1.0.0');
      expect(loadedConfig.auth?.bearerToken, 'test-token');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      final generatedFiles = outputDir.listSync();
      expect(generatedFiles.length, greaterThan(0));
    });

    test('generates client with environment profile', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final configFile = File('${tempDir.path}/dart_swagger_to_api_client.yaml');
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

      final config = '''
input: ${specFile.path}
outputDir: ${outputDir.path}
client:
  baseUrl: https://api.example.com
environments:
  dev:
    baseUrl: https://dev-api.example.com
    headers:
      X-Environment: dev
  prod:
    baseUrl: https://api.example.com
    headers:
      X-Environment: prod
http:
  adapter: http
''';

      await specFile.writeAsString(jsonEncode(spec));
      await configFile.writeAsString(config);
      await outputDir.create(recursive: true);

      // Test dev environment - ConfigLoader doesn't support environment parameter directly
      // Instead, we test that the config file can be loaded and contains environment profiles
      final loadedConfig = await ConfigLoader.load(configFile.path);
      expect(loadedConfig, isNotNull);
      expect(loadedConfig!.environments, isNotEmpty);
      expect(loadedConfig.environments.containsKey('dev'), isTrue);
      expect(loadedConfig.environments.containsKey('prod'), isTrue);
      
      final devProfile = loadedConfig.environments['dev'];
      expect(devProfile?.baseUrl?.toString(), 'https://dev-api.example.com');
      expect(devProfile?.headers['X-Environment'], 'dev');
      
      final prodProfile = loadedConfig.environments['prod'];
      expect(prodProfile?.baseUrl?.toString(), 'https://api.example.com');
      expect(prodProfile?.headers['X-Environment'], 'prod');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      final generatedFiles = outputDir.listSync();
      expect(generatedFiles.length, greaterThan(0));
    });

    test('generates client with Dio adapter config', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final configFile = File('${tempDir.path}/dart_swagger_to_api_client.yaml');
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

      final config = '''
input: ${specFile.path}
outputDir: ${outputDir.path}
baseUrl: https://api.example.com
http:
  adapter: dio
''';

      await specFile.writeAsString(jsonEncode(spec));
      await configFile.writeAsString(config);
      await outputDir.create(recursive: true);

      final loadedConfig = await ConfigLoader.load(configFile.path);
      expect(loadedConfig, isNotNull);
      expect(loadedConfig!.httpAdapter, 'dio');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
        customAdapterType: 'DioHttpClientAdapter',
      );

      final generatedFiles = outputDir.listSync();
      expect(generatedFiles.length, greaterThan(0));
    });

    test('generates client with custom adapter config', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final configFile = File('${tempDir.path}/dart_swagger_to_api_client.yaml');
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

      final config = '''
input: ${specFile.path}
outputDir: ${outputDir.path}
baseUrl: https://api.example.com
http:
  adapter: custom
  customAdapterType: MyCustomAdapter
''';

      await specFile.writeAsString(jsonEncode(spec));
      await configFile.writeAsString(config);
      await outputDir.create(recursive: true);

      final loadedConfig = await ConfigLoader.load(configFile.path);
      expect(loadedConfig, isNotNull);
      expect(loadedConfig!.httpAdapter, 'custom');
      expect(loadedConfig.customAdapterType, 'MyCustomAdapter');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
        customAdapterType: 'MyCustomAdapter',
      );

      final generatedFiles = outputDir.listSync();
      expect(generatedFiles.length, greaterThan(0));
    });

    test('generates client with API key authentication', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final configFile = File('${tempDir.path}/dart_swagger_to_api_client.yaml');
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

      final config = '''
input: ${specFile.path}
outputDir: ${outputDir.path}
client:
  baseUrl: https://api.example.com
  auth:
    apiKeyHeader: X-API-Key
    apiKey: my-api-key-123
http:
  adapter: http
''';

      await specFile.writeAsString(jsonEncode(spec));
      await configFile.writeAsString(config);
      await outputDir.create(recursive: true);

      final loadedConfig = await ConfigLoader.load(configFile.path);
      expect(loadedConfig, isNotNull);
      expect(loadedConfig!.auth?.apiKeyHeader, 'X-API-Key');
      expect(loadedConfig.auth?.apiKey, 'my-api-key-123');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      final generatedFiles = outputDir.listSync();
      expect(generatedFiles.length, greaterThan(0));
    });

    test('generates client with bearer token from environment', () async {
      final specFile = File('${tempDir.path}/spec.json');
      final configFile = File('${tempDir.path}/dart_swagger_to_api_client.yaml');
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

      final config = '''
input: ${specFile.path}
outputDir: ${outputDir.path}
client:
  baseUrl: https://api.example.com
  auth:
    bearerTokenEnv: API_TOKEN
http:
  adapter: http
''';

      await specFile.writeAsString(jsonEncode(spec));
      await configFile.writeAsString(config);
      await outputDir.create(recursive: true);

      final loadedConfig = await ConfigLoader.load(configFile.path);
      expect(loadedConfig, isNotNull);
      expect(loadedConfig!.auth?.bearerTokenEnv, 'API_TOKEN');

      await ApiClientGenerator.generateClient(
        inputSpecPath: specFile.path,
        outputDir: outputDir.path,
        projectDir: tempDir.path,
      );

      final generatedFiles = outputDir.listSync();
      expect(generatedFiles.length, greaterThan(0));
    });
  });
}
