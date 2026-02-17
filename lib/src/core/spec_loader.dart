import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A very small helper to load an OpenAPI/Swagger spec from disk.
///
/// v0.1 goal: just read YAML or JSON into a `Map<String, dynamic>` without
/// any advanced validation or normalization – that's for higher layers.
class SpecLoader {
  /// Loads a spec from [inputPath].
  ///
  /// Supports `.yaml` / `.yml` and `.json` files. Throws [FormatException]
  /// for unsupported extensions or if the file cannot be parsed.
  static Future<Map<String, dynamic>> load(String inputPath) async {
    final file = File(inputPath);
    if (!await file.exists()) {
      throw ArgumentError.value(inputPath, 'inputPath', 'File does not exist');
    }

    final content = await file.readAsString();
    final ext = p.extension(inputPath).toLowerCase();

    if (ext == '.yaml' || ext == '.yml') {
      final yamlDoc = loadYaml(content);
      return _yamlToMap(yamlDoc);
    }

    if (ext == '.json') {
      final json = jsonDecode(content);
      if (json is! Map<String, dynamic>) {
        throw FormatException(
          'Expected top-level JSON object in spec file, got ${json.runtimeType}',
        );
      }
      return json;
    }

    throw FormatException(
      'Unsupported spec file extension "$ext". Expected .yaml, .yml or .json',
    );
  }

  /// Convert a YAML document (from `loadYaml`) into a JSON-like map.
  static Map<String, dynamic> _yamlToMap(dynamic node) {
    if (node is Map) {
      return node.map(
        (key, value) => MapEntry(
          key.toString(),
          _yamlToJsonCompatible(value),
        ),
      );
    }
    throw FormatException(
      'Expected YAML document to be a mapping, got ${node.runtimeType}',
    );
  }

  static dynamic _yamlToJsonCompatible(dynamic node) {
    if (node is Map) {
      return node.map(
        (key, value) => MapEntry(
          key.toString(),
          _yamlToJsonCompatible(value),
        ),
      );
    }
    if (node is List) {
      return node.map(_yamlToJsonCompatible).toList(growable: false);
    }
    return node;
  }
}

