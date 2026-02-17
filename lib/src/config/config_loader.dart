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
    Map<String, EnvironmentProfile>? environments,
  })  : headers = Map.unmodifiable(headers ?? const {}),
        environments = Map.unmodifiable(environments ?? const {});

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

  /// Environment profiles (dev, staging, prod, etc.).
  final Map<String, EnvironmentProfile> environments;
}

/// Environment profile configuration.
class EnvironmentProfile {
  EnvironmentProfile({
    this.baseUrl,
    Map<String, String>? headers,
    this.auth,
  }) : headers = Map.unmodifiable(headers ?? const {});

  /// Base URL for this environment.
  final Uri? baseUrl;

  /// Default headers for this environment.
  final Map<String, String> headers;

  /// Authentication settings for this environment.
  final AuthConfig? auth;
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
          bearerToken: readString(authNode, 'bearerToken'),
          bearerTokenEnv: readString(authNode, 'bearerTokenEnv'),
        );
      }
    }

    // Load environment profiles
    final environments = <String, EnvironmentProfile>{};
    final environmentsNode = yamlDoc['environments'];
    if (environmentsNode is Map) {
      environmentsNode.forEach((key, value) {
        if (key is String && value is Map) {
          final profile = _loadEnvironmentProfile(value);
          if (profile != null) {
            environments[key] = profile;
          }
        }
      });
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
      environments: environments,
    );
  }

  /// Loads an environment profile from a YAML node.
  static EnvironmentProfile? _loadEnvironmentProfile(Map<dynamic, dynamic> node) {
    String? readString(Map<dynamic, dynamic> map, String key) {
      final value = map[key];
      return value is String ? value : null;
    }

    Uri? baseUrl;
    final baseUrlStr = readString(node, 'baseUrl');
    if (baseUrlStr != null && baseUrlStr.isNotEmpty) {
      baseUrl = Uri.tryParse(baseUrlStr);
    }

    Map<String, String>? headers;
    final headersNode = node['headers'];
    if (headersNode is Map) {
      headers = <String, String>{};
      headersNode.forEach((key, value) {
        if (key != null && value is String) {
          headers![key.toString()] = value;
        }
      });
    }

    AuthConfig? auth;
    final authNode = node['auth'];
    if (authNode is Map) {
      auth = AuthConfig(
        apiKeyHeader: readString(authNode, 'apiKeyHeader'),
        apiKeyQuery: readString(authNode, 'apiKeyQuery'),
        apiKey: readString(authNode, 'apiKey'),
        bearerToken: readString(authNode, 'bearerToken'),
        bearerTokenEnv: readString(authNode, 'bearerTokenEnv'),
      );
    }

    return EnvironmentProfile(
      baseUrl: baseUrl,
      headers: headers,
      auth: auth,
    );
  }
}

