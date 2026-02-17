import 'dart:io';

import 'package:path/path.dart' as p;

import 'models_config.dart';
import 'models_resolver.dart';

/// Real implementation of [ModelsResolver] that reads generated model files
/// from the filesystem based on `dart_swagger_to_models` configuration.
///
/// This resolver:
/// 1. Reads `dart_swagger_to_models.yaml` to find the output directory
/// 2. Scans the output directory for generated model files
/// 3. Maps schema names (from `$ref`) to Dart class names and file paths
class FileBasedModelsResolver implements ModelsResolver {
  FileBasedModelsResolver({
    required String projectDir,
    ModelsConfig? modelsConfig,
  })  : _projectDir = projectDir,
        _modelsConfig = modelsConfig;

  final String _projectDir;
  final ModelsConfig? _modelsConfig;

  // Cache for resolved types (schema name -> class name)
  final Map<String, String> _schemaToType = {};

  // Cache for import paths (class name -> import path)
  final Map<String, String> _typeToImportPath = {};

  // Set of known model types
  final Set<String> _modelTypes = {};

  bool _initialized = false;

  /// Initializes the resolver by scanning the models directory.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final outputDir = _modelsConfig?.outputDir ?? 'lib/models';
    final effectiveOutputDir = p.isAbsolute(outputDir)
        ? outputDir
        : p.join(_projectDir, outputDir);

    final modelsDirectory = Directory(effectiveOutputDir);
    if (!await modelsDirectory.exists()) {
      _initialized = true;
      return;
    }

    // Scan for model files
    await for (final entity in modelsDirectory.list(recursive: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      try {
        final content = await entity.readAsString();
        final fileName = p.basenameWithoutExtension(entity.path);

        // Look for class definitions in the file
        final classMatches = _classPattern.allMatches(content);
        final classesInFile = <String>[];
        
        for (final match in classMatches) {
          final className = match.group(1);
          if (className == null) continue;

          classesInFile.add(className);
          _modelTypes.add(className);

          // Build import path (same for all classes in the file)
          // If outputDir is relative, we need to compute relative path from project root
          final relativePath = p.relative(entity.path, from: _projectDir);
          // Convert to package-style import (replace backslashes with slashes)
          final importPath = relativePath.replaceAll('\\', '/');
          _typeToImportPath[className] = importPath;
        }

        // Map schema names to class names
        // Primary mapping: file name (snake_case) -> first class in file
        // Also map each class name to itself
        final schemaName = _toPascalCase(fileName);
        if (classesInFile.isNotEmpty) {
          // Map file name to first class (primary mapping)
          _schemaToType[schemaName] = classesInFile.first;
          
          // Map each class name to itself (for direct lookups)
          for (final className in classesInFile) {
            _schemaToType[className] = className;
          }
          
          // Also map the file name directly (in case schema name matches file name)
          if (fileName != schemaName) {
            _schemaToType[fileName] = classesInFile.first;
          }
        }
      } catch (_) {
        // Ignore file reading errors
      }
    }

    _initialized = true;
  }

  /// Pattern to match class definitions: `class ClassName {`
  static final _classPattern = RegExp(r'class\s+(\w+)\s*[<{]');

  @override
  Future<String?> resolveRefToType(String ref) async {
    await _ensureInitialized();

    // Parse $ref: #/components/schemas/User or #/definitions/User
    // Extract the schema name (last part after /)
    final parts = ref.split('/');
    if (parts.isEmpty) return null;

    final schemaName = parts.last;
    if (schemaName.isEmpty) return null;

    // Try direct lookup
    final type = _schemaToType[schemaName];
    if (type != null) return type;

    // Try PascalCase conversion
    final pascalCaseName = _toPascalCase(schemaName);
    return _schemaToType[pascalCaseName];
  }

  @override
  Future<String?> getImportPath(String typeName) async {
    await _ensureInitialized();
    return _typeToImportPath[typeName];
  }

  @override
  Future<bool> isModelType(String typeName) async {
    await _ensureInitialized();
    return _modelTypes.contains(typeName);
  }

  /// Converts a string to PascalCase.
  ///
  /// Example: "user_profile" -> "UserProfile", "userProfile" -> "UserProfile"
  static String _toPascalCase(String name) {
    if (name.isEmpty) return name;

    final parts = name
        .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')
        .split(RegExp(r'[_\s]+'))
      ..removeWhere((e) => e.isEmpty);

    if (parts.isEmpty) return name;

    return parts
        .map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join();
  }
}
