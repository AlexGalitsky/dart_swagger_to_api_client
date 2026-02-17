import 'dart:io';

import 'package:yaml/yaml.dart';

import 'config.dart';

/// Configuration loaded from `dart_swagger_to_api_client.yaml`.
///
/// This represents generator-level options (input, outputDir, default client
/// settings), not the runtime `ApiClientConfig` used by the generated code.
class ApiGeneratorConfig {
  ApiGeneratorConfig({
    this.input,
    this.outputDir,
    this.baseUrl,
    Map<String, String>? headers,
    this.auth,
    this.httpAdapter,
    this.customAdapterType,
  }) : headers = Map.unmodifiable(headers ?? const {});

  /// Path to OpenAPI/Swagger spec.
  final String? input;

  /// Where to put generated client code.
  final String? outputDir;

  /// Default base URL for the generated client.
  final Uri? baseUrl;

  /// Default headers for all requests.
  final Map<String, String> headers;

  /// Authentication settings (API key / bearer token).
  final AuthConfig? auth;

  /// HTTP adapter name: `http`, `dio`, `custom`.
  final String? httpAdapter;

  /// For `custom` adapter: Dart type name implementing `HttpClientAdapter`.
  final String? customAdapterType;
}

class ConfigLoader {
  /// Loads `dart_swagger_to_api_client.yaml` from [path].
  ///
  /// If the file does not exist, returns `null`.
  static Future<ApiGeneratorConfig?> load(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();
    final yamlDoc = loadYaml(content);
    if (yamlDoc is! Map) {
      throw FormatException(
        'Expected top-level mapping in $path, got ${yamlDoc.runtimeType}',
      );
    }

    String? readString(Map<dynamic, dynamic> map, String key) {
      final value = map[key];
      return value is String ? value : null;
    }

    final input = readString(yamlDoc, 'input');
    final outputDir = readString(yamlDoc, 'outputDir');

    Uri? baseUrl;
    final clientNode = yamlDoc['client'];
    Map<String, String>? headers;
    AuthConfig? auth;

    if (clientNode is Map) {
      final baseUrlStr = readString(clientNode, 'baseUrl');
      if (baseUrlStr != null && baseUrlStr.isNotEmpty) {
        baseUrl = Uri.tryParse(baseUrlStr);
      }

      final headersNode = clientNode['headers'];
      if (headersNode is Map) {
        headers = <String, String>{};
        headersNode.forEach((key, value) {
          if (key != null && value is String) {
            headers![key.toString()] = value;
          }
        });
      }

      final authNode = clientNode['auth'];
      if (authNode is Map) {
        auth = AuthConfig(
          apiKeyHeader: readString(authNode, 'apiKeyHeader'),
          apiKeyQuery: readString(authNode, 'apiKeyQuery'),
          apiKey: readString(authNode, 'apiKey'),
          // We intentionally ignore bearerTokenEnv at v0.1 and allow
          // only direct bearerToken value for simplicity.
          bearerToken: readString(authNode, 'bearerToken'),
        );
      }
    }

    String? httpAdapter;
    String? customAdapterType;
    final httpNode = yamlDoc['http'];
    if (httpNode is Map) {
      httpAdapter = readString(httpNode, 'adapter');
      customAdapterType = readString(httpNode, 'customAdapterType');
    }

    return ApiGeneratorConfig(
      input: input,
      outputDir: outputDir,
      baseUrl: baseUrl,
      headers: headers,
      auth: auth,
      httpAdapter: httpAdapter,
      customAdapterType: customAdapterType,
    );
  }
}

