import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'errors.dart';
import 'spec_cache.dart';

/// A helper to load an OpenAPI/Swagger spec from disk with caching support.
///
/// Supports caching parsed specs to improve performance for large files.
class SpecLoader {
  SpecLoader({SpecCache? cache}) : _cache = cache;

  final SpecCache? _cache;

  /// Loads a spec from [inputPath] with optional caching.
  ///
  /// Supports `.yaml` / `.yml` and `.json` files. Throws [FormatException]
  /// or [GenerationException] for unsupported extensions or if the file cannot be parsed.
  Future<Map<String, dynamic>> load(String inputPath) async {
    try {
      // Try to get from cache first
      final cache = _cache;
      if (cache != null) {
        final cached = await cache.getCachedSpec(inputPath);
        if (cached != null) {
          return cached;
        }
      }

      final file = File(inputPath);
      if (!await file.exists()) {
        throw GenerationException(
          'Spec file does not exist',
          path: inputPath,
          context: {
            'inputPath': inputPath,
            'absolutePath': file.absolute.path,
          },
        );
      }

      final content = await file.readAsString();
      final ext = p.extension(inputPath).toLowerCase();

      Map<String, dynamic> spec;
      try {
        if (ext == '.yaml' || ext == '.yml') {
          final yamlDoc = loadYaml(content);
          spec = _yamlToMap(yamlDoc);
        } else if (ext == '.json') {
          final json = jsonDecode(content);
          if (json is! Map<String, dynamic>) {
            throw GenerationException(
              'Expected top-level JSON object in spec file',
              path: inputPath,
              context: {
                'actualType': json.runtimeType.toString(),
                'fileExtension': ext,
              },
            );
          }
          spec = json;
        } else {
          throw GenerationException(
            'Unsupported spec file extension',
            path: inputPath,
            context: {
              'extension': ext,
              'supportedExtensions': ['.yaml', '.yml', '.json'],
            },
          );
        }
      } catch (e) {
        if (e is GenerationException) {
          rethrow;
        }
        throw GenerationException(
          'Failed to parse spec file',
          path: inputPath,
          context: {
            'extension': ext,
            'fileSize': await file.length(),
          },
          cause: e,
        );
      }

      // Cache the parsed spec
      if (_cache != null) {
        await _cache.cacheSpec(inputPath, spec);
      }

      return spec;
    } catch (e) {
      if (e is GenerationException) {
        rethrow;
      }
      throw GenerationException(
        'Unexpected error while loading spec',
        path: inputPath,
        cause: e,
      );
    }
  }

  /// Static method for backward compatibility.
  ///
  /// **Deprecated**: Use instance method `load()` instead.
  @Deprecated('Use SpecLoader().load() instead')
  static Future<Map<String, dynamic>> loadStatic(String inputPath) async {
    final loader = SpecLoader();
    return loader.load(inputPath);
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

