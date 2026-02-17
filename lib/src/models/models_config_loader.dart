import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'models_config.dart';

/// Loads `dart_swagger_to_models.yaml` configuration.
///
/// This allows `dart_swagger_to_api_client` to understand where models
/// are generated and how they are named, without requiring a direct
/// dependency on `dart_swagger_to_models` package.
class ModelsConfigLoader {
  /// Loads `dart_swagger_to_models.yaml` from [projectDir].
  ///
  /// If the file doesn't exist, returns `null`.
  /// If the file exists but cannot be parsed, throws [FormatException].
  static Future<ModelsConfig?> load(String projectDir) async {
    final configPath = p.join(projectDir, 'dart_swagger_to_models.yaml');
    final configFile = File(configPath);

    if (!await configFile.exists()) {
      return null;
    }

    try {
      final content = await configFile.readAsString();
      final yamlDoc = loadYaml(content);
      if (yamlDoc is! Map) {
        throw FormatException(
          'Expected top-level mapping in $configPath, got ${yamlDoc.runtimeType}',
        );
      }

      String? readString(Map<dynamic, dynamic> map, String key) {
        final value = map[key];
        return value is String ? value : null;
      }

      final outputDir = readString(yamlDoc, 'outputDir');
      final defaultStyle = readString(yamlDoc, 'defaultStyle');

      // Parse schema overrides
      final schemasNode = yamlDoc['schemas'];
      final schemas = <String, SchemaOverride>{};
      if (schemasNode is Map) {
        schemasNode.forEach((schemaName, overrideNode) {
          if (schemaName is! String || overrideNode is! Map) return;

          final className = readString(overrideNode, 'className');
          Map<String, String>? fieldNames;
          Map<String, String>? typeMapping;

          final fieldNamesNode = overrideNode['fieldNames'];
          if (fieldNamesNode is Map) {
            fieldNames = <String, String>{};
            fieldNamesNode.forEach((key, value) {
              if (key != null && value is String) {
                fieldNames![key.toString()] = value;
              }
            });
          }

          final typeMappingNode = overrideNode['typeMapping'];
          if (typeMappingNode is Map) {
            typeMapping = <String, String>{};
            typeMappingNode.forEach((key, value) {
              if (key != null && value is String) {
                typeMapping![key.toString()] = value;
              }
            });
          }

          schemas[schemaName] = SchemaOverride(
            className: className,
            fieldNames: fieldNames,
            typeMapping: typeMapping,
          );
        });
      }

      return ModelsConfig(
        outputDir: outputDir,
        defaultStyle: defaultStyle,
        schemas: schemas,
      );
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Failed to parse $configPath: $e');
    }
  }
}
